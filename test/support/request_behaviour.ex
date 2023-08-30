defmodule Test.Support.RequestBehaviour do
  @callback get(path :: binary, params :: map) :: any
  @callback get(path :: binary) :: any
end
