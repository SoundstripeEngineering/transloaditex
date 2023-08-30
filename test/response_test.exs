defmodule Transloaditex.ResponseTest do
  use ExUnit.Case
  alias Transloaditex.Response

  setup do
    valid_response = %{
      body: ~s({"key": "value"}),
      status: 200,
      headers: [{"content-type", "application/json"}]
    }

    error_reason = :some_error_reason

    test_function = fn ->
      {:ok, valid_response}
    end

    test_function_error = fn ->
      {:error, error_reason}
    end

    {:ok, test_function: test_function, test_function_error: test_function_error}
  end

  describe "new/1" do
    test "creates a new Response struct on valid input", %{test_function: test_function} do
      response = Response.new(test_function.())
      assert response.data == %{"key" => "value"}
      assert response.status_code == 200
      assert response.headers == [{"content-type", "application/json"}]
    end

    test "returns an error tuple on error input", %{test_function_error: test_function_error} do
      assert Response.new(test_function_error.()) == {:error, :some_error_reason}
    end
  end

  describe "status_code/1 and headers/1" do
    test "return correct status code and headers", %{test_function: test_function} do
      response = Response.new(test_function.())
      assert Response.status_code(response) == 200
      assert Response.headers(response) == [{"content-type", "application/json"}]
    end
  end

  describe "as_response/1" do
    test "wraps function output into a Response struct", %{test_function: test_function} do
      response = Response.as_response(test_function)
      assert response.data == %{"key" => "value"}
      assert response.status_code == 200
      assert response.headers == [{"content-type", "application/json"}]
    end

    test "wraps function error output into an error tuple", %{
      test_function_error: test_function_error
    } do
      assert Response.as_response(test_function_error) == {:error, :some_error_reason}
    end
  end
end
