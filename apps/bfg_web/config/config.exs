# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :bfg_web,
  namespace: BfgWeb

# Configures the endpoint
config :bfg_web, BfgWebWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Acrmg4/6P5Ypnc3LljTYrmTfT1iuW1uiiVv9h7pjjEwHl48ZFH+FGqakcpCZj/P7",
  render_errors: [view: BfgWebWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: BfgWeb.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

config :phoenix, :template_engines,
  drab: Drab.Live.Engine

config :drab, BfgWebWeb.Endpoint,
  otp_app: :bfg_web

config :drab, BfgWebWeb.Endpoint,
  js_socket_constructor: "window.__socket"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
