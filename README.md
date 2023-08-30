<p align="center">
  <img src="../transloadit-logo.png" />
</p>

# Transloaditex

[![Elixir CI](https://github.com/SoundstripeEngineering/transloaditex/actions/workflows/ci.yml/badge.svg)](https://github.com/SoundstripeEngineering/transloaditex)
[![Module Version](https://img.shields.io/hexpm/v/transloaditex.svg)](https://hex.pm/packages/transloaditex)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/transloaditex/)
[![Total Download](https://img.shields.io/hexpm/dt/transloaditex.svg)](https://hex.pm/packages/transloaditex)
[![License](https://img.shields.io/hexpm/l/transloaditex.svg)](https://github.com/WTTJ/transloaditex/blob/master/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/SoundstripeEngineering/transloaditex.svg)](https://github.com/SoundstripeEngineering/transloaditex/commits/master)

Transloaditex is an Elixir implmenetation of [Transloadit
API](https://transloadit.com/docs/api/).

## Installation

The package can be installed by adding `transloaditex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:transloaditex, "~> 0.1.0"}
  ]
end
```

## Configuration

Transloaditex can be configured using [Config](https://hexdocs.pm/elixir/1.15/Config.html) or environment variables.

### Config

  * `auth_key` (string) - Auth key...
  * `auth_secret` (string) - Auth secret...
  * `max_retries` (Optional[int]) - Maximum number of retries before timing out
  * `duration` (Optional[int]) - Amount of time for auth expiration, value is in seconds

```elixir
config :transloaditex,
  auth_key: "my-auth-key",
  auth_secret: "my-auth-secret",
  max_retries: 10,
  duration: 300

```

### Environment variables

```
export TRANSLOADIT_AUTH_KEY=my-auth-key
export TRANSLOADIT_AUTH_SECRET=my-auth-secret
export TRANSLOADIT_MAX_RETRIES=max-retries-count
export TRANSLOADIT_DURATION=max-duration
```

### Usage

```elixir
response = Transloaditex.Assembly.create_assembly(%{steps: steps, files: files})

response = Transloaditex.Assembly.get_assembly(assembly_id)

response = Transloaditex.Template.create_template("my_custom_template", steps)
```

### Example:

```elixir
steps =
  Transloaditex.Step.add_step(":original", "/upload/handle")
  |> Transloaditex.Step.add_step("resize", "/image/resize", width: 70, height: 70)

files =
  Transloaditex.File.add_file("/assets/logo-1.jpg")
  |> Transloaditex.File.add_file("/assets/watermark.png")

response = Transloaditex.Assembly.create_assembly(
  %{
    steps: steps,
    files: files,
    wait: false,
    resumable: true
  }
)

IO.puts(response.body["message"])
```

## Run tests

```sh
mix test
```

## License
MIT
