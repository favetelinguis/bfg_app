defmodule BfgEngine.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    usr = Application.get_env(:bfg_engine, :betfair_user)
    pwd = Application.get_env(:bfg_engine, :betfair_password)
    app_key = Application.get_env(:bfg_engine, :betfair_app_key)
    # List all child processes to be supervised
    children = [
      BfgEngine.PubSub,
      BfgEngine.Repo,
      #BfgEngine.ServerRegistry,
      #BfgEngine.MarketCache,
      #BfgEngine.StrategyCache,
      #BfgEngine.OrderCache,
      #BfgEngine.MarketsServer,
      #BfgEngine.Subscriber,
      #{BfgEngine.Cerebro, %{password: pwd, username: usr, app_key: app_key, certs: ""}}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BfgEngine.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
