defmodule Tiannara.RSME.Supervisor do
  use GenServer
  require Logger

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def init(_) do
    {:ok, %{
      runtime_snapshots: [],
      trajectory_predictions: [],
      bottleneck_detections: [],
      config: %{snapshot_interval_ms: 5000, prediction_window: 100, bottleneck_threshold: 0.7}
    }}
  end

  def capture_runtime_snapshot(metrics) do
    GenServer.cast(__MODULE__, {:snapshot, metrics})
  end

  def predict_collapse_risk do
    GenServer.call(__MODULE__, :predict_risk)
  end

  def detect_bottlenecks do
    GenServer.call(__MODULE__, :detect_bottlenecks)
  end

  def handle_cast({:snapshot, metrics}, state) do
    snapshot = %{timestamp: System.monotonic_time(:millisecond), metrics: metrics}
    new_snapshots = [snapshot | Enum.take(state.runtime_snapshots, 999)]
    {:noreply, %{state | runtime_snapshots: new_snapshots}}
  end

  def handle_call(:predict_risk, _from, state) do
    if Enum.empty?(state.runtime_snapshots) do
      {:reply, {:ok, %{collapse_risk: 0.0, severity: :low}}, state}
    else
      stability = state.runtime_snapshots |> Enum.map(fn s -> Map.get(s.metrics, :stability, 0.5) end) |> Enum.at(0, 0.5)
      risk = max(0.0, 1.0 - stability)
      result = %{collapse_risk: risk, severity: if(risk > 0.7, do: :high, else: :low)}
      {:reply, {:ok, result}, state}
    end
  end

  def handle_call(:detect_bottlenecks, _from, state) do
    {:reply, {:ok, []}, state}
  end
end
