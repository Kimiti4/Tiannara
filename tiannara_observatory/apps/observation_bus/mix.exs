defmodule ObservationBus.MixProject do
  use Mix.Project

  def project do
    [
      app: :observation_bus,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {ObservationBus.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:jason, "~> 1.2"},
      {:telemetry, "~> 1.2"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:shared, in_umbrella: true},
      {:observatory_core, in_umbrella: true},
      {:telemetry_gateway, in_umbrella: true},
      {:event_store, in_umbrella: true},
      {:metrics_engine, in_umbrella: true},
      {:replay_store, in_umbrella: true},
      {:observatory_state, in_umbrella: true},
      {:rbac, in_umbrella: true},
      {:stream_data, "~> 1.1", only: [:test, :dev]},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end
end
