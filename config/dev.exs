import Config

config :blog, Blog.Repo, database: Path.expand("../blog_dev.db", __DIR__)
