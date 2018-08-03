defmodule BfgEngine.TestInstumenter do

  use Prometheus.Metric

  @counter [name: :my_service_user_signups_total,
            help: "User signups count.",
            labels: [:country],
            registry: :all]

  def inc(country) do
    Counter.inc([name: :my_service_user_signups_total,
                labels: [country],
                registry: :all])
  end

end
