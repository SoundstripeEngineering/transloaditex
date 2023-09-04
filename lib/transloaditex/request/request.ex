defmodule Transloaditex.Request do
  alias Req
  # alias Req.Response

  @api_uri "https://api2.transloadit.com"
  @headers %{"Transloadit-Client": "elixir-sdk:0.1.0"}

  @doc """
  Makes a HTTP GET request

  ## Args:

    * `path` (string) - URL path to which the request should be made.
    * `params` (map) - Optional params to send along with the request. Default is an empty map.

  ## Returns:

    An instance of `Transloaditex.Response`.
  """
  def get(path, params) do
    url = get_full_url(path)
    payload = to_payload(params)

    Transloaditex.Response.as_response(fn ->
      Req.get(url, params: payload, headers: @headers)
    end)
  end

  def get(path) do
    get(path, %{})
  end

  @doc """
  Makes a HTTP POST request

  ## Args:

    * `path` (string) - URL path to which the request should be made.
    * `data` (Optional[map]) - The body of the request. THis would be stored under the 'params' field.
    * `extra_data` (Optional[map]) - This is also added to the body of the request but not under the 'params' field.
    * `files` (Optional[map]) - Files to upload with the request. THis should be a key, value pair of field name and file stream respectively.

  ## Returns:

    An instance of `Transloaditex.Response`.
  """
  def post(path, data, extra_data) do
    url = get_full_url(path)
    payload = to_payload(data)

    payload = Map.merge(payload, extra_data || %{})

    opts = [
      headers: @headers,
      form: payload
    ]

    Transloaditex.Response.as_response(fn ->
      Req.post(url, opts)
    end)
  end

  def post(path, data), do: post(path, data, %{})

  def post(path), do: post(path, %{}, %{})

  @doc """
  Makes a HTTP PUT request
  """
  def put(path, data) do
    url = get_full_url(path)
    payload = to_payload(data)

    opts = [
      headers: @headers,
      form: payload
    ]

    Transloaditex.Response.as_response(fn ->
      Req.put(url, opts)
    end)
  end

  @doc """
  Makes a HTTP DELETE request
  """
  def delete(path, data) do
    url = get_full_url(path)
    payload = to_payload(data)

    opts = [
      headers: @headers,
      form: payload
    ]

    Transloaditex.Response.as_response(fn ->
      Req.delete(url, opts)
    end)
  end

  def delete(path) do
    delete(path, %{})
  end

  def to_url(url_or_endpoint) when is_binary(url_or_endpoint) do
    case is_url?(url_or_endpoint) do
      true -> url_or_endpoint
      false -> {:error, "Invalid or missing parameters. Expecting valid url, or endpoint and id"}
    end
  end

  def to_url(endpoint, id) when is_binary(endpoint) and is_binary(id) do
    cond do
      is_url?(id) ->
        to_url(id)

      true ->
        case is_valid_id?(id) do
          true ->
            endpoint =
              cond do
                !String.starts_with?(endpoint, "/") -> "/" <> endpoint
                true -> endpoint
              end

            endpoint =
              cond do
                !String.ends_with?(endpoint, "/") -> endpoint <> "/"
                true -> endpoint
              end

            "#{endpoint}#{id}"

          false ->
            {:error, "Invalid or missing parameters. Expecting valid url, or endpoint and id"}
        end
    end
  end

  defp to_payload(data) do
    data =
      Map.put(data, "auth", %{
        "key" => Application.get_env(:transloaditex, :auth_key),
        "expires" => expires_datetime(Application.get_env(:transloaditex, :duration))
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

  defp expires_datetime(duration) do
    utc_now = DateTime.utc_now()
    new_datetime = DateTime.add(utc_now, duration)
    format_datetime(new_datetime)
  end

  defp format_datetime(datetime) do
    DateTime.to_string(datetime)
    |> String.replace("T", " ")
    |> String.split(".")
    |> hd()
    |> Kernel.<>("+00:00")
  end

  defp get_full_url(url) do
    if String.starts_with?(url, ["http://", "https://"]) do
      url
    else
      @api_uri <> url
    end
  end

  defp is_url?(value) do
    String.match?(
      value,
      ~r/^((http|https)?:\/\/)(([a-zA-Z0-9\-]+\.)*)([a-zA-Z0-9\-]+\.[a-zA-Z]{2,})(\/[a-zA-Z0-9\-\/]*)?$/
    )
  end

  defp is_valid_id?(value), do: String.match?(value, ~r/^[a-z0-9]+$/)
end
