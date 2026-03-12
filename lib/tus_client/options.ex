defmodule TusClient.Options do
  @moduledoc false
  alias TusClient.Utils

  require Logger

  def request(url, headers \\ [], opts \\ []) do
    req_opts = [method: :options, url: url, headers: headers] ++ Utils.req_options(opts)

    case Req.request(req_opts) do
      {:ok, %{status: status} = resp} when status in [200, 204] ->
        process(resp)

      {:ok, resp} ->
        Logger.error("OPTIONS response not handled: #{inspect(resp)}")
        {:error, :generic}

      {:error, err} ->
        Logger.error("OPTIONS request failed: #{inspect(err)}")
        {:error, :transport}
    end
  end

  defp process(%{headers: headers}) when map_size(headers) == 0, do: {:error, :not_supported}

  defp process(%{headers: headers}) do
    with :ok <- check_supported_protocol(headers),
         {:ok, extensions} <- check_required_extensions(headers) do
      max_size =
        case Utils.get_header(headers, "tus-max-size") do
          v when is_binary(v) -> String.to_integer(v)
          _ -> nil
        end

      {:ok,
       %{
         max_size: max_size,
         extensions: extensions
       }}
    end
  end

  defp check_required_extensions(headers) do
    supported =
      headers
      |> Utils.get_header("tus-extension")
      |> String.split(",")
      |> Enum.map(&String.trim/1)

    if Enum.member?(supported, "creation") do
      {:ok, supported}
    else
      {:error, :unfulfilled_extensions}
    end
  end

  defp check_supported_protocol(headers) do
    case Utils.get_header(headers, "tus-version") do
      "1.0.0" ->
        :ok

      v ->
        Logger.warning("Unsupported server version #{v}")
        {:error, :not_supported}
    end
  end
end
