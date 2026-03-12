defmodule Transloaditex.AssemblyNotification do
  defp request, do: Application.get_env(:transloaditex, :request, Transloaditex.Request)

  @doc """
  Replay the notification for the specified assembly.

  Re-sends the POST containing the Assembly result JSON to the original `notify_url`.

  ## Args

    * `assembly_id` - The assembly id whose notification to replay
    * `options` - Optional map. Supports `:wait` (boolean, default: true)

  ## Returns

    A `Transloaditex.Response` struct or `{:error, reason}`.
  """
  def replay(assembly_id, options \\ %{})

  def replay(assembly_id, options) when is_binary(assembly_id) do
    request().post("/assembly_notifications/#{assembly_id}/replay", options)
  end

  def replay(_, _), do: {:error, "Invalid argument. Provide a valid assembly id"}
end
