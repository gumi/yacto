defmodule Yacto.Mixfile do
  use Mix.Project

  @source_url "https://github.com/gumi/yacto"
  @version "2.0.3"

  def project do
    [
      app: :yacto,
      version: @version,
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [all_warnings: true, warnings_as_errors: true],
      start_permanent: Mix.env() == :prod,
      test_paths: ["test/yacto"],
      package: package(),
      docs: docs(),
      deps: deps()
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
      {:ecto_sql, "~> 3.8"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:myxql, "~> 0.6.2"},
      {:elixir_uuid, "~> 1.2"},
      {:memoize, "~> 1.4"},
      {:power_assert, "~> 0.3.0", only: :test}
    ]
  end

  defp package do
    [
      description:
        "A library for automatically generating a migration file " <>
          "and horizontally partitioning databases",
      maintainers: ["melpon", "kenichirow"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/gumi/yacto"}
    ]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md": [],
        LICENSE: [title: "ライセンス"],
        "README.md": [title: "概要"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end
end
