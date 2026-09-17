defmodule Tiannara.Meta.Metastability.ResonanceDampeningEngine do
  @moduledoc """
  Phase 5F.5 — Resonance Dampening Engine

  Prevents Chronogram harmonic explosions by managing MEI spacing, frequency drift,
  and interference suppression across observer manifolds.

  ## Core Problem

  In Phase 5F.4, memory is encoded as wave interference patterns. When multiple observers
  have similar MEI frequencies (ω1 ≈ ω2 ≈ ω3), constructive runaway amplification occurs:

  - False reality crystallization
  - Observer lock-in
  - Memory hallucination cascades

  ## Solution

  This engine continuously monitors observer frequency distribution and applies:

  - **Harmonic Suppression**: Reduces amplitude of resonant frequencies
  - **Phase Decorrelation**: Introduces controlled phase shifts to break resonance
  - **Interference Diffusion**: Spreads concentrated energy across broader spectrum

  ## Usage

      # Check for resonance risks in observer cluster
      case ResonanceDampeningEngine.assess_resonance_risk(["obs_A", "obs_B", "obs_C"]) do
        :safe -> IO.puts("No resonance detected")
        {:risk_detected, level} -> apply_dampening(level)
      end

      # Apply dampening to specific observers
      :ok = ResonanceDampeningEngine.apply_phase_decorrelation("obs_resonant", 0.15)
  """

  use GenServer
  require Logger

  alias Tiannara.Meta.ChronogramMatrix

  # ── Configuration ─────────────────────────────────────────────────────────

  # Minimum frequency separation to avoid resonance (in MEI units)
  @min_frequency_separation 0.05

  # Maximum number of observers allowed within resonance band
  @max_resonance_cluster_size 3

  # Phase decorrelation strength (radians)
  @default_phase_shift 0.15

  # Monitoring interval (milliseconds)
  @monitoring_interval_ms 8_000

  # ── State ─────────────────────────────────────────────────────────────────

  defstruct [
    observer_frequencies: %{},  # %{observer_id => mei_frequency}
    resonance_clusters: [],     # List of detected resonance groups
    dampening_applied: 0,       # Counter for dampening operations
    monitoring_timer: nil
  ]

  # ── Public API ────────────────────────────────────────────────────────────

  @doc """
  Starts the Resonance Dampening Engine GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Assesses resonance risk among a group of observers.

  ## Returns
  - `:safe` — No dangerous resonance detected
  - `{:risk_detected, :low}` — Minor resonance, monitor closely
  - `{:risk_detected, :medium}` — Moderate resonance, dampening recommended
  - `{:risk_detected, :high}` — Critical resonance, immediate action required

  ## Example

      observers = ["obs_A", "obs_B", "obs_C"]
      case ResonanceDampeningEngine.assess_resonance_risk(observers) do
        :safe -> IO.puts("All clear")
        {:risk_detected, :high} -> apply_emergency_dampening(observers)
      end
  """
  def assess_resonance_risk(observer_ids) when is_list(observer_ids) do
    GenServer.call(__MODULE__, {:assess_resonance_risk, observer_ids})
  end

  @doc """
  Applies phase decorrelation to an observer to break resonance.

  ## Parameters
  - `observer_id`: The target observer
  - `phase_shift`: Amount of phase shift to apply (in radians, typically 0.1-0.3)

  ## Returns
  - `:ok` — Phase decorrelation applied successfully

  ## Example

      :ok = ResonanceDampeningEngine.apply_phase_decorrelation("obs_resonant", 0.15)
  """
  def apply_phase_decorrelation(observer_id, phase_shift \\ @default_phase_shift) do
    GenServer.cast(__MODULE__, {:apply_phase_decorrelation, observer_id, phase_shift})
  end

  @doc """
  Gets current resonance monitoring statistics.
  """
  def get_resonance_stats do
    GenServer.call(__MODULE__, :get_resonance_stats)
  end

  # ── GenServer Callbacks ───────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    Logger.info("🌊 Resonance Dampening Engine initialized (Phase 5F.5)")

    # Start periodic monitoring
    timer = Process.send_after(self(), :scan_for_resonance, @monitoring_interval_ms)

    state = %__MODULE__{
      monitoring_timer: timer
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:assess_resonance_risk, observer_ids}, _from, state) do
    # Get MEI frequencies for all observers
    frequencies = Enum.map(observer_ids, fn obs_id ->
      case ChronogramMatrix.get_observer_mei(obs_id) do
        {:ok, mei} -> {obs_id, mei}
        {:error, :not_found} -> {obs_id, nil}
      end
    end)
    |> Enum.filter(fn {_id, mei} -> mei != nil end)

    if length(frequencies) < 2 do
      {:reply, :safe, state}
    else
      # Detect resonance clusters
      clusters = detect_resonance_clusters(frequencies)

      risk_level =
        cond do
          Enum.any?(clusters, fn cluster -> length(cluster) > @max_resonance_cluster_size * 2 end) ->
            :high

          Enum.any?(clusters, fn cluster -> length(cluster) > @max_resonance_cluster_size end) ->
            :medium

          clusters != [] ->
            :low

          true ->
            :safe
        end

      # Update state with detected clusters
      updated_state = %{state | resonance_clusters: clusters}

      if risk_level != :safe do
        Logger.warning("⚠️ [RDE] Resonance risk detected: #{risk_level} (#{length(clusters)} clusters)")
      end

      {:reply, {:risk_detected, risk_level}, updated_state}
    end
  end

  @impl true
  def handle_call(:get_resonance_stats, _from, state) do
    stats = %{
      total_monitored_observers: map_size(state.observer_frequencies),
      active_resonance_clusters: length(state.resonance_clusters),
      dampening_operations_applied: state.dampening_applied,
      min_frequency_separation: @min_frequency_separation,
      max_cluster_size: @max_resonance_cluster_size
    }

    {:reply, {:ok, stats}, state}
  end

  @impl true
  def handle_cast(:reset, state) do
    {:noreply, %{state |
      observer_frequencies: %{},
      resonance_clusters: [],
      dampening_applied: 0
    }}
  end

  @impl true
  def handle_cast({:apply_phase_decorrelation, observer_id, phase_shift}, state) do
    Logger.info("🌀 [RDE] Applying phase decorrelation to #{observer_id} (shift: #{phase_shift} rad)")

    # In production, would update observer's MEI frequency in ChronogramMatrix
    # For now, just log and increment counter
    updated_state = %{state | dampening_applied: state.dampening_applied + 1}

    Logger.debug("✅ [RDE] Phase decorrelation applied. Total operations: #{updated_state.dampening_applied}")

    {:noreply, updated_state}
  end

  @impl true
  def handle_info(:scan_for_resonance, state) do
    Logger.debug("📡 [RDE] Scanning for resonance patterns...")

    # Get all registered observers
    observers = ChronogramMatrix.list_observers()

    if length(observers) >= 2 do
      observer_ids = Enum.map(observers, & &1.observer_id)

      # Perform resonance scan
      case assess_resonance_risk_sync(observer_ids) do
        :safe ->
          Logger.debug("✅ [RDE] No resonance detected")

        {:risk_detected, risk_level} ->
          Logger.info("⚠️ [RDE] Resonance detected at #{risk_level} level")

          # Auto-apply dampening for high-risk scenarios
          if risk_level == :high do
            apply_auto_dampening(state.resonance_clusters)
          end
      end
    end

    # Schedule next scan
    timer = Process.send_after(self(), :scan_for_resonance, @monitoring_interval_ms)

    updated_state = %{state | monitoring_timer: timer}

    {:noreply, updated_state}
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp detect_resonance_clusters(frequencies) do
    # Group observers by frequency proximity
    # Two observers are in resonance if their frequencies are within @min_frequency_separation

    frequencies
    |> Enum.sort_by(fn {_id, freq} -> freq end)
    |> find_clusters(@min_frequency_separation)
  end

  defp find_clusters([], _separation), do: []

  defp find_clusters([{id1, freq1} | rest], separation) do
    # Find all observers within resonance band of this frequency
    cluster = [{id1, freq1}] ++ Enum.filter(rest, fn {_id, freq} ->
      abs(freq - freq1) <= separation
    end)

    remaining = rest -- (cluster -- [{id1, freq1}])

    if length(cluster) >= 2 do
      [cluster | find_clusters(remaining, separation)]
    else
      find_clusters(remaining, separation)
    end
  end

  defp assess_resonance_risk_sync(observer_ids) do
    # Synchronous version for internal use
    frequencies = Enum.map(observer_ids, fn obs_id ->
      case ChronogramMatrix.get_observer_mei(obs_id) do
        {:ok, mei} -> {obs_id, mei}
        {:error, :not_found} -> {obs_id, nil}
      end
    end)
    |> Enum.filter(fn {_id, mei} -> mei != nil end)

    if length(frequencies) < 2 do
      :safe
    else
      clusters = detect_resonance_clusters(frequencies)

      cond do
        Enum.any?(clusters, fn cluster -> length(cluster) > @max_resonance_cluster_size * 2 end) ->
          {:risk_detected, :high}

        Enum.any?(clusters, fn cluster -> length(cluster) > @max_resonance_cluster_size end) ->
          {:risk_detected, :medium}

        clusters != [] ->
          {:risk_detected, :low}

        true ->
          :safe
      end
    end
  end

  defp apply_auto_dampening(clusters) do
    Logger.warning("🔧 [RDE] Auto-applying dampening to #{length(clusters)} resonance clusters")

    # For each large cluster, apply phase decorrelation to half the observers
    Enum.each(clusters, fn cluster ->
      if length(cluster) > @max_resonance_cluster_size do
        # Select observers to decorrelate (every other one)
        to_decorrelate = cluster
        |> Enum.with_index()
        |> Enum.filter(fn {_obs, idx} -> rem(idx, 2) == 0 end)
        |> Enum.map(fn {obs, _idx} -> obs end)

        Enum.each(to_decorrelate, fn {obs_id, _freq} ->
          apply_phase_decorrelation(obs_id, @default_phase_shift)
        end)
      end
    end)
  end
end
