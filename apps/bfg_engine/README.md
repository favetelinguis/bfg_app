# BfgEngine

prometheus
/usr/local/Cellar/prometheus/2.3.1/bin

start prometheus
create a config file and then start
prometheus --config.file=prometheus.yml

Start grafana
grafana-server --config=/usr/local/etc/grafana/grafana.ini --homepath /usr/local/share/grafana cfg:default.paths.logs=/usr/local/var/log/grafana cfg:default.paths.data=/usr/local/var/lib/grafana cfg:default.paths.plugins=/usr/local/var/lib/grafana/plugins

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `bfg_engine` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bfg_engine, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/bfg_engine](https://hexdocs.pm/bfg_engine).

