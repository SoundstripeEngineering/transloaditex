defmodule TusClient.Head do
  @moduledoc false
  alias TusClient.Utils

  require Logger

  def request(url, headers \\ [], opts \\ []) do
    req_opts = [method: :head, url: url, headers: headers] ++ Utils.req_options(opts)

    case Req.request(req_opts) do
      {:ok, %{status: status} = resp} when status in [200, 204] ->
        process(resp)

      {:ok, %{status: status}} when status in [403, 404, 410] ->
        {:error, :not_found}

      {:ok, resp} ->
        Logger.error("HEAD response not handled: #{inspect(resp)}")
        {:error, :generic}

      {:error, err} ->
        Logger.error("HEAD request failed: #{inspect(err)}")
        {:error, :transport}
    end
  end

  defp process(%{headers: headers}) when map_size(headers) == 0, do: {:error, :preconditions}

  defp process(%{headers: headers}) do
    with {:ok, offset} <- get_upload_offset(headers),
         :ok <- ensure_no_cache(headers),
         {:ok, len} <- get_upload_len(headers) do
      {:ok,
       %{
         upload_offset: offset,
         upload_length: len
       }}
    else
      {:error, :no_offset} -> {:error, :preconditions}
      {:error, :wrong_cache} -> {:error, :preconditions}
    end
  end

  defp get_upload_len(headers) do
    case Utils.get_header(headers, "upload-length") do
      v when is_binary(v) -> {:ok, String.to_integer(v)}
      _ -> {:ok, nil}
    end
  end

  defp get_upload_offset(headers) do
    case Utils.get_header(headers, "upload-offset") do
      v when is_binary(v) -> {:ok, String.to_integer(v)}
      _ -> {:error, :no_offset}
    end
  end

  defp ensure_no_cache(headers) do
    case Utils.get_header(headers, "cache-control") do
      "no-store" -> :ok
      _ -> {:error, :wrong_cache}
    end
  end
end
