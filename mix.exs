defmodule Yacto.Mixfile do
  use Mix.Project

  def project do
    [
      app: :yacto,
      version: "1.2.4",
      elixir: "~> 1.5",
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
      {:ecto, "~> 2.2"},
      {:ex_doc, "~> 0.18.3", only: :dev, runtime: false},
      {:db_connection, "~> 1.1"},
      {:mariaex, "~> 0.8.4"},
      {:uuid, "~> 1.1"},
      {:memoize, "~> 1.2"},
      {:power_assert, "~> 0.1.1", only: :test}
    ]
  end
end
