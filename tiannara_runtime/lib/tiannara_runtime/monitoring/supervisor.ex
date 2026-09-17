defmodule TiannaraRuntime.Monitoring.Supervisor do
  @moduledoc """
  Supervises runtime monitoring and cold ignition telemetry helpers.
  """

  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {TiannaraRuntime.Monitoring.TelemetryPublisher, []},
      {TiannaraRuntime.Monitoring.Automated24hMonitor, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
