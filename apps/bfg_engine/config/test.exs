use Mix.Config

config :bfg_engine, stream_url: 'localhost'
config :bfg_engine, stream_port: 1414
config :bfg_engine, session_managemenet_url: "http://localhost:1337"
config :bypass, adapter: Plug.Adapters.Cowboy2
config :bfg_engine, keep_alive_ms: 1000

config :ex_unit, assert_receive_timeout: 3000
