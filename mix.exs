defmodule Bunyan.Mixfile do
  use Mix.Project

  def project do
    [
      app: :bunyan,
      version: "0.1.0",
      elixir: "~> 1.3",
      name: "Bunyan",
      description: description(),
      package: package(),
      deps: deps(),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
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

  defp deps do
    [
      {:poison,      ">= 2.0.0"},
      {:plug,        "~> 1.0"},
      {:credo,       "~> 0.4", only: [:dev, :test]},
      {:dialyxir,    "~> 0.4", only: [:dev]},
      {:excoveralls, "~> 0.5", only: :test},
      {:ex_doc,      "~> 0.14",only: :dev}
    ]
  end

  defp description do
    """
    A JSON logger for Elixir that provides a plug logger, error logger, and
    manual logging by wrapping the standard Elixir Logger.
    """
  end

  defp package do
    [
      maintainers: ["Ben Coppock"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/bencoppock/bunyan"}
    ]
  end
end
