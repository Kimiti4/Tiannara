defmodule Tiannara.Ecology do
  @moduledoc """
  Lock-free capability ecology tracker using ETS.
  
  
  Tracks birth/death rates, half-life, and Shannon diversity at civilizational scale
  without creating centralized observer bottlenecks. All worker processes update
  shared ETS tables concurrently via write_concurrency: true.
  
  ## Architecture
  
  - `:eco_lineages` — Tracks active lineage sizes (lineage_id → count)
  - `:eco_births` — Tracks individual capability lifespans (cap_id → {birth_tick, lineage_id}) [DELETED ON DEATH]
  - `:eco_historical_births` — Permanent record of all births for age calculation (cap_id → birth_tick)
  - `:eco_stats` — Aggregated statistics (total births, deaths, lifespan sums)
  
  ## Usage
  
      # From worker processes (capability graph, economic engine):
      Tiannara.Ecology.record_birth(cap_id, lineage_id, tick)
      Tiannara.Ecology.record_death(cap_id, tick)
      Tiannara.Ecology.tick()
      
      # From supervisor (every 5k ticks):
      Tiannara.Ecology.print_ecology_report()
  """

  use GenServer
  require Logger

  # ==================== Public API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Initialize ETS tables for ecology tracking.
  Must be called once at system startup.
  """
  def init_tables do
    # write_concurrency: true allows massive parallel updates from worker processes
    :ets.new(:eco_lineages, [:set, :public, :named_table, write_concurrency: true])
    :ets.new(:eco_births, [:set, :public, :named_table, write_concurrency: true])
    :ets.new(:eco_historical_births, [:set, :public, :named_table, write_concurrency: true])  # Permanent birth log
    :ets.new(:eco_stats, [:set, :public, :named_table])
    
    :ets.insert(:eco_stats, [
      {:total_births, 0},
      {:total_deaths, 0},
      {:lifespan_sum, 0},
      {:lifespan_count, 0},
      {:current_tick, 0},
      {:snapshot_births, 0},
      {:snapshot_deaths, 0},
      {:snapshot_tick, 0},
      # Run 16: Promotion ecology counters
      {:promotion_attempts, 0},
      {:promotion_successes, 0},
      {:promotion_failures, 0}
    ])
    
    Logger.info("🌍 [Ecology] ETS tables initialized for lock-free ecology tracking")
    :ok
  end

  # --- Worker Process API (Called from Capability Graph / Economic Engine) ---

  @doc """
  Record a new capability birth.
  
  Called from worker processes when a new capability node is created.
  Updates lineage size and total birth counter atomically.
  
  ## Parameters
  - `cap_id`: Unique capability identifier
  - `lineage_id`: Lineage this capability belongs to
  - `tick`: Current simulation tick
  """
  @spec record_birth(cap_id :: term(), lineage_id :: term(), tick :: non_neg_integer()) :: :ok
  def record_birth(cap_id, lineage_id, tick) do
    :ets.insert(:eco_births, {cap_id, tick, lineage_id})
    :ets.insert(:eco_historical_births, {cap_id, tick})  # Permanent record for age calculation
    :ets.update_counter(:eco_lineages, lineage_id, {2, 1}, {lineage_id, 0})
    :ets.update_counter(:eco_stats, :total_births, {2, 1}, {:total_births, 0})
  end

  @doc """
  Record a capability death/extinction.
  
  Called from worker processes when a capability is removed.
  Calculates lifespan and updates extinction counters atomically.
  
  ## Parameters
  - `cap_id`: Unique capability identifier
  - `tick`: Current simulation tick
  """
  @spec record_death(cap_id :: term(), tick :: non_neg_integer()) :: :ok
  def record_death(cap_id, tick) do
    case :ets.lookup(:eco_births, cap_id) do
      [{^cap_id, birth_tick, lineage_id}] ->
        :ets.delete(:eco_births, cap_id)
        lifespan = tick - birth_tick
        
        :ets.update_counter(:eco_lineages, lineage_id, {2, -1}, {lineage_id, 0})
        :ets.update_counter(:eco_stats, :total_deaths, {2, 1}, {:total_deaths, 0})
        :ets.update_counter(:eco_stats, :lifespan_sum, {2, lifespan}, {:lifespan_sum, 0})
        :ets.update_counter(:eco_stats, :lifespan_count, {2, 1}, {:lifespan_count, 0})
      _ ->
        :ok  # Capability not tracked (pre-existing or already deleted)
    end
  end

  @doc """
  Increment the global tick counter.
  
  Called once per simulation tick from the main loop.
  """
  @spec tick() :: non_neg_integer()
  def tick do
    :ets.update_counter(:eco_stats, :current_tick, {2, 1}, {:current_tick, 0})
  end

  # --- Promotion Ecology API (Run 16) ---

  @doc """
  Record a promotion attempt for a capability.
  
  Called when a capability is evaluated for promotion to World/Civilization level.
  """
  @spec record_promotion_attempt() :: :ok
  def record_promotion_attempt do
    :ets.update_counter(:eco_stats, :promotion_attempts, {2, 1}, {:promotion_attempts, 0})
  end

  @doc """
  Record a successful promotion.
  
  Called when a capability successfully promotes to higher level.
  """
  @spec record_promotion_success() :: :ok
  def record_promotion_success do
    :ets.update_counter(:eco_stats, :promotion_successes, {2, 1}, {:promotion_successes, 0})
  end

  @doc """
  Record a failed promotion.
  
  Called when a capability fails to promote.
  """
  @spec record_promotion_failure() :: :ok
  def record_promotion_failure do
    :ets.update_counter(:eco_stats, :promotion_failures, {2, 1}, {:promotion_failures, 0})
  end

  # --- Telemetry API (Called by Supervisor every 5k ticks) ---

  @doc """
  Print comprehensive ecology report to console.
  
  Includes birth/death rates, half-life, Shannon diversity, lineage turnover,
  and health assessment indicators.
  """
  @spec print_ecology_report() :: :ok
  def print_ecology_report do
    s = calculate_snapshot()
    
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("🌍 TECHNOLOGICAL ECOLOGY @ Tick #{s.tick}")
    IO.puts(String.duplicate("=", 80))
    
    IO.puts("\n📊 Population Dynamics:")
    IO.puts("   Birth Rate:            #{Float.round(s.birth_rate, 2)} / 1k ticks")
    IO.puts("   Extinction Rate:       #{Float.round(s.death_rate, 2)} / 1k ticks")
    IO.puts("   Net Growth:            #{Float.round(s.birth_rate - s.death_rate, 2)} / 1k ticks")
    
    IO.puts("\n🧬 Evolutionary Health:")
    IO.puts("   Average Half-Life:     #{Float.round(s.half_life, 1)} ticks")
    IO.puts("   Shannon Diversity:     #{Float.round(s.shannon_entropy, 3)}")
    IO.puts("   Lineage Turnover:      #{Float.round(s.lineage_turnover, 3)}")
    
    IO.puts("\n🌐 Ecosystem State:")
    IO.puts("   Total Active Species:  #{s.total_active}")
    IO.puts("   Extinct Species:       #{s.total_extinct}")
    IO.puts("   Survival Rate:         #{Float.round(s.survival_rate, 1)}%")
    
    # Run 16: Age Distribution
    IO.puts("\n⏳ Age Distribution:")
    Enum.each(s.age_distribution, fn {age_range, count} ->
      pct = if s.total_active > 0, do: count / s.total_active * 100, else: 0.0
      IO.puts("   #{String.pad_trailing(age_range, 15)} #{String.pad_leading(Integer.to_string(count), 8)}  (#{Float.round(pct, 1)}%)")
    end)
    
    # Run 16: Lifecycle Invariant Check
    expected_alive = s.tick_data[:expected_alive] || 0
    actual_eco_births = s.tick_data[:actual_eco_births] || 0
    invariant_violation = s.tick_data[:invariant_violation] || 0
    age_stats = s.tick_data[:age_stats] || %{oldest: 0, youngest: 0, median: 0, p95: 0}
    
    IO.puts("\n🔍 Lifecycle Accounting:")
    IO.puts("   Historical Births:     #{expected_alive + (s.tick_data[:total_deaths] || 0)}")
    IO.puts("   Historical Deaths:     #{s.tick_data[:total_deaths] || 0}")
    IO.puts("   Expected Alive (B-D):  #{expected_alive}")
    IO.puts("   Actual ETS Entries:    #{actual_eco_births}")
    if invariant_violation > 0 do
      IO.puts("   ⚠️  INVARIANT VIOLATION: #{invariant_violation} capabilities unaccounted")
    else
      IO.puts("   ✅ Lifecycle accounting consistent")
    end
    
    # Run 16: Age Statistics
    IO.puts("\n📊 Capability Ages:")
    IO.puts("   Oldest:                #{age_stats.oldest} ticks")
    IO.puts("   Median:                #{age_stats.median} ticks")
    IO.puts("   95th Percentile:       #{age_stats.p95} ticks")
    IO.puts("   Youngest:              #{age_stats.youngest} ticks")
    
    # Health Assessment
    IO.puts("\n🎯 Technology Health:")
    cond do
      s.half_life < 1000 ->
        IO.puts("   ⚠️  Chaotic Ecosystem (Half-life < 1k ticks)")
        IO.puts("   → Excessive churn, technologies don't persist")
      s.half_life > 50000 ->
        IO.puts("   ⚠️  Technological Stagnation (Half-life > 50k ticks)")
        IO.puts("   → Technologies persist too long, low innovation")
      s.shannon_entropy < 1.5 ->
        IO.puts("   ⚠️  Low Diversity (Shannon < 1.5)")
        IO.puts("   → Risk of monoculture, limited technological variety")
      s.lineage_turnover < 0.05 ->
        IO.puts("   ⚠️  Lineage Stagnation (Turnover < 5%)")
        IO.puts("   → Little replacement of old lineages")
      s.lineage_turnover > 0.5 ->
        IO.puts("   ⚠️  Excessive Turnover (> 50%)")
        IO.puts("   → Unstable ecosystem, high extinction pressure")
      true ->
        IO.puts("   ✅ Stable ecosystem with healthy turnover")
        IO.puts("   ✅ High lineage diversity maintained")
        IO.puts("   ✅ Competitive replacement occurring")
    end
    
    IO.puts("\n" <> String.duplicate("=", 80) <> "\n")
  end

  # --- Internal Calculations ---

  defp calculate_snapshot do
    [{:total_births, tb}] = :ets.lookup(:eco_stats, :total_births)
    [{:total_deaths, td}] = :ets.lookup(:eco_stats, :total_deaths)
    [{:lifespan_sum, ls}] = :ets.lookup(:eco_stats, :lifespan_sum)
    [{:lifespan_count, lc}] = :ets.lookup(:eco_stats, :lifespan_count)
    [{:current_tick, ct}] = :ets.lookup(:eco_stats, :current_tick)
    
    [{:snapshot_births, pb}] = :ets.lookup(:eco_stats, :snapshot_births)
    [{:snapshot_deaths, pd}] = :ets.lookup(:eco_stats, :snapshot_deaths)
    [{:snapshot_tick, pt}] = :ets.lookup(:eco_stats, :snapshot_tick)

    tick_delta = max(ct - pt, 1)
    birth_rate = (tb - pb) / tick_delta * 1000
    death_rate = (td - pd) / tick_delta * 1000
    half_life = if lc > 0, do: ls / lc, else: 0.0
    survival_rate = if tb > 0, do: (tb - td) / tb * 100, else: 0.0

    # Shannon Entropy of lineage distribution
    entropy = calculate_shannon_entropy()

    # Lineage Turnover
    all_lineages = :ets.match(:eco_lineages, [:'$1', :'$2'])
    total_lc = length(all_lineages)
    extinct_lc = Enum.count(all_lineages, fn [_id, count] -> count == 0 end)
    turnover = if total_lc > 0, do: extinct_lc / total_lc, else: 0.0

    # Run 16: Age Distribution of active capabilities
    {age_distribution, age_stats} = calculate_age_distribution(ct)
    
    # Run 16: Lifecycle Invariant Check (Births - Deaths = Alive)
    expected_alive = tb - td
    actual_eco_births = :ets.info(:eco_births, :size)  # Currently alive (deleted on death)
    _historical_births = :ets.info(:eco_historical_births, :size)  # All-time births
    invariant_violation = abs(expected_alive - actual_eco_births)

    # Update baseline for next window
    :ets.insert(:eco_stats, [
      {:snapshot_births, tb},
      {:snapshot_deaths, td},
      {:snapshot_tick, ct}
    ])

    %{
      tick: ct,
      birth_rate: birth_rate,
      death_rate: death_rate,
      half_life: half_life,
      shannon_entropy: entropy,
      lineage_turnover: turnover,
      survival_rate: survival_rate,
      total_active: tb - td,
      total_extinct: td,
      age_distribution: age_distribution,
      # Run 16: Lifecycle invariant data for reporting
      tick_data: %{
        expected_alive: expected_alive,
        actual_eco_births: actual_eco_births,
        invariant_violation: invariant_violation,
        total_deaths: td,
        age_stats: age_stats
      }
    }
  end

  defp calculate_shannon_entropy do
    counts = :ets.match(:eco_lineages, [:'$1', :'$2'])
    |> Enum.map(fn [_id, count] -> count end)
    |> Enum.filter(&(&1 > 0))
    
    total = Enum.sum(counts)
    if total == 0 do
      0.0
    else
      counts
      |> Enum.map(fn c ->
        p = c / total
        -p * :math.log2(p)
      end)
      |> Enum.sum()
    end
  end

  # Run 16: Calculate age distribution of active capabilities
  defp calculate_age_distribution(current_tick) do
    # Use historical births table (permanent record, not deleted on death)
    all_births = :ets.match(:eco_historical_births, [:'$1', :'$2'])
    
    age_buckets = Enum.reduce(all_births, %{"Young (0-5k)" => 0, "Maturing (5k-15k)" => 0, "Established (15k-50k)" => 0, "Legacy (50k+)" => 0}, fn [_cap_id, birth_tick, _lineage_id], acc ->
      age = current_tick - birth_tick
      cond do
        age <= 5_000 -> Map.update!(acc, "Young (0-5k)", &(&1 + 1))
        age <= 15_000 -> Map.update!(acc, "Maturing (5k-15k)", &(&1 + 1))
        age <= 50_000 -> Map.update!(acc, "Established (15k-50k)", &(&1 + 1))
        true -> Map.update!(acc, "Legacy (50k+)", &(&1 + 1))
      end
    end)
    
    # Also calculate age statistics for diagnostics
    ages = Enum.map(all_births, fn [_cap_id, birth_tick] -> current_tick - birth_tick end)
    age_stats = if length(ages) > 0 do
      sorted = Enum.sort(ages)
      oldest = List.last(sorted)
      youngest = hd(sorted)
      median_idx = div(length(sorted), 2)
      median = Enum.at(sorted, median_idx)
      p95_idx = round(length(sorted) * 0.95)
      p95 = Enum.at(sorted, min(p95_idx, length(sorted) - 1))
      %{oldest: oldest, youngest: youngest, median: median, p95: p95}
    else
      %{oldest: 0, youngest: 0, median: 0, p95: 0}
    end
    
    {age_buckets, age_stats}
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    init_tables()
    {:ok, %{}}
  end

  @impl true
  def handle_call(:get_snapshot, _from, state) do
    {:reply, {:ok, calculate_snapshot()}, state}
  end

  @impl true
  def handle_cast(:print_report, state) do
    print_ecology_report()
    {:noreply, state}
  end
end
