defmodule Transloaditex.Request do
  @api_uri "https://api2.transloadit.com"
  @version Mix.Project.config()[:version]
  @headers %{"transloadit-client" => "elixir-sdk:#{@version}"}

  @doc """
  Makes a HTTP GET request.

  ## Args

    * `path` - URL path to which the request should be made.
    * `params` - Optional params to send along with the request.

  ## Returns

    A `Transloaditex.Response` struct or `{:error, reason}`.
  """
  def get(path, params \\ %{}) do
    url = to_full_url(path)
    payload = to_payload(params)

    Transloaditex.Response.as_response(fn ->
      Req.get(url, params: payload, headers: @headers)
    end)
  end

  @doc """
  Makes a HTTP POST request.

  ## Args

    * `path` - URL path to which the request should be made.
    * `data` - The body of the request, stored under the 'params' field.
    * `extra_data` - Additional body fields not nested under 'params'.

  ## Returns

    A `Transloaditex.Response` struct or `{:error, reason}`.
  """
  def post(path, data \\ %{}, extra_data \\ %{}) do
    url = to_full_url(path)
    payload = to_payload(data) |> Map.merge(extra_data || %{})

    Transloaditex.Response.as_response(fn ->
      Req.post(url, headers: @headers, form: payload)
    end)
  end

  @doc """
  Makes a HTTP PUT request.
  """
  def put(path, data) do
    url = to_full_url(path)
    payload = to_payload(data)

    Transloaditex.Response.as_response(fn ->
      Req.put(url, headers: @headers, form: payload)
    end)
  end

  @doc """
  Makes a HTTP DELETE request.
  """
  def delete(path, data \\ %{}) do
    url = to_full_url(path)
    payload = to_payload(data)

    Transloaditex.Response.as_response(fn ->
      Req.delete(url, headers: @headers, form: payload)
    end)
  end

  @doc """
  Converts a URL string or an endpoint + id pair into a full URL path.

  Returns the URL string on success, or `{:error, reason}` on failure.
  """
  def to_url(url_or_endpoint) when is_binary(url_or_endpoint) do
    if url?(url_or_endpoint) do
      url_or_endpoint
    else
      {:error, "Invalid or missing parameters. Expecting valid url, or endpoint and id"}
    end
  end

  def to_url(endpoint, id) when is_binary(endpoint) and is_binary(id) do
    cond do
      url?(id) ->
        id

      valid_id?(id) ->
        "/#{String.trim(endpoint, "/")}/#{id}"

      true ->
        {:error, "Invalid or missing parameters. Expecting valid url, or endpoint and id"}
    end
  end

  defp to_payload(data) do
    data =
      Map.put(data, "auth", %{
        "key" => Application.get_env(:transloaditex, :auth_key),
        "expires" => format_expiry(Application.get_env(:transloaditex, :duration)),
        "nonce" => generate_nonce()
      })

    json_data = Jason.encode!(data)
    %{"params" => json_data, "signature" => sign_data(json_data)}
  end

  defp sign_data(message) do
    auth_secret = Application.get_env(:transloaditex, :auth_secret)

    signature =
      :crypto.mac(:hmac, :sha384, auth_secret, message)
      |> Base.encode16(case: :lower)

    "sha384:#{signature}"
  end

  defp generate_nonce do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16(case: :lower)
  end

  defp format_expiry(duration) do
    DateTime.utc_now()
    |> DateTime.add(duration)
    |> Calendar.strftime("%Y/%m/%d %H:%M:%S+00:00")
  end

  defp to_full_url(url) do
    if String.starts_with?(url, ["http://", "https://"]) do
      url
    else
      @api_uri <> url
    end
  end

  defp url?(value) do
    String.match?(
      value,
      ~r/^https?:\/\/(([a-zA-Z0-9\-]+\.)*)([a-zA-Z0-9\-]+\.[a-zA-Z]{2,})(\/[a-zA-Z0-9\-\/]*)?$/
    )
  end

  defp valid_id?(value), do: String.match?(value, ~r/^[a-z0-9]+$/)
end
