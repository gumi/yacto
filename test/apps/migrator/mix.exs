defmodule Migrator.Mixfile do
  use Mix.Project

  def project do
    [app: :migrator,
     version: "0.1.0",
     build_path: "../.build",
     config_path: "config/config.exs",
     deps_path: "../.deps",
     lockfile: "../mix.lock",
     elixir: "~> 1.5",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:yacto, path: "../../.."},
      {:power_assert, "~> 0.1.1", only: :test},
    ]
  end
end
