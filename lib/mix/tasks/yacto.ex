defmodule Mix.Tasks.Yacto do
  use Mix.Task

  @shortdoc "Prints Yacto help information"

  @moduledoc """
  Prints Yacto tasks and their information.

      mix yacto

  """

  @doc false
  def run(args) do
    {_opts, args, _} = OptionParser.parse(args)

    case args do
      [] ->
        general()

      _ ->
        Mix.raise("Invalid arguments, expected: mix yacto")
    end
  end

  defp general() do
    Application.ensure_all_started(:yacto)
    Mix.shell().info("Yacto v#{Application.spec(:ecto, :vsn)}")
    Mix.shell().info("Convinience migration tool for Ecto.")
    Mix.shell().info("\nAvailable tasks:\n")
    Mix.Tasks.Help.run(["--search", "yacto."])
  end
end
