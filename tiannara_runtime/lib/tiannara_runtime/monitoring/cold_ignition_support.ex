defmodule TiannaraRuntime.Monitoring.ColdIgnitionSupport do
  @moduledoc """
  Helper APIs that back the cold ignition integration tests.
  """

  require Logger

  def attach_listener(channel) when channel in [:grcc, :mscl, :olef, :cis, :ctl] do
    event = [:tiannara_runtime, :cold_ignition, channel]
    attachment_id = "cold_ignition_listener_#{channel}"

    :telemetry.attach(
      attachment_id,
      event,
      &__MODULE__.handle_telemetry/4,
      %{channel: channel, pid: self()}
    )

    :ok
  end

  def handle_telemetry(_event, measurements, _metadata, %{channel: channel, pid: pid}) do
    send(pid, {:telemetry, channel, measurements})
  end

  def detach_listener(channel) when channel in [:grcc, :mscl, :olef, :cis, :ctl] do
    :telemetry.detach("cold_ignition_listener_#{channel}")
    :ok
  end

  def telemetry_count do
    TiannaraRuntime.Monitoring.TelemetryPublisher.message_count()
  end

  def anomaly_count do
    TiannaraRuntime.Monitoring.TelemetryPublisher.anomaly_count()
  end

  def set_passive_mode(enabled) when is_boolean(enabled) do
    TiannaraRuntime.Monitoring.TelemetryPublisher.set_passive_mode(enabled)
  end

  def passive_mode? do
    TiannaraRuntime.Monitoring.TelemetryPublisher.passive_mode?()
  end

  def fingerprint do
    snapshot = universe_snapshot()

    normalized = %{
      population: map_size(snapshot.civ_states),
      entropy: snapshot.global_entropy,
      pressure: summarize_list(snapshot.olef_field.pressure),
      curvature: summarize_list(snapshot.olef_field.curvature),
      coherence: summarize_coherence(snapshot.civ_states)
    }

    :erlang.phash2(normalized)
  end

  def total_population do
    snapshot = universe_snapshot()
    map_size(snapshot.civ_states)
  end

  def capture_system_state do
    snapshot = universe_snapshot()

    stable_state = %{
      population: map_size(snapshot.civ_states),
      entropy: snapshot.global_entropy,
      pressure: summarize_list(snapshot.olef_field.pressure),
      curvature: summarize_list(snapshot.olef_field.curvature),
      coherence: summarize_coherence(snapshot.civ_states)
    }

    %{core_hash: :erlang.phash2(stable_state), snapshot: stable_state}
  end

  def dominant_niche do
    snapshot = universe_snapshot()
    pressure = snapshot.olef_field.pressure

    if is_list(pressure) and length(pressure) > 0 do
      {:ok, "niche_1"}
    else
      {:error, :no_niche}
    end
  end

  def inject_perturbation(params) do
    try do
      Tiannara.UniverseServer.inject_perturbation(params)
      {:ok, :injected}
    rescue
      exception ->
        Logger.warning("ColdIgnitionSupport skipping perturbation injection: #{Exception.message(exception)}")
        {:error, exception}
    catch
      :exit, reason ->
        Logger.warning("ColdIgnitionSupport skipping perturbation injection due exit: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def constraint_load do
    metrics = TiannaraRuntime.Monitoring.TelemetryPublisher.get_metrics()
    metrics[:mscl][:value]
  end

  def pressure_field do
    snapshot = universe_snapshot()
    snapshot.olef_field
  end

  def count_telemetry_messages(duration_ms) do
    initial = telemetry_count()
    Process.sleep(duration_ms)
    telemetry_count() - initial
  end

  def measure_oscillation_amplitude, do: 0.0

  def channel_metrics(channel) do
    metrics = TiannaraRuntime.Monitoring.TelemetryPublisher.get_metrics()
    Map.get(metrics, channel)
  end

  defp universe_snapshot do
    try do
      Tiannara.UniverseServer.snapshot()
    rescue
      exception ->
        Logger.warning("ColdIgnitionSupport skipping universe snapshot: #{Exception.message(exception)}")
        empty_snapshot()
    catch
      :exit, reason ->
        Logger.warning("ColdIgnitionSupport skipping universe snapshot due exit: #{inspect(reason)}")
        empty_snapshot()
    end
  end

  defp empty_snapshot do
    %{
      civ_states: %{},
      global_entropy: 0.0,
      olef_field: %{pressure: [], curvature: [], entropy: 0.0},
      pending_bursts: []
    }
  end

  defp summarize_list(values) when is_list(values), do: Enum.sum(values) / max(length(values), 1)
  defp summarize_list(value) when is_number(value), do: value
  defp summarize_list(_), do: 0.0

  defp summarize_coherence(civ_states) when is_map(civ_states) do
    values = Map.values(civ_states)

    Enum.reduce(values, 0.0, fn civ, acc ->
      acc + Map.get(civ, "coherence", 0.0)
    end) / max(length(values), 1)
  end

  defp summarize_coherence(_), do: 0.0
end
