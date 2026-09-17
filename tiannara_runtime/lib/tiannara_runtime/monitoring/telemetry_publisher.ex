defmodule TiannaraRuntime.Monitoring.TelemetryPublisher do
  @moduledoc """
  Periodic telemetry publisher for cold ignition and monitoring.
  """

  use GenServer
  require Logger

  @tick_interval 100

  def start_link(opts \\ []) do
    case GenServer.start_link(__MODULE__, opts, name: __MODULE__) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  def set_passive_mode(enabled) when is_boolean(enabled) do
    if Process.whereis(__MODULE__) do
      GenServer.call(__MODULE__, {:set_passive_mode, enabled})
    else
      {:error, :not_started}
    end
  end

  def passive_mode? do
    if Process.whereis(__MODULE__) do
      GenServer.call(__MODULE__, :passive_mode?)
    else
      false
    end
  end

  def message_count do
    if Process.whereis(__MODULE__) do
      GenServer.call(__MODULE__, :message_count)
    else
      0
    end
  end

  def anomaly_count do
    if Process.whereis(__MODULE__) do
      GenServer.call(__MODULE__, :anomaly_count)
    else
      0
    end
  end

  def get_metrics do
    if Process.whereis(__MODULE__) do
      GenServer.call(__MODULE__, :get_metrics)
    else
      %{}
    end
  end

  def get_history(channel, limit \\ 100) do
    if Process.whereis(__MODULE__) do
      GenServer.call(__MODULE__, {:get_history, channel, limit})
    else
      []
    end
  end

  def reset_perturbation, do: :ok

  @impl true
  def init(_opts) do
    Process.send_after(self(), :tick, @tick_interval)

    {:ok, %{
      tick_interval: @tick_interval,
      passive_mode: false,
      message_count: 0,
      anomaly_count: 0,
      history: %{}
    }}
  end

  @impl true
  def handle_call({:set_passive_mode, enabled}, _from, state) do
    {:reply, :ok, %{state | passive_mode: enabled}}
  end

  @impl true
  def handle_call(:passive_mode?, _from, state) do
    {:reply, state.passive_mode, state}
  end

  @impl true
  def handle_call(:message_count, _from, state) do
    {:reply, state.message_count, state}
  end

  @impl true
  def handle_call(:anomaly_count, _from, state) do
    {:reply, state.anomaly_count, state}
  end

  @impl true
  def handle_call(:get_metrics, _from, state) do
    {:reply, safe_build_metrics(), state}
  end

  @impl true
  def handle_call({:get_history, channel, limit}, _from, state) do
    history = Map.get(state.history, channel, []) |> Enum.take(limit)
    {:reply, history, state}
  end

  @impl true
  def handle_info(:tick, state) do
    metrics = safe_build_metrics()

    new_state =
      Enum.reduce([:grcc, :mscl, :olef, :cis, :ctl], state, fn channel, acc ->
        measurement = Map.fetch!(metrics, channel)
        :telemetry.execute([:tiannara_runtime, :cold_ignition, channel], measurement, %{source: __MODULE__})

        updated_history = Map.update(acc.history, channel, [measurement], fn existing -> [measurement | existing] |> Enum.take(2000) end)

        %{acc | history: updated_history, message_count: acc.message_count + 1}
      end)

    anomaly_count = max(Map.get(metrics, :cis, %{}) |> Map.get(:anomaly_count, 0), new_state.anomaly_count)

    Process.send_after(self(), :tick, state.tick_interval)

    {:noreply, %{new_state | anomaly_count: anomaly_count}}
  end

  defp safe_build_metrics do
    try do
      build_metrics()
    rescue
      exception ->
        Logger.warning("TelemetryPublisher skipping metrics build: #{Exception.message(exception)}")
        empty_metrics()
    catch
      :exit, reason ->
        Logger.warning("TelemetryPublisher skipping metrics build due exit: #{inspect(reason)}")
        empty_metrics()
    end
  end

  defp build_metrics do
    snapshot = Tiannara.UniverseServer.snapshot()

    coherence =
      case snapshot.civ_states do
        civ_states when is_map(civ_states) and map_size(civ_states) > 0 ->
          values = Map.values(civ_states)

          avg =
            Enum.reduce(values, 0.0, fn civ, acc ->
              acc + Map.get(civ, "coherence", 0.0)
            end) / max(length(values), 1)

          avg

        _ ->
          0.0
      end

    pressure_samples =
      case snapshot.olef_field do
        %{pressure: pressure} when is_list(pressure) -> pressure
        %{pressure: pressure} when is_number(pressure) -> [pressure]
        _ -> []
      end

    curvature_samples =
      case snapshot.olef_field do
        %{curvature: curvature} when is_list(curvature) -> curvature
        %{curvature: curvature} when is_number(curvature) -> [curvature]
        _ -> []
      end

    pressure_value = average(pressure_samples)
    curvature_value = average(curvature_samples)
    entropy_value = Map.get(snapshot.olef_field, :entropy, 0.0)

    constraint_load =
      case snapshot.civ_states do
        civ_states when is_map(civ_states) and map_size(civ_states) > 0 ->
          risk_values =
            Enum.map(Map.values(civ_states), fn civ ->
              Map.get(civ, "collapse_risk", 0.0)
            end)

          average(risk_values)

        _ ->
          snapshot.global_entropy
      end

    anomaly_count =
      case snapshot.pending_bursts do
        bursts when is_list(bursts) ->
          length(bursts)

        _ ->
          0
      end

    %{
      grcc: %{
        value: map_size(snapshot.civ_states),
        coherence: coherence,
        entropy: snapshot.global_entropy,
        channel: :grcc,
        timestamp: System.monotonic_time(:millisecond)
      },
      mscl: %{
        value: constraint_load,
        constraint_load: constraint_load,
        divergence_pressure: constraint_load,
        channel: :mscl,
        timestamp: System.monotonic_time(:millisecond)
      },
      olef: %{
        value: pressure_value,
        pressure: pressure_value,
        curvature: curvature_value,
        entropy: entropy_value,
        channel: :olef,
        timestamp: System.monotonic_time(:millisecond)
      },
      cis: %{
        value: anomaly_count,
        anomaly_count: anomaly_count,
        intervention_rate: min(1.0, anomaly_count / max(1, map_size(snapshot.civ_states))),
        channel: :cis,
        timestamp: System.monotonic_time(:millisecond)
      },
      ctl: %{
        value: snapshot.global_entropy,
        drift_velocity: snapshot.global_entropy,
        branch_divergence: coherence,
        channel: :ctl,
        timestamp: System.monotonic_time(:millisecond)
      }
    }
  end

  defp empty_metrics do
    now = System.monotonic_time(:millisecond)

    %{
      grcc: %{value: 0.0, coherence: 0.0, entropy: 0.0, channel: :grcc, timestamp: now},
      mscl: %{value: 0.0, constraint_load: 0.0, divergence_pressure: 0.0, channel: :mscl, timestamp: now},
      olef: %{value: 0.0, pressure: 0.0, curvature: 0.0, entropy: 0.0, channel: :olef, timestamp: now},
      cis: %{value: 0, anomaly_count: 0, intervention_rate: 0.0, channel: :cis, timestamp: now},
      ctl: %{value: 0.0, drift_velocity: 0.0, branch_divergence: 0.0, channel: :ctl, timestamp: now}
    }
  end

  defp average([]), do: 0.0

  defp average(values) when is_list(values) do
    Enum.sum(values) / max(length(values), 1)
  end
end
