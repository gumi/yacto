defmodule Yacto.Mixfile do
  use Mix.Project

  def project do
    [
      app: :yacto,
      version: "0.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env),
      elixirc_options: [all_warnings: true],
      test_paths: ["test/yacto"],
      start_permanent: Mix.env == :prod,
      deps: deps(),
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 2.1"},
      {:db_connection, "~> 1.1"},
      {:mariaex, "~> 0.8.2"},
      {:uuid, "~> 1.1"},
      {:power_assert, "~> 0.1.1", only: :test},
    ]
  end
end
