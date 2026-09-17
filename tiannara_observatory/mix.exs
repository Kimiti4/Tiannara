defmodule TiannaraObservatory.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      apps: [
        :shared,
        :observatory_core,
        :telemetry_gateway,
        :event_store,
        :metrics_engine,
        :replay_store,
        :observatory_state,
        :observatory_api,
        :rbac,
        :observation_bus
      ],
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp deps do
    []
  end
end
