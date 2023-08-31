defmodule Transloaditex.TemplateTest do
  use ExUnit.Case

  import Mox

  setup :verify_on_exit!

  @success_response {:ok, %{status_code: 200}}

  describe "create_template/2" do
    test "It is valid" do
      Transloaditex.RequestMock
      |> expect(:post, fn path, params ->
        assert path == "/templates"

        assert params == %{
                 name: "resize_image",
                 template: %{"resize" => %{height: 70, robot: "/image/resize", width: 70}}
               }

        @success_response
      end)

      result =
        Transloaditex.Template.create_template("resize_image", [
          %{"resize" => %{height: 70, robot: "/image/resize", width: 70}}
        ])

      assert @success_response = result
    end

    test "it has invalid arguments" do
      result = Transloaditex.Template.create_template(123, 123)

      assert {:error,
              "Missing or invalid arguments. Provide a name and either list of steps or JSON Encoded params"} ==
               result
    end
  end

  describe "create_template/0" do
    test "it is missing arguments" do
      result = Transloaditex.Template.create_template()

      assert {:error,
              "Missing or invalid arguments. Provide a name and either list of steps or JSON Encoded params"} ==
               result
    end
  end

  describe "update_template/2" do
    test "it updates the template" do
      Transloaditex.RequestMock
      |> expect(:put, fn path, params ->
        assert path == "/templates/123abc"
        assert params == %{template: %{steps: %{"step_name" => %{robot: "/image/resize"}}}}

        @success_response
      end)

      result =
        Transloaditex.Template.update_template("123abc", [
          %{"step_name" => %{robot: "/image/resize"}}
        ])

      assert @success_response == result
    end

    test "it has invalid arguments" do
      result = Transloaditex.Template.update_template(123, 123)

      assert {:error,
              "Missing or invalid arguments. Provide a valid template id and list of steps"} ==
               result
    end
  end

  describe "update_template/0" do
    test "it is missing arguments" do
      result = Transloaditex.Template.update_template()

      assert {:error,
              "Missing or invalid arguments. Provide a valid template id and list of steps"} ==
               result
    end
  end

  describe "get_template/1" do
    test "it gets the template" do
      Transloaditex.RequestMock
      |> expect(:get, fn path ->
        assert path == "/templates/abc123"
        @success_response
      end)

      result = Transloaditex.Template.get_template("abc123")
      assert @success_response == result
    end
  end

  describe "get_template/0" do
    test "missing argument" do
      result = Transloaditex.Template.get_template()
      assert {:error, "Missing arguments. Provide an template id or url"} == result
    end
  end

  describe "list_templates/0" do
    test "it lists the templates" do
      Transloaditex.RequestMock
      |> expect(:get, fn path, params ->
        assert path == "/templates"
        assert params == %{}
        @success_response
      end)

      result = Transloaditex.Template.list_templates()
      assert @success_response == result
    end
  end

  describe "list_templates/1" do
    test "it lists the templates with added params" do
      Transloaditex.RequestMock
      |> expect(:get, fn path, params ->
        assert path == "/templates"

        assert params == %{
                 page: 5,
                 pagesize: 10,
                 type: "uploading",
                 fromdate: "2023-01-01 00:00:00"
               }

        @success_response
      end)

      result =
        Transloaditex.Template.list_templates(%{
          page: 5,
          pagesize: 10,
          type: "uploading",
          fromdate: "2023-01-01 00:00:00"
        })

      assert @success_response == result
    end
  end

  describe "delete_template/1" do
    test "it deletes the template" do
      Transloaditex.RequestMock
      |> expect(:delete, fn path ->
        assert path == "/templates/123abc"

        @success_response
      end)

      response = Transloaditex.Template.delete_template("123abc")
      assert @success_response == response
    end

    test "it has an invalid argument" do
      assert {:error, "Invalid argument. Provide a valid template url or template id"} ==
               Transloaditex.Template.delete_template(123)
    end
  end

  describe "delete_template/0" do
    test "it is missing the argument" do
      assert {:error, "Missing argument. Provide a valid template url or template id"} ==
               Transloaditex.Template.delete_template()
    end
  end

  describe "get_template_id/0" do
    test "when mising template id" do
      result = Transloaditex.Template.get_template_id()
      assert {:error, "Missing or invalid argument. Provide a valid template name"} == result
    end
  end

  describe "get_template_id/1" do
    test "when template id is not a string" do
      result = Transloaditex.Template.get_template_id(12345)
      assert {:error, "Missing or invalid argument. Provide a valid template name"} == result
    end

    # Successful response, item found
    test "it gets the template_id when template exists" do
      mock_response = %Transloaditex.Response{
        status_code: 200,
        data: %{"items" => [%{"name" => "template_name", "id" => "123"}]}
      }

      Transloaditex.RequestMock
      |> expect(:get, fn path, params ->
        assert path == "/templates"
        assert params == %{}
        mock_response
      end)

      {:ok, id} = Transloaditex.Template.get_template_id("template_name")
      assert id == "123"
    end

    # Successful response, item not found
    test "it returns an error when template does not exist" do
      mock_response = %Transloaditex.Response{
        status_code: 200,
        data: %{"items" => [%{"name" => "some_other_template", "id" => "456"}]}
      }

      Transloaditex.RequestMock
      |> expect(:get, fn _path, _params -> mock_response end)

      assert {:error, "Template not found"} ==
               Transloaditex.Template.get_template_id("template_name")
    end

    # Non-200 response
    test "it returns an error when API response is non-200" do
      mock_response = %Transloaditex.Response{status_code: 404}

      Transloaditex.RequestMock
      |> expect(:get, fn _path, _params -> mock_response end)

      assert {:error, "Received non-200 status: 404"} ==
               Transloaditex.Template.get_template_id("template_name")
    end

    # UNexpected response format
    test "it returns an error when API response format is unexpected" do
      mock_response = %Transloaditex.Response{status_code: 200, data: %{"unexpected" => "data"}}

      Transloaditex.RequestMock
      |> expect(:get, fn _path, _params -> mock_response end)

      assert {:error, "Unexpected response format"} ==
               Transloaditex.Template.get_template_id("template_name")
    end
  end
end
