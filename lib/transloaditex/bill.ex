defmodule Transloaditex.Bill do
  defp request, do: Application.get_env(:transloaditex, :request, Transloaditex.Request)

  @doc """
  Get the bill for the specified month and year.

  ## Args

    * `month` - Integer month (1-12)
    * `year` - Integer year

  ## Returns

    A `Transloaditex.Response` struct or `{:error, reason}`.
  """
  def get_bill(month, year) when is_integer(month) and is_integer(year) do
    if month >= 1 and month <= 12 do
      month_str = month |> Integer.to_string() |> String.pad_leading(2, "0")
      request().get("/bill/#{year}-#{month_str}")
    else
      {:error, "Invalid month"}
    end
  end

  def get_bill(_, _), do: {:error, "Month and year should be integers"}
end
