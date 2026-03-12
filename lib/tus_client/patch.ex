defmodule TusClient.Patch do
  @moduledoc false
  alias TusClient.Utils

  require Logger

  def request(url, offset, path, headers \\ [], opts \\ []) do
    path
    |> seek(offset)
    |> do_read(opts)
    |> do_request(url, offset, headers, opts)
  end

  defp do_request({:ok, data}, url, offset, headers, opts) do
    hdrs =
      [
        {"content-length", IO.iodata_length(data)},
        {"upload-offset", to_string(offset)}
      ]
      |> Utils.add_version_hdr()
      |> Utils.add_tus_content_type()
      |> Kernel.++(headers)
      |> Enum.uniq()

    req_opts =
      [method: :patch, url: url, headers: hdrs, body: data] ++ Utils.req_options(opts)

    case Req.request(req_opts) do
      {:ok, %{status: 204, headers: resp_headers}} ->
        case Utils.get_header(resp_headers, "upload-offset") do
          v when is_binary(v) -> {:ok, String.to_integer(v)}
          _ -> {:error, :protocol}
        end

      {:ok, resp} ->
        Logger.error("PATCH response not handled: #{inspect(resp)}")
        {:error, :generic}

      {:error, err} ->
        Logger.error("PATCH request failed: #{inspect(err)}")
        {:error, :transport}
    end
  end

  defp do_request({:error, _} = err, _url, _offset, _headers, _opts), do: err

  defp do_read({:error, _} = err, _opts), do: err

  defp do_read({:ok, io_device}, opts) do
    data =
      case :file.read(io_device, get_chunk_size(opts)) do
        :eof -> {:error, :eof}
        res -> res
      end

    File.close(io_device)
    data
  end

  defp seek(path, offset) when is_binary(path) do
    path
    |> File.open([:read])
    |> seek(offset)
  end

  defp seek({:ok, io_device}, offset) do
    case :file.position(io_device, offset) do
      {:ok, _newpos} ->
        {:ok, io_device}

      err ->
        File.close(io_device)
        err
    end
  end

  defp seek({:error, err}, _offset) do
    Logger.error("Cannot open file for reading: #{inspect(err)}")
    {:error, :file_error}
  end

  # Accepts both :chunk_size (preferred) and :chunk_len (legacy) option names
  defp get_chunk_size(opts) do
    Keyword.get(opts, :chunk_size, Keyword.get(opts, :chunk_len, 4_194_304))
  end
end
