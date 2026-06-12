import Config

config :blog, Blog.Repo, database: Path.expand("../blog_prod.db", __DIR__)
