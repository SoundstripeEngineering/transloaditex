defmodule Transloaditex.Response do
  defstruct [:data, :status_code, :headers]

  def new({:ok, response}) do
    %Transloaditex.Response{
      data: decode_body(response.body),
      status_code: response.status,
      headers: response.headers
    }
  end

  def new({:error, reason}), do: {:error, reason}

  @doc false
  def status_code(response), do: response.status_code

  @doc false
  def headers(response), do: response.headers

  # Req auto-decodes JSON responses, so body may already be a map or list.
  # Fall back to manual decode for string bodies, and return raw if not JSON.
  defp decode_body(body) when is_map(body), do: body
  defp decode_body(body) when is_list(body), do: body

  defp decode_body(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, data} -> data
      {:error, _} -> body
    end
  end

  defp decode_body(body), do: body

  @doc false
  def as_response(func) when is_function(func, 0) do
    response = func.()
    Transloaditex.Response.new(response)
  end
end
