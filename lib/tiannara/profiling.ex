defmodule Tiannara.Profiling do
  @moduledoc """
  Lock-free telemetry aggregator using ETS.
  
  Aggregates timing data from worker processes without creating centralized
  bottlenecks. Uses :telemetry events and ETS counters with write_concurrency: true
  to allow thousands of BEAM processes to update profiling data concurrently.
  
  ## Architecture
  
  - `:profiler_stats` — Stores accumulated durations and call counts per phase
  - Attaches to `[:tiannara, :profile, :phase]` telemetry events
  - Worker processes call `profile/2` to wrap timed operations
  - Supervisor calls report functions to print breakdowns
  
  ## Usage
  
      # From worker processes:
      result = Tiannara.Profiling.profile(:portfolio_valuation, fn ->
        valuate_all_portfolios(state)
      end)
      
      # From supervisor (every 5k ticks):
      Tiannara.Profiling.print_economic_profile()
      
      # From supervisor (every 10k ticks):
      Tiannara.Profiling.print_registration_profile()
  """

  use GenServer
  require Logger

  # ==================== Public API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Initialize ETS table and attach telemetry handlers.
  Must be called once at system startup.
  """
  def init_profiler do
    :ets.new(:profiler_stats, [:set, :public, :named_table, write_concurrency: true])
    
    # Attach to all telemetry events starting with [:tiannara, :profile]
    :telemetry.attach(
      "tiannara-profiler",
      [:tiannara, :profile, :_],
      &handle_event/4,
      nil
    )
    
    Logger.info("📊 [Profiling] ETS profiler initialized with telemetry attachment")
    :ok
  end

  @doc """
  Profile a function execution and emit telemetry event.
  
  Wraps the given function with timing instrumentation and automatically
  emits a telemetry event with the duration.
  
  ## Parameters
  - `phase`: Atom identifying the profiling phase (e.g., :mutation, :synthesis)
  - `fun`: Zero-arity function to execute and time
  
  ## Returns
  The result of executing `fun.()`
  
  ## Example
  
      portfolio_val = Tiannara.Profiling.profile(:portfolio_valuation, fn ->
        valuate_all_portfolios(economic_state)
      end)
  """
  @spec profile(phase :: atom(), fun :: function()) :: term()
  def profile(phase, fun) when is_function(fun, 0) do
    start = System.monotonic_time(:microsecond)
    result = fun.()
    duration = System.monotonic_time(:microsecond) - start
    
    :telemetry.execute([:tiannara, :profile, phase], %{duration: duration}, %{})
    result
  end

  # --- Telemetry Handler ---

  @doc false
  def handle_event([:tiannara, :profile, phase], %{duration: duration}, _metadata, _config) do
    # Lock-free accumulation in ETS
    :ets.update_counter(:profiler_stats, {phase, :duration}, {2, duration}, {{phase, :duration}, 0})
    :ets.update_counter(:profiler_stats, {phase, :count}, {2, 1}, {{phase, :count}, 0})
  end

  # --- Reporting API ---

  @doc """
  Print economic sub-profiling breakdown.
  
  Shows percentage breakdown of:
  - Portfolio Valuation
  - Resource Allocation
  - Need Matching
  - Mortality Selection
  - Capacity Calculation
  
  Call every 5,000 ticks.
  """
  @spec print_economic_profile() :: :ok
  def print_economic_profile do
    phases = [
      :portfolio_valuation,
      :resource_allocation,
      :need_matching,
      :mortality_selection,
      :capacity_calculation
    ]
    print_report("Economic Profile", phases)
  end

  @doc """
  Print registration pipeline profiling breakdown.
  
  Shows percentage breakdown of:
  - Mutation
  - Synthesis
  - Node Creation
  - Fitness Updates
  - Dependency Linking
  
  Call every 10,000 ticks.
  """
  @spec print_registration_profile() :: :ok
  def print_registration_profile do
    phases = [
      :mutation,
      :synthesis,
      :node_creation,
      :fitness_updates,
      :dependency_linking
    ]
    print_report("Registration Profile", phases)
  end

  defp print_report(title, phases) do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("📊 #{title}")
    IO.puts(String.duplicate("=", 80))
    
    durations = :ets.match(:profiler_stats, [{{:'$1', :duration}, :'$2'}])
    |> Map.new(fn [p, d] -> {p, d} end)
    
    counts = :ets.match(:profiler_stats, [{{:'$1', :count}, :'$2'}])
    |> Map.new(fn [p, c] -> {p, c} end)
    
    total_time_ms = Enum.reduce(phases, 0, fn p, acc ->
      acc + Map.get(durations, p, 0)
    end) / 1000
    
    if total_time_ms == 0 do
      IO.puts("   No profiling data collected yet")
    else
      # Sort phases by duration (descending) to identify bottleneck
      sorted_phases = Enum.sort_by(phases, fn p -> Map.get(durations, p, 0) end, :desc)
      dominant_phase = hd(sorted_phases)
      
      Enum.each(phases, fn phase ->
        dur_us = Map.get(durations, phase, 0)
        dur_ms = dur_us / 1000
        count = Map.get(counts, phase, 0)
        pct = if total_time_ms > 0, do: dur_ms / total_time_ms * 100, else: 0
        
        formatted = phase
        |> Atom.to_string()
        |> String.split("_")
        |> Enum.map(&String.capitalize/1)
        |> Enum.join(" ")
        
        marker = if phase == dominant_phase, do: " ← DOMINANT", else: ""
        IO.puts("   #{String.pad_trailing(formatted, 25)} #{String.pad_leading(Float.round(pct, 1), 5)}%  (#{Float.round(dur_ms, 2)}ms / #{count} calls)#{marker}")
      end)
      
      IO.puts("\n   Total Time: #{Float.round(total_time_ms, 2)}ms")
      IO.puts("   Dominant Bottleneck: #{Atom.to_string(dominant_phase) |> String.replace("_", " ") |> String.capitalize()}")
    end
    
    # Reset window for next reporting period
    :ets.delete_all_objects(:profiler_stats)
    
    IO.puts(String.duplicate("=", 80) <> "\n")
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    init_profiler()
    {:ok, %{}}
  end

  @impl true
  def handle_call(:get_economic_profile, _from, state) do
    phases = [:portfolio_valuation, :resource_allocation, :need_matching, :mortality_selection, :capacity_calculation]
    profile_data = collect_profile_data(phases)
    {:reply, {:ok, profile_data}, state}
  end

  @impl true
  def handle_call(:get_registration_profile, _from, state) do
    phases = [:mutation, :synthesis, :node_creation, :fitness_updates, :dependency_linking]
    profile_data = collect_profile_data(phases)
    {:reply, {:ok, profile_data}, state}
  end

  defp collect_profile_data(phases) do
    durations = :ets.match(:profiler_stats, [{{:'$1', :duration}, :'$2'}])
    |> Map.new(fn [p, d] -> {p, d} end)
    
    counts = :ets.match(:profiler_stats, [{{:'$1', :count}, :'$2'}])
    |> Map.new(fn [p, c] -> {p, c} end)
    
    Enum.map(phases, fn phase ->
      %{
        phase: phase,
        duration_us: Map.get(durations, phase, 0),
        duration_ms: Map.get(durations, phase, 0) / 1000,
        count: Map.get(counts, phase, 0)
      }
    end)
  end
end
