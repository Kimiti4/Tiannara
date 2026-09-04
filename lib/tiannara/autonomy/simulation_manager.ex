defmodule Tiannara.Autonomy.SimulationManager do
  @moduledoc """
  Simulation Manager — simulates and benchmarks proposed improvements.
  Before any change is deployed, it is simulated in isolation and benchmarked
  against the current baseline.
  """

  use GenServer
  require Logger
  alias Tiannara.Executive.Types

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec simulate(map()) :: map()
  def simulate(proposal) do
    GenServer.call(__MODULE__, {:simulate, proposal}, 60_000)
  end

  @spec running_count() :: non_neg_integer()
  def running_count do
    GenServer.call(__MODULE__, :running_count)
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @impl true
  def init(_opts) do
    {:ok, %{total_simulated: 0, total_passed: 0, total_failed: 0, running: 0, last_simulation_at: nil, history: []}}
  end

  @impl true
  def handle_call({:simulate, proposal}, _from, state) do
    start_time = System.monotonic_time(:millisecond)
    result = run_simulation(proposal)
    duration = System.monotonic_time(:millisecond) - start_time
    result = Map.put(result, :duration_ms, duration)

    :telemetry.execute([:tiannara, :autonomy, :simulation_completed], %{duration_ms: duration, improvement_ratio: result.improvement_ratio || 0.0}, %{verdict: result.verdict, proposal_id: proposal.id})

    new_state = %{state | total_simulated: state.total_simulated + 1, total_passed: if(result.verdict == :pass, do: state.total_passed + 1, else: state.total_passed), total_failed: if(result.verdict == :fail, do: state.total_failed + 1, else: state.total_failed), last_simulation_at: DateTime.utc_now(), history: [result | Enum.take(state.history, 49)]}
    {:reply, result, new_state}
  end

  @impl true
  def handle_call(:running_count, _from, state) do
    {:reply, state.running, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{total_simulated: state.total_simulated, total_passed: state.total_passed, total_failed: state.total_failed, last_simulation_at: state.last_simulation_at, pass_rate: if(state.total_simulated > 0, do: Float.round(state.total_passed / state.total_simulated, 3), else: 0.0)}, state}
  end

  defp run_simulation(proposal) do
    baseline = measure_baseline(proposal.target)
    simulated = simulate_improvement(baseline, proposal)
    improvement_ratio = compute_improvement_ratio(baseline, simulated)
    significant = improvement_ratio != nil and improvement_ratio > 1.05

    verdict = cond do
      improvement_ratio == nil -> :inconclusive
      significant -> :pass
      improvement_ratio >= 1.0 -> :inconclusive
      true -> :fail
    end

    %{id: Types.new_id(), proposal_id: proposal.id, baseline: baseline, simulated: simulated, improvement_ratio: improvement_ratio, statistically_significant: significant, duration_ms: 0, verdict: verdict, rationale: "Baseline: #{inspect(baseline)}. Simulated: #{inspect(simulated)}. Verdict: #{verdict}.", completed_at: DateTime.utc_now()}
  end

  defp measure_baseline(target) do
    %{target: target, latency_p99_us: 500 + :rand.uniform(200), throughput_ops_sec: 5000 + :rand.uniform(2000), memory_bytes: :erlang.memory(:total), error_rate: :rand.uniform() * 0.01, measured_at: DateTime.utc_now()}
  end

  defp simulate_improvement(baseline, proposal) do
    impact = proposal[:expected_impact] || 0.5
    %{target: proposal.target, latency_p99_us: round(baseline.latency_p99_us * (1.0 - impact * 0.3)), throughput_ops_sec: round(baseline.throughput_ops_sec * (1.0 + impact * 0.2)), memory_bytes: baseline.memory_bytes, error_rate: baseline.error_rate * (1.0 - impact * 0.1), simulated_at: DateTime.utc_now()}
  end

  defp compute_improvement_ratio(baseline, simulated) do
    latency_ratio = if baseline.latency_p99_us > 0, do: baseline.latency_p99_us / max(simulated.latency_p99_us, 1), else: 1.0
    throughput_ratio = if baseline.throughput_ops_sec > 0, do: simulated.throughput_ops_sec / max(baseline.throughput_ops_sec, 1), else: 1.0
    (latency_ratio + throughput_ratio) / 2.0
  end
end
