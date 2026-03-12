defmodule TusClient.Utils do
  @moduledoc false

  @doc false
  # Handles Req response headers (map of string => list of strings)
  def get_header(headers, header_name) when is_map(headers) do
    case Map.get(headers, String.downcase(header_name)) do
      [value | _] -> value
      _ -> nil
    end
  end

  # Handles legacy list-of-tuples header format
  def get_header(headers, header_name) when is_list(headers) do
    lowered = String.downcase(header_name)

    Enum.find_value(headers, fn {k, v} ->
      if String.downcase(k) == lowered, do: v
    end)
  end

  @doc false
  def add_version_hdr(headers) do
    headers ++ [{"tus-resumable", "1.0.0"}]
  end

  @doc false
  def add_tus_content_type(headers) do
    headers ++ [{"content-type", "application/offset+octet-stream"}]
  end

  @doc false
  def req_options(tus_opts) do
    case Keyword.get(tus_opts, :ssl, []) do
      [] -> []
      ssl_opts -> [connect_options: [transport_opts: ssl_opts]]
    end
  end
end
