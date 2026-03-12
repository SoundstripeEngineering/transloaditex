defmodule TusClient.Post do
  @moduledoc false
  alias TusClient.Utils

  require Logger

  def request(url, path, headers \\ [], opts \\ []) do
    path
    |> get_filesize()
    |> do_request(url, headers, opts)
  end

  defp do_request({:ok, size}, url, headers, opts) do
    hdrs =
      [{"upload-length", to_string(size)}]
      |> Utils.add_version_hdr()
      |> Kernel.++(headers)
      |> Enum.uniq()
      |> add_metadata(opts)

    req_opts =
      [method: :post, url: url, headers: hdrs, body: ""] ++ Utils.req_options(opts)

    case Req.request(req_opts) do
      {:ok, %{status: 201} = resp} ->
        process(resp)

      {:ok, %{status: 413}} ->
        {:error, :too_large}

      {:ok, resp} ->
        Logger.error("POST response not handled: #{inspect(resp)}")
        {:error, :generic}

      {:error, err} ->
        Logger.error("POST request failed: #{inspect(err)}")
        {:error, :transport}
    end
  end

  defp do_request(err, _url, _headers, _opts), do: err

  defp process(%{headers: headers}) when map_size(headers) == 0, do: {:error, :not_supported}

  defp process(%{headers: headers}) do
    case get_location(headers) do
      {:ok, location} -> {:ok, %{location: location}}
      _ -> {:error, :location}
    end
  end

  defp get_location(headers) do
    case Utils.get_header(headers, "location") do
      v when is_binary(v) -> {:ok, v}
      _ -> {:error, :location}
    end
  end

  defp get_filesize(path) do
    case File.stat(path) do
      {:ok, %{size: size}} -> {:ok, size}
      _ -> {:error, :file_error}
    end
  end

  defp add_metadata(headers, opts) do
    case Keyword.get(opts, :metadata) do
      md when is_map(md) ->
        new_md = cleanup_metadata(md)

        if Enum.empty?(new_md) do
          headers
        else
          headers ++ [{"upload-metadata", encode_metadata(new_md)}]
        end

      _ ->
        headers
    end
  end

  defp cleanup_metadata(md) do
    md
    |> Enum.map(fn {k, v} -> {"#{k}", v} end)
    |> Enum.filter(fn {k, _v} ->
      if k =~ ~r/^[a-zA-Z0-9_\-\.]+$/ do
        true
      else
        Logger.warning("Discarding invalid key #{k}")
        false
      end
    end)
    |> Map.new()
  end

  defp encode_metadata(md) do
    md
    |> Enum.map(fn {k, v} ->
      value = v |> to_string() |> Base.encode64()
      "#{k} #{value}"
    end)
    |> Enum.join(",")
  end
end
