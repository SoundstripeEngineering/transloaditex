defmodule Transloaditex.QueueTest do
  use ExUnit.Case

  import Mox

  setup :verify_on_exit!

  @success_response {:ok, %{status_code: 200}}
  @error_response {:error, "error message"}

  describe "get_job_slots/0" do
    test "returns successfully" do
      Transloaditex.RequestMock
      |> expect(:get, fn path ->
        assert path == "/queues/job_slots"
        @success_response
      end)

      assert @success_response == Transloaditex.Queue.get_job_slots()
    end

    test "returns an error" do
      Transloaditex.RequestMock
      |> expect(:get, fn path ->
        assert path == "/queues/job_slots"
        @error_response
      end)

      assert @error_response == Transloaditex.Queue.get_job_slots()
    end
  end
end
