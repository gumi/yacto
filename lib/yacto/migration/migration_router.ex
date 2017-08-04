defmodule Yacto.Migration.Router do
  @callback allow_migrate(atom, atom, Keyword.t) :: true | false | nil
end

defmodule Yacto.Migration.Routers do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      otp_app = Keyword.fetch!(opts, :otp_app)
      @otp_app otp_app

      def allow_migrate(schema, repo, opts) do
        Yacto.Migration.Routers.allow_migrate(@otp_app, schema, repo, opts)
      end
    end
  end

  def get_router(app) do
    Application.get_env(app, :migration_routers, [])
  end

  def allow_migrate(app, schema, repo, opts) do
    routers = get_router(app)
    can_migrate = Enum.reduce_while(routers,
                                    nil,
                                    fn router, default ->
                                      case router.allow_migrate(schema, repo, opts) do
                                        true -> {:halt, true}
                                        false -> {:halt, false}
                                        nil -> {:cont, default}
                                      end
                                    end)
    if can_migrate == nil do
      true
    else
      can_migrate
    end
  end
end
