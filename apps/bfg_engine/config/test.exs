use Mix.Config

config :bfg_engine,
stream_url: 'localhost'
stream_port: 1414
session_managemenet_url: "http://localhost:1337"
keep_alive_ms: 1000

config :bypass, adapter: Plug.Adapters.Cowboy2

config :ex_unit, assert_receive_timeout: 3000
