defmodule BfgEngine.Betfairex.Api.Login do
  @moduledoc """
    curl -q -k --cert client-2048.crt --key client-2048.key
  https://identitysso.betfair.com/api/certlogin -d
  "username=testuser&password=testpassword" -H "X-Application:
  curlCommandLineTest"
  If successful return {:ok, sessionToken}
  {
  sessionToken: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
  loginStatus: SUCCESS;
  }

  logg at error level also
  If not SUCCESS return {:error, <login status>}
  {
  loginStatus: INVALID_USERNAME_OR_PASSWORD;
  }
  """
  use HTTPoison.Base

  @base_url Application.get_env(:bfg_engine, :session_managemenet_url)

  @expected_fields ~w(sessionToken loginStatus)

  def process_url(resource) do
    @base_url <> resource
  end

  def process_request_headers(_headers) do
    [
      "X-Application": "1",
      "content-type": "application/x-www-form-urlencoded",
      Accept: "Application/json; Charset=utf-8"
    ]
  end

  def process_response_body(body) do
    body
    |> Poison.Parser.parse!(keys: :atoms)
  end

  def process_request_body(%{username: username, password: password}) do
    "username=#{URI.encode_www_form(username)}&password=#{URI.encode_www_form(password)}"
  end

  def process_request_options(_options) do
    [
      ssl: [
        certfile: "/certs/client-2048.crt",
        keyfile: "/certs/client-2048.key"
      ]
    ]
  end
end
