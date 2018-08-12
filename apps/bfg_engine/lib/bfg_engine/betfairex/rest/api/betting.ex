defmodule BfgEngine.Betfairex.Api.Betting do
  use HTTPoison.Base
  require Logger

  @base_url Application.get_env(:bfg_engine, :betting_url)

  def process_url(resource) do
    @base_url <> resource <> "/" # last / is importatnt else method is not found at betfair side
  end

  def process_request_headers(headers) do
    headers ++
      [
        "content-type": "Application/json; Charset=utf-8",
        "Accept": "Application/json; Charset=utf-8",
        "content-type": "application/json",
        "Accept-Encoding": "gzip, deflate",
        "Connection": "keep-alive"
      ]
  end

  @doc """
  It looks like error messages are not gziped in the response only correct messages
  example
  "{\"faultcode\":\"Client\",\"faultstring\":\"ANGX-0002\",\"detail\":{\"APINGException\":{\"requestUUID\":\"prdang038-05150915-01817065f9\",\"errorCode\":\"INVALID_INPUT_DATA\",\"errorDetails\":\"The customerStrategyRef is too long (15 character limit)\"},\"exceptionname\":\"APINGException\"}}"
  """
  def process_response_body(body) do
    # TODO this is brittle, I should really look at headers
    # Also looks like betfair response with 400 if not valid so could i get status code that would be ok
    # Easiest way to check error is to supply a faulty appkey
    case String.valid?(body) do
      true -> Poison.Parser.parse(body, keys: :atoms)
      false -> body |> :zlib.gunzip() |> Poison.Parser.parse(keys: :atoms)
    end
  end

  def process_request_body(body) do
    body
    |> Poison.encode!()
  end
end
