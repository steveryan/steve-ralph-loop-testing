{:ok, _} = Application.ensure_all_started(:blog)

Ecto.Adapters.SQL.Sandbox.mode(Blog.Repo, :manual)

ExUnit.start()
