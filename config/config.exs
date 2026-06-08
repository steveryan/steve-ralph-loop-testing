import Config

config :blog,
  port: String.to_integer(System.get_env("PORT") || "4000")

import_config "#{config_env()}.exs"
