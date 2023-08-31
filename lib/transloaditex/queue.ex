defmodule Transloaditex.Queue do
  @moduledoc """
  Transloaditex.Queue Description
  """

  def request, do: Application.get_env(:transloaditex, :request)

  @doc """
  Get the list of currently used priority job slots

  ## Returns:

    An instance of `Transloaditex.Response`.
  """
  def get_job_slots() do
    request().get("/queues/job_slots")
  end
end
