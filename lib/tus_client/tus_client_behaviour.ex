defmodule TusClient.Behaviour do
  @moduledoc false
  @callback upload(
              binary(),
              binary(),
              list(
                {:metadata, binary()}
                | {:max_retries, integer()}
                | {:chunk_len, integer()}
                | {:headers, list()}
                | {:ssl, list()}
                | {:follow_redirect, boolean()}
              )
            ) :: {:ok, binary} | {:error, any()}
end
