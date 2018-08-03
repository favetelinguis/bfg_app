defmodule BfgEngine.MarketsServer do
  use GenServer
  use Timex
  require Logger

  alias BfgEngine.{RestConnection}

  def list_market_ids() do
    list_markets()
    |> Enum.map(&Map.get(&1, :marketId))
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_args) do
    Logger.info(fn -> "Starting Markets server" end)
    state = nil
    {:ok, state}
  end

  @doc """
  Returns a list of market_ids sorted on start time, earliest starttime first
  """
  def list_markets() do
    GenServer.call(__MODULE__, :get_markets)
  end

  @doc """
  Returns a list where head is the next market to start and tail are the other ones
  Assumes a sorted list as given by list_markets
  """
  def get_next_and_all_after(markets) do
    markets
    |> Enum.filter(&Timex.before?(Timex.now, &1.marketStartTime))
  end

  def handle_call(:get_markets, _from, state) do
    state = case state do
      nil ->
        {:ok, [_|_] = markets} = RestConnection.list_market_catalogue()
        markets
        |> convert_start_time_to_datetime()
        |> sort_by_start_time()
      _ -> state
    end
    {:reply, state, state}
  end

  defp sort_by_start_time(markets) do
    markets
    |> Enum.sort_by(&(&1.marketStartTime))
  end

  defp convert_start_time_to_datetime(markets) do
    markets
    |> Enum.map(&(%{&1 | marketStartTime: Timex.parse(&1.marketStartTime, "{ISO:Extended}") |> elem(1)}))
  end
end

# {:ok,
#  %HTTPoison.Response{
#    body: {:ok,
#     [
#       %{
#         marketId: "1.145539104",
#         marketName: "2m4f Nov Hrd",
#         marketStartTime: "2018-07-15T13:00:00.000Z",
#         runners: [
#           %{
#             handicap: 0.0,
#             runnerName: "Montanna",
#             selectionId: 12996663,
#             sortPriority: 1
#           },
#           %{
#             handicap: 0.0,
#             runnerName: "Judge Earle",
#             selectionId: 12528574,
#             sortPriority: 2
#           },
#           %{
#             handicap: 0.0,
#             runnerName: "Court Dreaming",
#             selectionId: 142049,
#             sortPriority: 3
#           },
#           %{
#             handicap: 0.0,
#             runnerName: "Farocco",
#             selectionId: 13696504,
#             sortPriority: 4
#           },
#           %{
#             handicap: 0.0,
#             runnerName: "Solway Berry",
#             selectionId: 10183509,
#             sortPriority: 5
#           },
#           %{
#             handicap: 0.0,
#             runnerName: "Single Estate",
#             selectionId: 11374286,
#             sortPriority: 6
#           },
#           %{
#             handicap: 0.0,
#             runnerName: "Country Delights",
#             selectionId: 15014282,
#             sortPriority: 7
#           },
#           %{
#             handicap: 0.0,
#             runnerName: "Cushy Butterfield",
#             selectionId: 12201701,
#             sortPriority: 8
#           }
#         ],
#         totalMatched: 15918.28
#       },
#       %{
#         marketId: "1.145539069",
#         marketName: "2m Juv Hrd",
#         marketStartTime: "2018-07-15T13:10:00.000Z",
#         runners: [
#           %{
#             handicap: 0.0,
#             runnerName: "Adams Park",
#             selectionId: 13804752,
#             sortPriority: 1
#           },
#           %{
#             handicap: 0.0,
#             runnerName: "Parmenter",
#             selectionId: 14708036,
#             sortPriority: 2
#           },
#           %{
#             handicap: 0.0,
#             runnerName: "Weinberg",
#             selectionId: 14569147,
#             sortPriority: 3
#           },
#           %{
#             handicap: 0.0,
#             runnerName: "Red Miracle",
#             selectionId: 14708025,
#             sortPriority: 4
#           },
#           %{
#             handicap: 0.0,
#             runnerName: "Go Now Go Now",
#             selectionId: 12988772,
#             sortPriority: 5
#           },
#           %{
#             handicap: 0.0,
#             runnerName: "Sheriff",
#             selectionId: 58844,
#             sortPriority: 6
#           },
#           %{
#             handicap: 0.0,
#             runnerName: "Enforcement",
#             selectionId: 14766962,
#             sortPriority: 7
#           },
#           %{
#             handicap: 0.0,
#             runnerName: "Denis",
#             selectionId: 5306998,
#             sortPriority: 8
#           }
#         ],
#         totalMatched: 5445.76
#       }
#     ]},
#    headers: [
#      {"Date", "Sun, 15 Jul 2018 10:20:43 GMT"},
#      {"Server", "Cougar - 4.4.2 (Cougar 2 mode)"},
#      {"Cache-Control", "no-cache"},
#      {"Content-Type", "application/json;charset=utf-8"},
#      {"Content-Encoding", "gzip"},
#      {"Vary", "Accept-Encoding, User-Agent"},
#      {"Content-Length", "484"}
#    ],
#    request_url: "https://api.betfair.com/exchange/betting/rest/v1.0/listMarketCatalogue/",
#    status_code: 200
#  }}
