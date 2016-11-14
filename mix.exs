defmodule Bunyan.Mixfile do
  use Mix.Project

  def project do
    [
      app: :bunyan,
      version: "0.1.0",
      elixir: "~> 1.3",
      name: "Bunyan",
      description: "JSON log generator",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      dialyzer: [plt_add_deps: :transitive],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:poison,      ">= 2.0.0"},
      {:plug,        "~> 1.0"},
      {:credo,       "~> 0.4", only: [:dev, :test]},
      {:dialyxir,    "~> 0.4", only: [:dev]},
      {:excoveralls, "~> 0.5", only: :test}
    ]
  end
end
