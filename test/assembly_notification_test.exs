defmodule Transloaditex.AssemblyNotificationTest do
  use ExUnit.Case

  import Mox

  setup :verify_on_exit!

  @success_response {:ok, %{status_code: 200}}

  describe "replay/1" do
    test "replays the notification" do
      Transloaditex.RequestMock
      |> expect(:post, fn path, data ->
        assert path == "/assembly_notifications/abc123/replay"
        assert data == %{}

        @success_response
      end)

      result = Transloaditex.AssemblyNotification.replay("abc123")
      assert @success_response == result
    end
  end

  describe "replay/2" do
    test "replays the notification with options" do
      Transloaditex.RequestMock
      |> expect(:post, fn path, data ->
        assert path == "/assembly_notifications/abc123/replay"
        assert data == %{wait: false}

        @success_response
      end)

      result = Transloaditex.AssemblyNotification.replay("abc123", %{wait: false})
      assert @success_response == result
    end
  end

  describe "replay with invalid argument" do
    test "returns error for non-string argument" do
      assert {:error, "Invalid argument. Provide a valid assembly id"} ==
               Transloaditex.AssemblyNotification.replay(123)
    end
  end
end
