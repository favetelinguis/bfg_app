# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# Underlying module require single quoted string
config :bfg_engine,
stream_port: 443,
session_managemenet_url: "https://identitysso.betfair.com/api",
betting_url: "https://api.betfair.com/exchange/betting/rest/v1.0",
account_url: "https://api.betfair.com/exchange/account/rest/v1.0",
keep_alive_ms: 1000 * 3600 * 3, # 3 hours
ladder_levels: 2,
betfair_user: System.get_env("BETFAIR_USER"),
betfair_password: System.get_env("BETFAIR_PASSWORD"),
betfair_app_key: System.get_env("BETFAIR_APPKEY_DELAY")

config :bfg_engine, BfgEngine.Repo,
adapter: Ecto.Adapters.Postgres,
database: "bfg",
username: "postgres",
password: "postgres",
hostname: "localhost"

config :bfg_engine, :ecto_repos, [BfgEngine.Repo]
# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :bfg_engine, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:bfg_engine, :key)
#
# You can also configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
import_config "#{Mix.env}.exs"
