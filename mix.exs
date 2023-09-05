defmodule Transloaditex.MixProject do
  use Mix.Project

  @source_url "https://github.com/SoundstripeEngineering/transloaditex"

  def project do
    [
      app: :transloaditex,
      name: "transloaditex",
      description: "Elixir implementation of Transloadit API",
      maintainers: ["Soundstripe"],
      package: %{
        licenses: ["MIT"],
        links: %{
          github: @source_url
        }
      },
      source_url: @source_url,
      homepage_url: @source_url,
      version: "0.2.3",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [
        ignore_modules: [
          TusClient,
          TusClient.Head,
          TusClient.Options,
          TusClient.Patch,
          TusClient.Post,
          TusClient.Utils,
          TusClient.Behaviour
        ]
      ],
      deps: deps(),
      docs: docs()
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      env: [
        host: "api2.transloadit.com",
        auth_key: System.get_env("TRANSLOADIT_AUTH_KEY"),
        auth_secret: System.get_env("TRANSLOADIT_AUTH_SECRET")
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, "~> 0.3.11"},
      {:jason, "~> 1.4.0"},
      {:httpoison, "~> 2.0"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:mox, "~> 1.0.2", only: :test}
    ]
  end

  def docs do
    [
      extras: extras(),
      main: "readme",
      source_url: @source_url,
      homepage_url: @source_url,
      formatters: ["html"],
      groups_for_modules: [
        endpoints: [
          Transloaditex.Assembly,
          Transloaditex.Bill,
          Transloaditex.File,
          Transloaditex.Queue,
          Transloaditex.Request,
          Transloaditex.Response,
          Transloaditex.Step,
          Transloaditex.Template
        ]
      ]
    ]
  end

  defp extras() do
    ["README.md": [title: "Overview"]]
  end
end
