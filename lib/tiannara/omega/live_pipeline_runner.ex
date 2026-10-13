defmodule Tiannara.Omega.LivePipelineRunner do
  @moduledoc """
  Supervised runner for the Ω closed-loop live pipeline
  (`Tiannara.Omega.LivePipeline`). Periodically runs one cycle against live
  BEAM-runtime telemetry, records the verdict, and keeps the most recent
  cycle for inspection. This is what makes the documented "live telemetry →
  observation → anomaly → investigation → certification" loop actually run
  in production instead of existing only as a test-called pure function
  (doc-vs-reality audit finding, spec.md #4).

  CI validation is attempted only when a correlation-aware provider is
  configured via `:ci_provider`/`:ci_config`; otherwise cycles complete with
  verdict `:investigation_complete_no_ci` — fail-honest, not fail-silent.

  Constitutional basis: Verification First, "Maintain audit trails",
  augmentation clause (observe/investigate/certify — never deploy).
  """

  use GenServer
  require Logger

  alias Tiannara.Omega.LivePipeline

  @default_interval_ms 60_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Most recent completed cycle (struct or `nil` before the first tick)."
  def last_cycle do
    GenServer.call(__MODULE__, :last_cycle)
  end

  @doc "Cycle count completed since boot."
  def cycle_count do
    GenServer.call(__MODULE__, :cycle_count)
  end

  @impl true
  def init(opts) do
    interval = Keyword.get(opts, :interval_ms, @default_interval_ms)
    state = %{opts: opts, interval: interval, last_cycle: nil, cycles: 0}
    schedule_tick(interval)
    {:ok, state}
  end

  @impl true
  def handle_call(:last_cycle, _from, state), do: {:reply, state.last_cycle, state}
  def handle_call(:cycle_count, _from, state), do: {:reply, state.cycles, state}

  @impl true
  def handle_info(:tick, state) do
    result =
      try do
        LivePipeline.run_cycle(state.opts)
      rescue
        e ->
          Logger.warning("[LivePipelineRunner] cycle failed: #{Exception.message(e)}")
          nil
      end

    if result do
      Logger.info("[LivePipelineRunner] cycle #{state.cycles + 1} verdict=#{result.verdict}")
    end

    schedule_tick(state.interval)
    {:noreply, %{state | last_cycle: result, cycles: state.cycles + 1}}
  end

  defp schedule_tick(interval), do: Process.send_after(self(), :tick, interval)
end
