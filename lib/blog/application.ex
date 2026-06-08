defmodule Blog.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Bandit, plug: Blog.Router, scheme: :http, port: port()}
    ]

    opts = [strategy: :one_for_one, name: Blog.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp port do
    System.get_env("PORT", "4000") |> String.to_integer()
  end
end
