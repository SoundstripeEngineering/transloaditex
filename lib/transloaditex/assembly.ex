defmodule Transloaditex.Assembly do
  alias Transloaditex.Request
  alias Transloaditex.Step
  alias Transloaditex.File

  @retries 5
  @chunk_size 5 * 1024 * 1024

  def request, do: Application.get_env(:transloaditex, :request)

  @doc """
  Create a new assembly

  ## Args:

    * `options` (map) - ...

  ## Returns:

    An instance of `Transloaditex.Response`.
  """

  def create_assembly(options) do
    steps = Step.get_steps(Map.get(options, :steps, []))
    files = Map.get(options, :files, [])
    wait = Map.get(options, :wait, false)
    resumable = Map.get(options, :resumable, true)
    retries = Map.get(options, :retries, @retries)

    response =
      if resumable do
        extra_data = %{"tus_num_expected_upload_files" => Jason.encode!(length(files))}
        response = request().post("/assemblies", %{steps: steps}, extra_data)

        do_tus_upload(%{
          files: files,
          assembly_url: response.data["assembly_url"],
          tus_url: response.data["tus_url"],
          max_retries: retries
        })

        response
      else
        request().post("/assemblies", %{steps: steps}, %{
          files: Jason.encode!(File.get_files(files))
        })
      end

    if wait, do: wait_for_assembly_finish(response, @retries)

    if rate_limit_reached(response) and retries > 0 do
      sleep_time =
        Map.get(response.data, "info", %{})
        |> Map.get("retryIn", 1)

      :timer.sleep(sleep_time * 1_000)

      options = %{options | retries: retries - 1}
      create_assembly(options)
    end

    response
  end

  def create_assembly(), do: {:error, "Missing or invalid parameters"}

  @doc """
  Get the assembly specified by assemby id or assembly url

  ## Args:

    * `assembly` (str) - One of assembly id or assembly url

  ## Returns:

    An instance of `Transloaditex.Response`.
  """
  def get_assembly(assembly) when is_binary(assembly) do
    url = Request.to_url("assemblies", assembly)

    request().get(url)
  end

  def get_assembly(_), do: {:error, "Missing or invalid argument. Provide an assembly if or url"}
  def get_assembly(), do: {:error, "Missing or invalid argument. Provide an assembly if or url"}

  @doc """
  Get the list of assemblies.

  ## Args:

    * `options` (Optional[map) -
      params to send along with the request. Please see
      https://transloadit.com/docs/api-docs/#25-retrieve-assembly-list for available options.

  ## Returns:

    An instance of `Transloaditex.Response`.
  """
  def list_assemblies(params), do: request().get("/assemblies", params)

  def list_assemblies(), do: list_assemblies(%{})

  @doc """
  Cancel the assembly specified by either assembly_id or assembly_url

  ## Args:

    * `assembly` (str) - One of assembly_id or assembly_url

  ## Returns:

    An instance of `Transloaditex.Response`.
  """
  def cancel_assembly(assembly) do
    url = Request.to_url("assemblies", assembly)

    request().delete(url)
  end

  def cancel_assembly(), do: {:error, "Missing parameter. Provide an assembly id or url"}

  defp do_tus_upload(options) do
    Enum.each(Map.get(options, :files, []), fn file_map ->
      [{field_name, file_path}] = Map.to_list(file_map)

      metadata = %{
        assembly_url: Map.get(options, :assembly_url),
        fieldname: field_name,
        filename: Path.basename(file_path)
      }

      TusClient.upload(
        Map.get(options, :tus_url),
        Path.absname(file_path),
        [
          {:max_retries, Map.get(options, :max_retries, @retries)},
          {:chunk_size, @chunk_size},
          {:metadata, metadata}
        ]
      )
    end)
  end

  defp wait_for_assembly_finish(_response, 0),
    do: {:error, "Max retries reached without completion."}

  defp wait_for_assembly_finish(response, retries) when retries > 0 do
    if !assembly_finished(response) do
      sleep_time =
        Map.get(response.data, "info", %{})
        |> Map.get("retryIn", 1)

      :timer.sleep(sleep_time * 1_000)

      response = get_assembly(Map.get(response.data, "assembly_ssl_url"))

      wait_for_assembly_finish(response, retries - 1)
    else
      {:ok}
    end
  end

  defp assembly_finished(response) do
    status = Map.get(response, "ok")
    is_aborted = status == "REQUEST_ABORTED"
    is_canceled = status == "ASSEMBLY_CANCELED"
    is_completed = status == "ASSEUMBLY_COMPLETED"
    error = Map.get(response, "error")
    is_failed = !is_nil(error)
    is_fetch_rate_limit = error == "ASSEMBLY_STATUS_FETCHING_RATE_LIMIT_REACHED"

    is_aborted or is_canceled or is_completed or (is_failed and not is_fetch_rate_limit)
  end

  defp rate_limit_reached(response), do: Map.get(response, "error") == "RATE_LIMIT_REACHED"
end
