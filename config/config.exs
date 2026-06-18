import Config

config :blog,
  ecto_repos: [Blog.Repo],
  port: String.to_integer(System.get_env("PORT") || "4000")

import_config "#{config_env()}.exs"
