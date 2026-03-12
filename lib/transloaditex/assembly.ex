defmodule Transloaditex.Assembly do
  alias Transloaditex.Step
  alias Transloaditex.File

  @retries 5
  @chunk_size 5 * 1024 * 1024

  defp request, do: Application.get_env(:transloaditex, :request, Transloaditex.Request)
  defp tus_client, do: Application.get_env(:transloaditex, :tus_adapter, TusClient)

  @doc """
  Create a new assembly.

  ## Options

    * `:steps` - List of step maps built with `Transloaditex.Step`
    * `:files` - List of file maps built with `Transloaditex.File`
    * `:wait` - Whether to poll until assembly completes (default: `false`)
    * `:resumable` - Whether to use resumable (TUS) uploads (default: `true`)
    * `:retries` - Maximum retry/poll attempts (default: 5)

  ## Returns

    A `Transloaditex.Response` struct or `{:error, reason}`.
  """
  def create_assembly(options) when is_map(options) do
    steps_opt = Map.get(options, :steps, [])
    files = Map.get(options, :files, [])
    wait = Map.get(options, :wait, false)
    resumable = Map.get(options, :resumable, true)
    retries = Map.get(options, :retries, @retries)

    steps = Step.get_steps(steps_opt)

    response = post_assembly(steps, files, resumable)

    cond do
      match?({:error, _}, response) ->
        response

      rate_limit_reached?(response.data) and retries > 0 ->
        retry_after_rate_limit(response, options, retries)

      true ->
        with :ok <- upload_files(response, files, resumable, retries) do
          if wait do
            wait_for_completion(response, retries)
          else
            response
          end
        end
    end
  end

  def create_assembly(_), do: {:error, "Missing or invalid parameters"}

  @doc """
  Get the assembly specified by assembly id or assembly url.

  ## Args

    * `assembly` - Assembly id or full assembly url

  ## Returns

    A `Transloaditex.Response` struct or `{:error, reason}`.
  """
  def get_assembly(assembly) when is_binary(assembly) do
    case Transloaditex.Request.to_url("assemblies", assembly) do
      {:error, _} = error -> error
      url -> request().get(url)
    end
  end

  def get_assembly(_), do: {:error, "Missing or invalid argument. Provide an assembly id or url"}

  @doc """
  List assemblies with optional filter parameters.

  See https://transloadit.com/docs/api/assemblies-get/ for available options.
  """
  def list_assemblies(params \\ %{}), do: request().get("/assemblies", params)

  @doc """
  Cancel the assembly specified by assembly id or assembly url.
  """
  def cancel_assembly(assembly) when is_binary(assembly) do
    case Transloaditex.Request.to_url("assemblies", assembly) do
      {:error, _} = error -> error
      url -> request().delete(url)
    end
  end

  def cancel_assembly(_), do: {:error, "Invalid argument. Provide an assembly id or url"}

  @doc """
  Replay an existing assembly.

  ## Args

    * `assembly_id` - The assembly id to replay
    * `options` - Optional map with keys: `:notify_url`, `:reparse_template`,
      `:steps`, `:template_id`, `:fields`

  ## Returns

    A `Transloaditex.Response` struct or `{:error, reason}`.
  """
  def replay_assembly(assembly_id, options \\ %{}) when is_binary(assembly_id) do
    data = Map.put_new(options, :reparse_template, 0)
    request().post("/assemblies/#{assembly_id}/replay", data)
  end

  # Private helpers

  defp post_assembly(steps, files, true = _resumable) do
    if length(files) > 0 do
      extra_data = %{"tus_num_expected_upload_files" => Jason.encode!(length(files))}
      request().post("/assemblies", %{steps: steps}, extra_data)
    else
      request().post("/assemblies", %{steps: steps})
    end
  end

  defp post_assembly(steps, files, false = _resumable) do
    request().post("/assemblies", %{steps: steps}, %{
      files: Jason.encode!(File.get_files(files))
    })
  end

  defp retry_after_rate_limit(response, options, retries) do
    sleep_time = get_in(response.data, ["info", "retryIn"]) || 1
    :timer.sleep(sleep_time * 1_000)
    create_assembly(Map.put(options, :retries, retries - 1))
  end

  defp upload_files(_response, _files, false, _retries), do: :ok
  defp upload_files(_response, [], _resumable, _retries), do: :ok

  defp upload_files(response, files, true, retries) do
    results =
      Enum.map(files, fn file_map ->
        [{field_name, file_path}] = Map.to_list(file_map)

        metadata = %{
          assembly_url: response.data["assembly_url"],
          assembly_ssl_url: response.data["assembly_ssl_url"],
          fieldname: field_name,
          filename: Path.basename(file_path)
        }

        tus_client().upload(
          response.data["tus_url"],
          Path.absname(file_path),
          max_retries: retries,
          chunk_size: @chunk_size,
          metadata: metadata
        )
      end)

    case Enum.find(results, &match?({:error, _}, &1)) do
      nil -> :ok
      error -> error
    end
  end

  defp wait_for_completion(_response, 0),
    do: {:error, "Max retries reached without completion."}

  defp wait_for_completion(response, retries) do
    if assembly_finished?(response) do
      response
    else
      sleep_time = get_in(response.data, ["info", "retryIn"]) || 1
      :timer.sleep(sleep_time * 1_000)
      updated_response = get_assembly(response.data["assembly_ssl_url"])
      wait_for_completion(updated_response, retries - 1)
    end
  end

  defp assembly_finished?(response) do
    status = Map.get(response.data, "ok")
    error = Map.get(response.data, "error")

    terminal_status = status in ["ASSEMBLY_COMPLETED", "ASSEMBLY_CANCELED", "REQUEST_ABORTED"]
    failed = not is_nil(error) and error != "ASSEMBLY_STATUS_FETCHING_RATE_LIMIT_REACHED"

    terminal_status or failed
  end

  defp rate_limit_reached?(data), do: Map.get(data, "error") == "RATE_LIMIT_REACHED"
end
