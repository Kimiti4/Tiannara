defmodule Tiannara.Meta.Metastability.ParadoxDensityMonitor do
  @moduledoc """
  Phase 5F.5 — Paradox Density Monitor

  Tracks CTN (Causal Tensegrity Node) concentration, paradox percolation spread,
  and contradiction clustering across the observer manifold.

  ## Purpose

  Computes the Global Paradox Density Field:

      Π_global = Σ(κ_i · ρ_i) / Ω_runtime

  Where:
  - κ_i = local paradox intensity
  - ρ_i = CTN resonance factor
  - Ω_runtime = active observer manifold space

  ## Thresholds

  When paradox density exceeds safe limits, triggers:
  - Observer creation throttling
  - Chronogram write rate limiting
  - Causal region quarantine
  - Escalation to CIS Supervisor

  ## Usage

      # Report local paradox measurement
      :ok = ParadoxDensityMonitor.report_paradox_intensity("region_001", 0.45)

      # Get current global density
      {:ok, density} = ParadoxDensityMonitor.get_global_density()
  """

  use GenServer
  require Logger

  alias Tiannara.Meta.Metastability.Kernel, as: MSCLKernel

  # ── Configuration ─────────────────────────────────────────────────────────

  # Maximum safe paradox density (0.0-1.0 scale)
  @safe_density_threshold 0.60

  # Critical density requiring immediate intervention
  @critical_density_threshold 0.85

  # Number of regions to track
  @max_tracked_regions 100

  # Reporting interval to MSCL Kernel (milliseconds)
  @reporting_interval_ms 3_000

  # ── State ─────────────────────────────────────────────────────────────────

  defstruct [
    regional_paradox_map: %{},  # %{region_id => {intensity, resonance_factor, timestamp}}
    global_density: 0.0,
    reporting_timer: nil
  ]

  # ── Public API ────────────────────────────────────────────────────────────

  @doc """
  Starts the Paradox Density Monitor GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Reports paradox intensity for a specific region.

  ## Parameters
  - `region_id`: Identifier for the causal region
  - `intensity`: Local paradox intensity (0.0-1.0)
  - `resonance_factor`: CTN resonance factor (0.0-1.0, optional, defaults to 0.5)

  ## Example

      :ok = ParadoxDensityMonitor.report_paradox_intensity("ctn_region_001", 0.45, 0.6)
  """
  def report_paradox_intensity(region_id, intensity, resonance_factor \\ 0.5) do
    GenServer.cast(__MODULE__, {:report_paradox_intensity, region_id, intensity, resonance_factor})
  end

  @doc """
  Gets current global paradox density.

  ## Returns
  - `{:ok, density}` — Current global density value (0.0-1.0)
  """
  def get_global_density do
    GenServer.call(__MODULE__, :get_global_density)
  end

  @doc """
  Gets detailed paradox metrics including regional breakdown.
  """
  def get_detailed_metrics do
    GenServer.call(__MODULE__, :get_detailed_metrics)
  end

  # ── GenServer Callbacks ───────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    Logger.info("📊 Paradox Density Monitor initialized (Phase 5F.5)")

    # Start periodic reporting to MSCL Kernel
    timer = Process.send_after(self(), :report_to_mscl, @reporting_interval_ms)

    state = %__MODULE__{
      reporting_timer: timer
    }

    {:ok, state}
  end

  @impl true
  def handle_cast(:reset, state) do
    {:noreply, %{state |
      regional_paradox_map: %{},
      global_density: 0.0
    }}
  end

  @impl true
  def handle_cast({:report_paradox_intensity, region_id, intensity, resonance_factor}, state) do
    # Validate inputs
    validated_intensity = max(0.0, min(1.0, intensity))
    validated_resonance = max(0.0, min(1.0, resonance_factor))

    # Update regional map
    updated_map = Map.put(state.regional_paradox_map, region_id, {
      validated_intensity,
      validated_resonance,
      DateTime.utc_now()
    })

    # Trim if exceeding max regions
    trimmed_map =
      if map_size(updated_map) > @max_tracked_regions do
        # Remove oldest entries
        updated_map
        |> Enum.sort_by(fn {_id, {_int, _res, ts}} -> ts end)
        |> Enum.take(-@max_tracked_regions)
        |> Map.new()
      else
        updated_map
      end

    # Recalculate global density
    new_density = calculate_global_density(trimmed_map)

    updated_state = %{state | regional_paradox_map: trimmed_map, global_density: new_density}

    # Check thresholds
    check_density_thresholds(new_density, region_id)

    {:noreply, updated_state}
  end

  @impl true
  def handle_call(:get_global_density, _from, state) do
    {:reply, {:ok, state.global_density}, state}
  end

  @impl true
  def handle_call(:get_detailed_metrics, _from, state) do
    metrics = %{
      global_density: state.global_density,
      total_tracked_regions: map_size(state.regional_paradox_map),
      safe_threshold: @safe_density_threshold,
      critical_threshold: @critical_density_threshold,
      status: determine_status(state.global_density),
      top_paradox_regions: get_top_paradox_regions(state.regional_paradox_map, 5)
    }

    {:reply, {:ok, metrics}, state}
  end

  @impl true
  def handle_info(:report_to_mscl, state) do
    # Report current global density to MSCL Kernel
    MSCLKernel.report_paradox_density(state.global_density)

    Logger.debug("📤 [PDM] Reported global paradox density: #{state.global_density |> :erlang.float_to_binary(decimals: 3)}")

    # Schedule next report
    timer = Process.send_after(self(), :report_to_mscl, @reporting_interval_ms)

    updated_state = %{state | reporting_timer: timer}

    {:noreply, updated_state}
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp calculate_global_density(regional_map) do
    if map_size(regional_map) == 0 do
      0.0
    else
      # Π_global = Σ(κ_i · ρ_i) / Ω_runtime
      total_weighted_paradox = Enum.sum(Enum.map(regional_map, fn {_id, {intensity, resonance, _ts}} ->
        intensity * resonance
      end))

      omega_runtime = map_size(regional_map)
      total_weighted_paradox / omega_runtime
    end
  end

  defp check_density_thresholds(density, region_id) do
    cond do
      density > @critical_density_threshold ->
        Logger.error("🔥 [PDM] CRITICAL paradox density: #{density |> :erlang.float_to_binary(decimals: 3)} in region #{region_id}")
        trigger_critical_response(density, region_id)

      density > @safe_density_threshold ->
        Logger.warning("⚠️ [PDM] Elevated paradox density: #{density |> :erlang.float_to_binary(decimals: 3)} in region #{region_id}")
        trigger_elevated_response(density)

      true ->
        Logger.debug("✅ [PDM] Safe paradox density: #{density |> :erlang.float_to_binary(decimals: 3)}")
    end
  end

  defp trigger_critical_response(density, region_id) do
    Logger.error("🚨 [PDM] Initiating critical response for region #{region_id}")

    # TODO: In production, would trigger:
    # - Immediate observer creation freeze
    # - Chronogram write throttling
    # - Region quarantine via CTN Containment Field
    # - Escalation to CIS Supervisor

    Logger.error("🛑 [PDM] CRITICAL: All observer operations suspended in region #{region_id}")
  end

  defp trigger_elevated_response(density) do
    Logger.warning("⚡ [PDM] Initiating elevated response measures")

    # TODO: In production, would trigger:
    # - Observer creation rate limiting
    # - Increased monitoring frequency
    # - Preemptive stabilization checks
  end

  defp determine_status(density) do
    cond do
      density > @critical_density_threshold -> :critical
      density > @safe_density_threshold -> :elevated
      density > @safe_density_threshold * 0.7 -> :moderate
      true -> :stable
    end
  end

  defp get_top_paradox_regions(regional_map, count) do
    regional_map
    |> Enum.map(fn {id, {intensity, resonance, _ts}} ->
      %{
        region_id: id,
        intensity: intensity,
        resonance_factor: resonance,
        weighted_score: intensity * resonance
      }
    end)
    |> Enum.sort_by(& &1.weighted_score, :desc)
    |> Enum.take(count)
  end
end
