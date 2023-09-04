defmodule Transloaditex.BillTest do
  use ExUnit.Case

  import Mox

  setup :verify_on_exit!

  @success_response {:ok, %{status_code: 200}}

  describe "get_bill/1" do
    test "returns error when no parameters provided" do
      result = Transloaditex.Bill.get_bill()
      assert {:error, "Month and year should be integers"} == result
    end
  end

  describe "get_bill/2" do
    test "returns error when non-integer paramters are provided" do
      result = Transloaditex.Bill.get_bill("1", "2023")
      assert {:error, "Month and year should be integers"} == result
    end

    test "returns success message when valid paramters provided" do
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
