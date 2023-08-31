defmodule Transloaditex.RequestBehaviour do
  @moduledoc false

  @callback get(path :: binary, params :: map) :: any
  @callback get(path :: binary) :: any
  @callback post(path :: binary, data :: map, extra_data :: map) :: any
  @callback post(path :: binary, data :: map) :: any
  @callback post(path :: binary) :: any
  @callback put(path :: binary, data :: map) :: any
  @callback delete(path :: binary, data :: binary) :: any
  @callback delete(path :: binary) :: any
  @callback to_url(url_or_endpoint :: binary) :: any
  @callback to_url(endpoint :: binary, id :: binary) :: any
end
