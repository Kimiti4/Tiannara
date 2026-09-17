defmodule TelemetryGateway.MixProject do
  use Mix.Project

  def project do
    [
      app: :telemetry_gateway,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [mod: {TelemetryGateway.Application, []}, extra_applications: [:logger]]
  end

  defp deps do
    [
      {:shared, in_umbrella: true},
      {:observatory_core, in_umbrella: true},
      {:event_store, in_umbrella: true},
      {:jason, "~> 1.2"},
      {:gnat, "~> 1.0"}
    ]
  end
end
