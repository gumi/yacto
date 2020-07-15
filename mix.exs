defmodule Yacto.Mixfile do
  use Mix.Project

  def project do
    [
      app: :yacto,
      version: "2.0.0-rc.1",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [all_warnings: true, warnings_as_errors: true],
      description:
        "A library for automatically generating a migration file and horizontally partitioning databases",
      package: [
        maintainers: ["melpon", "kenichirow"],
        licenses: ["Apache 2.0"],
        links: %{"GitHub" => "https://github.com/gumi/yacto"}
      ],
      docs: [main: "Yacto"],
      test_paths: ["test/yacto"],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: "https://github.com/gumi/yacto"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.4.2"},
      {:ex_doc, "~> 0.21.3", only: :dev, runtime: false},
      {:myxql, "~> 0.4.0"},
      {:elixir_uuid, "~> 1.2.1"},
      {:memoize, "~> 1.2"},
      {:power_assert, "~> 0.2.0", only: :test}
    ]
  end
end
