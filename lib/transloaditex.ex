defmodule Transloaditex do
  @moduledoc """
  Transloaditex is an Elixir implementation of the [Transloadit API](https://transloadit.com/docs/api/).

  ## Installation

  Add `transloaditex` to your list of dependencies in `mix.exs`:

      def deps do
        [
          {:transloaditex, "~> 0.3.0"}
        ]
      end

  ## Configuration

  Transloaditex requires the following config items:

    * `auth_key` (string) - Your Transloadit Auth Key
    * `auth_secret` (string) - Your Transloadit Auth Secret
    * `max_retries` (integer) - Maximum number of retries before timing out (default: 10)
    * `duration` (integer) - Auth expiration time in seconds (default: 300)

      config :transloaditex,
        auth_key: "your_auth_key",
        auth_secret: "your_auth_secret",
        max_retries: 10,
        duration: 300
  """
end
