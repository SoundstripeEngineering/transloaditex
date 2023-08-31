defmodule Transloaditex.BillTest do
  use ExUnit.Case

  import Mox

  setup :verify_on_exit!

  @success_response {:ok, %{status_code: 200}}

  describe "get_bill/1" do
    test "it errors when there are no parameters" do
      result = Transloaditex.Bill.get_bill()
      assert {:error, "Month and year should be integers"} == result
    end
  end

  describe "get_bill/2" do
    test "it errors when non integer parameters" do
      result = Transloaditex.Bill.get_bill("1", "2023")
      assert {:error, "Month and year should be integers"} == result
    end

    test "it gets the bill information" do
      Transloaditex.RequestMock
      |> expect(:get, fn path ->
        assert path == "/bill/2023-01"
        {:ok, %{status_code: 200}}
      end)

      result = Transloaditex.Bill.get_bill(1, 2023)
      assert @success_response == result
    end
  end
end
