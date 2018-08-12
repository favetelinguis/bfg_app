defmodule BfgEngine.Betfairex.Api.Session do
  use HTTPoison.Base

  @base_url Application.get_env(:bfg_engine, :session_managemenet_url)

  def process_url(resource) do
    @base_url <> resource
  end

  def process_request_headers(headers) do
    headers ++
      [
        "content-type": "Application/json; Charset=utf-8",
        Accept: "Application/json; Charset=utf-8"
      ]
  end

  def process_response_body(body) do
    body
    |> Poison.Parser.parse(keys: :atoms)
  end

  def process_request_body(body) do
    body
    |> Poison.encode!()
  end
end
