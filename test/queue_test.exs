defmodule Transloaditex.QueueTest do
  use ExUnit.Case

  import Mox

  setup :verify_on_exit!

  @success_response {:ok, %{status_code: 200}}

  describe "get_job_slots/0" do
    test "it gets the job slots" do
      Transloaditex.RequestMock
      |> expect(:get, fn path ->
        assert path == "/queues/job_slots"
        {:ok, %{status_code: 200}}
      end)

      result = Transloaditex.Queue.get_job_slots()
      assert @success_response == result
    end
  end
end
