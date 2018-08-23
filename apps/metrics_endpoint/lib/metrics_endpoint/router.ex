defmodule MetricsEndpoint.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/metrics" do
    metrics = Prometheus.Format.Text.format(:all)
    send_resp(conn, 200, metrics)
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end
