defmodule Tiannara.Constitution.Runtime.Monitor do
  @moduledoc """
  Continuous constitutional monitoring. Periodically re-runs the invariant
  suite and publishes a `:constitutional_concern` epistemic event the moment
  any invariant breaks — wiring the suite into the live Sentinel/Ω.3 pipeline.

  Constitutional basis: "Detect anomalies", "Detect degraded performance",
  "Maintain audit trails", "Capability must never outpace verification."
  """
  use GenServer

  alias Tiannara.Constitution.{Suite, Gate}
  alias Tiannara.Sentinel.EpistemicEvent

  def start_link(opts),
    do: GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name))

  def run_now(server), do: GenServer.call(server, :run_now)
  def last_run(server), do: GenServer.call(server, :last_run)
  def last_verdict(server), do: GenServer.call(server, :last_verdict)

  @impl true
  def init(opts) do
    suite = Keyword.fetch!(opts, :suite)
    interval = Keyword.get(opts, :interval)
    publisher = Keyword.get(opts, :publisher, fn _event -> :ok end)

    if interval, do: Process.send_after(self(), :tick, interval)

    {:ok,
     %{suite: suite, interval: interval, publisher: publisher,
       last_run: nil, last_verdict: nil}}
  end

  @impl true
  def handle_info(:tick, state) do
    run = Suite.run(state.suite)
    verdict = Gate.verdict(run)
    maybe_publish(state.publisher, verdict, run)

    if state.interval, do: Process.send_after(self(), :tick, state.interval)
    {:noreply, %{state | last_run: run, last_verdict: verdict}}
  end

  @impl true
  def handle_call(:run_now, _from, state) do
    run = Suite.run(state.suite)
    verdict = Gate.verdict(run)
    {:reply, run, %{state | last_run: run, last_verdict: verdict}}
  end

  def handle_call(:last_run, _from, state), do: {:reply, state.last_run, state}
  def handle_call(:last_verdict, _from, state), do: {:reply, state.last_verdict, state}

  defp maybe_publish(_publisher, :gate_open, _run), do: :ok

  defp maybe_publish(publisher, {:gate_closed, failed}, run) do
    event =
      EpistemicEvent.new(:constitutional_concern,
        severity: :critical,
        payload: %{failed_invariants: failed},
        evidence: Enum.map(run.results, fn r -> {r.id, r.passed} end),
        confidence: 1.0)

    publisher.(event)
  end
end