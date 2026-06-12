ExUnit.start()

Ecto.Adapters.SQLite3.storage_up(Blog.Repo.config())

Ecto.Migrator.run(Blog.Repo, Path.expand("../priv/repo/migrations", __DIR__), :up, all: true)

Ecto.Adapters.SQL.Sandbox.mode(Blog.Repo, :manual)
