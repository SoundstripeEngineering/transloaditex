defmodule Transloaditex.AssemblyTest do
  use ExUnit.Case

  import Mox

  setup :verify_on_exit!

  @success_response {:ok, %{status_code: 200}}
  @upload_file_path "assets/logo.png"

  @create_assembly_completed %Transloaditex.Response{
    status_code: 200,
    headers: [],
    data: %{
      "ok" => "ASSEMBLY_COMPLETED"
    }
  }

  @create_assembly_not_completed %Transloaditex.Response{
    status_code: 200,
    headers: [],
    data: %{
      "ok" => "ASSEMBLY_NOT_COMPLETED",
      "assembly_url" => "https://transloadit.com/abc123",
      "assembly_ssl_url" => "https://transloadit.com/abc123",
      "tus_url" => "https://transloaditex.com/resumable/files/"
    }
  }

  @create_assembly_rate_limit_reached %Transloaditex.Response{
    status_code: 200,
    headers: [],
    data: %{
      "error" => "RATE_LIMIT_REACHED",
      "assembly_url" => "https://transloadit.com/abc123",
      "assembly_ssl_url" => "https://transloadit.com/abc123",
      "tus_url" => "https://transloaditex.com/resumable/files/"
    }
  }

  @assembly_uploading %Transloaditex.Response{
    status_code: 200,
    headers: [],
    data: %{
      "ok" => "ASSEMBLY_UPLOADING",
      "assembly_url" => "https://transloadit.com/abc123",
      "assembly_ssl_url" => "https://transloadit.com/abc123",
      "tus_url" => "https://transloaditex.com/resumable/files/"
    }
  }

  describe "create_assembly/0" do
    test "is missing arguments" do
      assert {:error, "Missing or invalid parameters"} == Transloaditex.Assembly.create_assembly()
    end
  end

  describe "create_assembly/1" do
    test "it is successful, non-resumable, no waiting" do
      Transloaditex.RequestMock
      |> expect(:post, fn path, steps, files ->
        assert path == "/assemblies"
        assert steps == %{steps: %{"resize" => %{height: 70, robot: "/image/size", width: 70}}}
        assert files == %{files: "{\"file\":\"assets/logo.png\"}"}

        @create_assembly_completed
      end)

      steps = Transloaditex.Step.add_step("resize", "/image/size", width: 70, height: 70)
      files = Transloaditex.File.add_file(@upload_file_path)

      options = %{
        steps: steps,
        files: files,
        wait: false,
        resumable: false
      }

      response = Transloaditex.Assembly.create_assembly(options)
      assert @create_assembly_completed == response
    end

    test "it is successful, non-resumable, waiting" do
      Transloaditex.RequestMock
      |> expect(:post, fn path, steps, files ->
        assert path == "/assemblies"
        assert steps == %{steps: %{"resize" => %{height: 70, robot: "/image/size", width: 70}}}
        assert files == %{files: "{\"file\":\"assets/logo.png\"}"}

        @create_assembly_not_completed
      end)

      Transloaditex.RequestMock
      |> expect(:get, fn path ->
        assert path == "https://transloadit.com/abc123"

        @create_assembly_completed
      end)

      steps = Transloaditex.Step.add_step("resize", "/image/size", width: 70, height: 70)
      files = Transloaditex.File.add_file(@upload_file_path)

      options = %{
        steps: steps,
        files: files,
        wait: true,
        resumable: false
      }

      response = Transloaditex.Assembly.create_assembly(options)
      assert @create_assembly_not_completed == response
    end

    test "it times out waiting, non-resumable, waiting" do
      Transloaditex.RequestMock
      |> expect(:post, fn path, steps, files ->
        assert path == "/assemblies"
        assert steps == %{steps: %{"resize" => %{height: 70, robot: "/image/size", width: 70}}}
        assert files == %{files: "{\"file\":\"assets/logo.png\"}"}

        @create_assembly_not_completed
      end)

      Transloaditex.RequestMock
      |> expect(:get, 5, fn path ->
        assert path == "https://transloadit.com/abc123"

        @assembly_uploading
      end)

      steps = Transloaditex.Step.add_step("resize", "/image/size", width: 70, height: 70)
      files = Transloaditex.File.add_file(@upload_file_path)

      options = %{
        steps: steps,
        files: files,
        wait: true,
        resumable: false
      }

      response = Transloaditex.Assembly.create_assembly(options)
      assert {:error, "Max retries reached without completion."} == response
    end

    test "it has reached api rate limit" do
      Transloaditex.RequestMock
      |> expect(:post, 6, fn path, steps, files ->
        assert path == "/assemblies"
        assert steps == %{steps: %{"resize" => %{height: 70, robot: "/image/size", width: 70}}}
        assert files == %{files: "{\"file\":\"assets/logo.png\"}"}

        @create_assembly_rate_limit_reached
      end)

      steps = Transloaditex.Step.add_step("resize", "/image/size", width: 70, height: 70)
      files = Transloaditex.File.add_file(@upload_file_path)

      options = %{
        steps: steps,
        files: files,
        wait: false,
        resumable: false
      }

      response = Transloaditex.Assembly.create_assembly(options)
      assert @create_assembly_rate_limit_reached == response
    end

    test "it is successful, resumable, not waiting" do
      Transloaditex.RequestMock
      |> expect(:post, fn path, steps, extra_data ->
        assert path == "/assemblies"
        assert steps == %{steps: %{"resize" => %{height: 70, robot: "/image/size", width: 70}}}
        assert extra_data == %{"tus_num_expected_upload_files" => "1"}

        @create_assembly_not_completed
      end)

      TusClientMock
      |> expect(:upload, fn base_url, path, options ->
        assert base_url == "https://transloaditex.com/resumable/files/"
        assert path == Path.absname(@upload_file_path)

        assert options == [
                 max_retries: 5,
                 chunk_size: 5 * 1024 * 1024,
                 metadata: %{
                   assembly_url: "https://transloadit.com/abc123",
                   assembly_ssl_url: "https://transloadit.com/abc123",
                   fieldname: "file",
                   filename: Path.basename(@upload_file_path)
                 }
               ]

        @create_assembly_completed
      end)

      steps = Transloaditex.Step.add_step("resize", "/image/size", width: 70, height: 70)
      files = Transloaditex.File.add_file(@upload_file_path)

      options = %{
        steps: steps,
        files: files,
        wait: false,
        resumable: true
      }

      response = Transloaditex.Assembly.create_assembly(options)
      assert @create_assembly_not_completed == response
    end

    test "it is successful, resumable, waiting" do
      Transloaditex.RequestMock
      |> expect(:post, fn path, steps, extra_data ->
        assert path == "/assemblies"
        assert steps == %{steps: %{"resize" => %{height: 70, robot: "/image/size", width: 70}}}
        assert extra_data == %{"tus_num_expected_upload_files" => "1"}

        @create_assembly_not_completed
      end)

      TusClientMock
      |> expect(:upload, fn base_url, path, options ->
        assert base_url == "https://transloaditex.com/resumable/files/"
        assert path == Path.absname(@upload_file_path)

        assert options == [
                 max_retries: 5,
                 chunk_size: 5 * 1024 * 1024,
                 metadata: %{
                   assembly_url: "https://transloadit.com/abc123",
                   assembly_ssl_url: "https://transloadit.com/abc123",
                   fieldname: "file",
                   filename: Path.basename(@upload_file_path)
                 }
               ]

        @create_assembly_completed
      end)

      Transloaditex.RequestMock
      |> expect(:get, fn path ->
        assert path == "https://transloadit.com/abc123"

        @assembly_uploading
      end)

      Transloaditex.RequestMock
      |> expect(:get, fn path ->
        assert path == "https://transloadit.com/abc123"

        @create_assembly_completed
      end)

      steps = Transloaditex.Step.add_step("resize", "/image/size", width: 70, height: 70)
      files = Transloaditex.File.add_file(@upload_file_path)

      options = %{
        steps: steps,
        files: files,
        wait: true,
        resumable: true
      }

      response = Transloaditex.Assembly.create_assembly(options)
      assert @create_assembly_not_completed == response
    end
  end

  describe "get_assembly/0" do
    test "is missing argument" do
      assert {:error, "Missing or invalid argument. Provide an assembly id or url"} ==
               Transloaditex.Assembly.get_assembly()
    end
  end

  describe "get_assembly/1" do
    test "invalid parameter" do
      assert {:error, "Missing or invalid argument. Provide an assembly id or url"} ==
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
