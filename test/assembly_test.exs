defmodule Transloaditex.AssemblyTest do
  use ExUnit.Case

  import Mox

  setup :verify_on_exit!

  @success_response {:ok, %{status_code: 200}}
  @error_response {:error, :error_reason}

  describe "create_assembly/0" do
    test "is missing arguments" do
      assert {:error, "Missing or invalid parameters"} == Transloaditex.Assembly.create_assembly()
    end
  end

  describe "get_assembly/0" do
    test "is missing argument" do
      assert {:error, "Missing or invalid argument. Provide an assembly if or url"} ==
               Transloaditex.Assembly.get_assembly()
    end
  end

  describe "get_assembly/1" do
    test "invalid parameter" do
      assert {:error, "Missing or invalid argument. Provide an assembly if or url"} ==
               Transloaditex.Assembly.get_assembly(123)
    end

    test "successfully returns assembly" do
      Transloaditex.RequestMock
      |> expect(:get, fn path ->
        assert path == "/assemblies/abc123"

        @success_response
      end)

      result = Transloaditex.Assembly.get_assembly("abc123")
      assert @success_response == result
    end
  end

  describe "list_assemblies/0" do
    test "it lists the assemblies" do
      Transloaditex.RequestMock
      |> expect(:get, fn path, params ->
        assert path == "/assemblies"
        assert params == %{}
        @success_response
      end)

      result = Transloaditex.Assembly.list_assemblies()
      assert @success_response == result
    end
  end

  describe "list_assemblies/1" do
    test "it passes params to list_assemblies" do
      Transloaditex.RequestMock
      |> expect(:get, fn path, params ->
        assert path == "/assemblies"

        assert params == %{
                 page: 5,
                 pagesize: 10,
                 type: "uploading",
                 fromdate: "2023-01-01 00:00:00"
               }

        @success_response
      end)

      result =
        Transloaditex.Assembly.list_assemblies(%{
          page: 5,
          pagesize: 10,
          type: "uploading",
          fromdate: "2023-01-01 00:00:00"
        })

      assert @success_response == result
    end
  end

  describe "cancel_assembly/1" do
    test "successfully cancels the assembly" do
      Transloaditex.RequestMock
      |> expect(:delete, fn path ->
        assert path == "/assemblies/123abc"

        @success_response
      end)

      result = Transloaditex.Assembly.cancel_assembly("123abc")
      assert @success_response == result
    end
  end

  describe "cancel_assembly/0" do
    test "it is missing the argument" do
      assert {:error, "Missing parameter. Provide an assembly id or url"} ==
               Transloaditex.Assembly.cancel_assembly()
    end
  end
end
