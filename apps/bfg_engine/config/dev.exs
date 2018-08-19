use Mix.Config


config :bfg_engine,
stream_url: 'stream-api-integration.betfair.com'

config :logger,
  level: :debug

config :bfg_engine, BfgEngine.Repo,
loggers: []
