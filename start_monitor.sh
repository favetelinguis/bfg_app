#!/usr/bin/env bash
docker run -p 9090:9090 -v /Users/henriklarsson/repos/elixir/bfg_app/prometheus.yml:/etc/prometheus/prometheus.yml \
       prom/prometheus &

docker run -d -p 3000:3000 grafana/grafana &