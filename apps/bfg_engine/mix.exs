defmodule BfgEngine.MixProject do
  use Mix.Project

  def project do
    [
      app: :bfg_engine,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :runtime_tools, :ssl],
      mod: {BfgEngine.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:connection, "~> 1.0.4"},
      {:httpoison, "~> 1.0"},
      {:poison, "~> 3.1"},
      {:timex, "~> 3.1"},
      {:hub, "~> 0.6"},
      {:postgrex, ">= 0.0.0"},
      {:ecto, "~> 2.1"},
      {:prometheus_ex, "~> 3.0"},
      {:bypass, github: "hassox/bypass", ref: "a8d8eeb49e4a52a96e8b1028afe6af483dd07602", only: :test},
      # {:credo, "~> 0.10.0", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 0.6", only: :dev, runtime: false}
    ]
  end
end
