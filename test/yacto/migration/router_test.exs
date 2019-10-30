defmodule Yacto.Migration.RouterTest do
  use PowerAssert

  defmodule Item do
    use Yacto.Schema

    def dbname(), do: :default

    schema "item" do
    end
  end

  defmodule Player do
    use Yacto.Schema

    def dbname(), do: :player

    schema "player" do
    end
  end

  defmodule Repo.Default do
    use Ecto.Repo, otp_app: :yacto, adapter: Ecto.Adapters.MyXQL
  end

  defmodule Repo.Player1 do
    use Ecto.Repo, otp_app: :yacto, adapter: Ecto.Adapters.MyXQL
  end

  defmodule Repo.Player2 do
    use Ecto.Repo, otp_app: :yacto, adapter: Ecto.Adapters.MyXQL
  end

  @databases %{
    default: %{module: Yacto.DB.Single, repo: Repo.Default},
    player: %{
      module: Yacto.DB.Shard,
      repos: [Repo.Player1, Repo.Player2]
    }
  }

  test "Yacto.Migration.Util.allow_migrate?" do
    allow_migrate? = &Yacto.Migration.Util.allow_migrate?/3
    assert true == allow_migrate?.(Item, Repo.Default, databases: @databases)
    assert false == allow_migrate?.(Item, Repo.Player1, databases: @databases)
    assert false == allow_migrate?.(Item, Repo.Player2, databases: @databases)
    assert false == allow_migrate?.(Player, Repo.Default, databases: @databases)
    assert true == allow_migrate?.(Player, Repo.Player1, databases: @databases)
    assert true == allow_migrate?.(Player, Repo.Player2, databases: @databases)
  end
end
