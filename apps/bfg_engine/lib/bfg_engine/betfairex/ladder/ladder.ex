defmodule BfgEngine.Betfairex.Ladder do
  alias __MODULE__
  require Logger
  @ladder_levels Application.get_env(:bfg_engine, :ladder_levels)
  # @initial_list 0..@ladder_levels-1 |> Enum.map(&([&1, nil, nil]))

  # TODO i should put this in a map whith the keys as value and the order as index range len(ladder_levels)
  @ladder_prices [1.01, 1.02, 1.03, 1.04, 1.05, 1.06, 1.07, 1.08, 1.09, 1.10, 1.11, 1.12, 1.13, 1.14, 1.15,
                  1.16, 1.17, 1.18, 1.19, 1.20, 1.21, 1.22, 1.23, 1.24, 1.25, 1.26, 1.27, 1.28, 1.29, 1.30,
                  1.31, 1.32, 1.33, 1.34, 1.35, 1.36, 1.37, 1.38, 1.39, 1.40, 1.41, 1.42, 1.43, 1.44, 1.45,
                  1.46, 1.47, 1.48, 1.49, 1.50, 1.51, 1.52, 1.53, 1.54, 1.55, 1.56, 1.57, 1.58, 1.59, 1.60,
                  1.61, 1.62, 1.63, 1.64, 1.65, 1.66, 1.67, 1.68, 1.69, 1.70, 1.71, 1.72, 1.73, 1.74, 1.75,
                  1.76, 1.77, 1.78, 1.79, 1.80, 1.81, 1.82, 1.83, 1.84, 1.85, 1.86, 1.87, 1.88, 1.89, 1.90,
                  1.91, 1.92, 1.93, 1.94, 1.95, 1.96, 1.97, 1.98, 1.99, 2.00, 2.02, 2.04, 2.06, 2.08, 2.10,
                  2.12, 2.14, 2.16, 2.18, 2.20, 2.22, 2.24, 2.26, 2.28, 2.30, 2.32, 2.34, 2.36, 2.38, 2.40,
                  2.42, 2.44, 2.46, 2.48, 2.50, 2.52, 2.54, 2.56, 2.58, 2.60, 2.62, 2.64, 2.66, 2.68, 2.70,
                  2.72, 2.74, 2.76, 2.78, 2.80, 2.82, 2.84, 2.86, 2.88, 2.90, 2.92, 2.94, 2.96, 2.98, 3.00,
                  3.05, 3.10, 3.15, 3.20, 3.25, 3.30, 3.35, 3.40, 3.45, 3.50, 3.55, 3.60, 3.65, 3.70, 3.75,
                  3.80, 3.85, 3.90, 3.95, 4.00, 4.10, 4.20, 4.30, 4.40, 4.50, 4.60, 4.70, 4.80, 4.90, 5.00,
                  5.10, 5.20, 5.30, 5.40, 5.50, 5.60, 5.70, 5.80, 5.90, 6.00, 6.20, 6.40, 6.60, 6.80, 7.00,
                  7.20, 7.40, 7.60, 7.80, 8.00, 8.20, 8.40, 8.60, 8.80, 9.00, 9.20, 9.40, 9.60, 9.80, 10.00,
                  10.50, 11.00, 11.50, 12.00, 12.50, 13.00, 13.50, 14.00, 14.50, 15.00, 15.50, 16.00, 16.50,
                  17.00, 17.50, 18.00, 18.50, 19.00, 19.50, 20.00, 21.00, 22.00, 23.00, 24.00, 26.00, 28.00,
                  29.00, 30.00, 31.00, 32.00, 34.00, 36.00, 38.00, 40.00, 41.00, 42.00, 44.00, 46.00, 48.00,
                  50.00, 51.00, 55.00, 60.00, 61.00, 65.00, 66.00, 67.00, 70.00, 71.00, 75.00, 76.00, 80.00,
                  81.00, 85.00, 90.00, 91.00, 95.00, 100.00, 101.00, 110.00, 111.00, 120.00, 126.00, 130.00,
                  140.00, 150.00, 151.00, 160.00, 170.00, 176.00, 180.00, 190.00, 200.00, 201.00, 210.00,
                  220.00, 226.00, 230.00, 240.00, 250.00, 251.00, 260.00, 270.00, 276.00, 280.00, 290.00,
                  300.00, 301.00, 310.00, 320.00, 330.00, 340.00, 350.00, 351.00, 360.00, 370.00, 380.00,
                  390.00, 400.00, 401.00, 410.00, 420.00, 430.00, 440.00, 450.00, 460.00, 470.00, 480.00,
                  490.00, 500.00, 501.00, 510.00, 520.00, 530.00, 540.00, 550.00, 560.00, 570.00, 580.00,
                  590.00, 600.00, 610.00, 620.00, 630.00, 640.00, 650.00, 660.00, 670.00, 680.00, 690.00,
                  700.00, 710.00, 720.00, 730.00, 740.00, 750.00, 751.00, 760.00, 770.00, 780.00, 790.00,
                  800.00, 810.00, 820.00, 830.00, 840.00, 850.00, 860.00, 870.00, 880.00, 890.00, 900.00,
                  910.00, 920.00, 930.00, 940.00, 950.00, 960.00, 970.00, 980.00, 990.00, 1000.00, 1001.00]

  @idx_to_price Stream.zip(Stream.iterate(0, &(&1+1)), @ladder_prices) |> Enum.into(%{})
  @price_to_idx Stream.with_index(@ladder_prices) |> Map.new

  #TODO add support for key prices see dock with levele and add

  def new_full_depth_ladder do
    %{}
  end

  @doc """
  If no update just return original value
  """
  def update_full_depth_ladder(ladder, nil) do
    ladder
  end

  @doc """
  If the list is empy also the ladder is empty
  """
  def update_full_depth_ladder(ladder, []) do
    new_full_depth_ladder()
  end

  @doc """
  Go over each entry in update and update the ladder accordingly
  """
  def update_full_depth_ladder(ladder, update) do
    Enum.reduce(update, ladder, fn price_size, acc ->
      case price_size do
        [price, 0] -> Map.delete(acc, price)
        [price, size] -> Map.put(acc, price, size)
      end
    end)
  end

  def new_depth_based_ladder(depth \\ @ladder_levels) do
    0..depth - 1 |> Enum.map(&([&1, nil, nil]))
  end

  def update_depth_based_ladder(ladder, nil) do
    ladder
  end

  @doc """
  [0, 1.2, 20] -> Insert / Update level 0 (top of book) with price 1.2 and size 20
  [0, 1.2, 0] -> Remove level 0 (top of book) i.e. ladder is now empty
  """
  def update_depth_based_ladder(ladder, update) do
    Enum.reduce(update, ladder, fn ([idx, price, size] = new, acc) ->
      case size do
        0 -> List.update_at(acc, idx, fn [^idx, price2, _] = value ->
          # Check that the price we are deleting is the same as the price we have inserted,
          # else assume the delition is after update
          case price == price2 or price == 0 do
            true -> [idx, nil, nil]
            false -> Logger.warn("In price update, update came before remove"); value
          end
        end)
        _ -> List.replace_at(acc, idx, new)
      end
    end)
  end

  @doc """
  If side is BACK i have used BATL to place a BACK bet as exit and I want to price one level below
  If side is LAY i have used BATB to place a LAY bet as exit and I want the price one level above
  """
  def find_entry_price(exit_price, side) when side in ["LAY", "BACK"] and exit_price > 1.01 and exit_price < 1001.00 do
    idx = @price_to_idx
    |> Map.get(exit_price / 1) # force a float since map keays are float
    case side do
      "LAY" -> Map.get(@idx_to_price, idx + 1)
      "BACK" -> Map.get(@idx_to_price, idx - 1)
    end
  end
end
