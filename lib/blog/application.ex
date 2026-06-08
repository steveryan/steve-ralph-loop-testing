defmodule Blog.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    port = Application.get_env(:blog, :port, 4000)

    children = [
      {Bandit, plug: Blog.Router, scheme: :http, port: port}
    ]

    opts = [strategy: :one_for_one, name: Blog.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
