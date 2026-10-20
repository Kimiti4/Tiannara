defmodule ColdIgnition.Helpers do
  @moduledoc false

  alias TiannaraRuntime.Monitoring.ColdIgnitionSupport

  def start_system(_context) do
    {:ok, _} = Application.ensure_all_started(:tiannara_runtime)
    TiannaraRuntime.Monitoring.TelemetryPublisher.reset_perturbation()
    :ok
  end

  def start_system_passive_mode(context) do
    start_system(context)
    ColdIgnitionSupport.set_passive_mode(true)

    ExUnit.Callbacks.on_exit(fn ->
      ColdIgnitionSupport.set_passive_mode(false)
    end)

    :ok
  end

  def start_system_active_mode(context) do
    start_system(context)
    ColdIgnitionSupport.set_passive_mode(false)
    :ok
  end

  def start_system_minimal_feedback(context), do: start_system_active_mode(context)

  def capture_system_state, do: ColdIgnitionSupport.capture_system_state()
  def get_telemetry_count, do: ColdIgnitionSupport.telemetry_count()

  def count_telemetry_messages(duration_ms: duration_ms),
    do: ColdIgnitionSupport.count_telemetry_messages(duration_ms)

  def measure_oscillation_amplitude, do: ColdIgnitionSupport.measure_oscillation_amplitude()
end
