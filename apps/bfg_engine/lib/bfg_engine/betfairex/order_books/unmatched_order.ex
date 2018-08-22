defmodule BfgEngine.Betfairex.OrderBooks.UnmatchedOrder do
  def new(unmatched_order) do
    %{
      bet_id: unmatched_order[:id],
      price: unmatched_order[:p],
      size: unmatched_order[:s],
      bsp_liability: unmatched_order[:bsp],
      side: unmatched_order[:side],
      status: unmatched_order[:status],
      persistence_type: unmatched_order[:pt],
      order_type: unmatched_order[:ot],
      placed_date: if unmatched_order[:pd] do Timex.from_unix(unmatched_order[:pd], :milliseconds) end,
      matched_date: if unmatched_order[:md] do Timex.from_unix(unmatched_order[:md], :milliseconds) end,
      lapsed_date: if unmatched_order[:ld] do Timex.from_unix(unmatched_order[:ld], :milliseconds) end,
      average_price_matched: unmatched_order[:avp],
      size_matched: unmatched_order[:sm],
      size_remaining: unmatched_order[:sr],
      size_lapsed: unmatched_order[:sl],
      size_cancelled: unmatched_order[:sc],
      size_voided: unmatched_order[:sv],
      regulator_auth_code: unmatched_order[:rac],
      regulator_code: unmatched_order[:rc],
      reference_order: unmatched_order[:rfo],
      reference_strategy: unmatched_order[:rfs]
    }
  end

  def update(_order, update) do
    new(update)
  end
end
