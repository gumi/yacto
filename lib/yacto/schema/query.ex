defmodule Yacto.Schema.Query do
  defmacro __using__(_) do
    quote do
      @before_compile Yacto.Schema.Query
    end
  end

  defmacro __before_compile__(env) do
    code =
      quote do
        def get(dbkey, kwargs) do
          Yacto.Query.get(unquote(env.module), Yacto.DB.repo(unquote(env.module).dbname(), dbkey), kwargs)
        end

        def create(dbkey, kwargs) do
          Yacto.Query.create(unquote(env.module), Yacto.DB.repo(unquote(env.module).dbname(), dbkey), kwargs)
        end

        def get_or_new(dbkey, kwargs) do
          Yacto.Query.get_or_new(unquote(env.module), Yacto.DB.repo(unquote(env.module).dbname(), dbkey), kwargs)
        end

        def save(dbkey, kwargs) do
          Yacto.Query.save(Yacto.DB.repo(unquote(env.module).dbname(), dbkey), kwargs)
        end
      end
    Module.create(Module.concat(env.module, Query), code, Macro.Env.location(env))

    quote do
    end
  end
end
