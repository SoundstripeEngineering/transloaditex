defmodule Transloaditex.Queue do
  @moduledoc """
  Transloaditex.Queue Description
  """
  alias Transloaditex.Request

  @doc """
  Get the list of currently used priority job slots

  ## Returns:

    An instance of `Transloaditex.Response`.
  """
  def get_job_slots() do
    Request.get("/queues/job_slots")
  end
end
