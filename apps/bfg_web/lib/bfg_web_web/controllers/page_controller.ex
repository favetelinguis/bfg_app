defmodule BfgWebWeb.PageController do
  use BfgWebWeb, :controller

  def index(conn, _params) do
    market_ids = BfgEngine.MarketsServer.list_market_ids()
    render conn, "index.html", market_ids: market_ids, genevent: ""
  end

end
