defmodule Transloaditex.Response do
  defstruct [:data, :status_code, :headers]

  def new({:ok, response}) do
    %Transloaditex.Response{
      data: decode_json(response.body),
      status_code: response.status,
      headers: response.headers
    }
  end

  def new({:error, reason}), do: {:error, reason}

  @doc false
  def status_code(response), do: response.status_code

  @doc false
  def headers(response), do: response.headers

  defp decode_json(body) do
    {:ok, data} = Jason.decode(body)
    data
  end

  @doc false
  def as_response(func) when is_function(func, 0) do
    response = func.()
    Transloaditex.Response.new(response)
  end
end
