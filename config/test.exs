import Config

config :blog, port: 4001

config :blog, Blog.Repo,
  database: Path.expand("../blog_test.db", __DIR__),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 5
