import Config

config :blog, port: 4002

config :blog, Blog.Repo,
  database: Path.expand("../priv/blog_test.db", __DIR__),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 1
