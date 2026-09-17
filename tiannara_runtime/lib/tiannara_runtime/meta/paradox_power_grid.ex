defmodule Tiannara.Meta.ParadoxPowerGrid do
  @moduledoc """
  Phase 5F — Paradox Power-Grid Harvester

  Harvests oscillatory friction metrics from active Causal Tensegrity Nodes
  to artificially depress global selection temperatures and subsidize mutation costs.

  Each CTN that reports tension + loop_frequency contributes:

      extracted_yield = tension × log(loop_frequency + 1)
      tau_depression  = atan(total_energy × 0.01) × 0.5

  The resulting tau modifier is published to NATS:
      "tiannara.meta.temperature.field"

  This module focuses on raw energy harvesting from individual CTN reports.
  For the full subsidy distribution algorithm, see ParadoxPowerGrid.Distributor.
  """

  use GenServer
  require Logger

  alias Tiannara.NATS.MetaEvolutionStreamManager

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # --------------------------------------------------------------------------
  # Public API
  # --------------------------------------------------------------------------

  @doc """
  Report oscillatory friction metrics for a single CTN.

  Parameters:
    - node_id: CTN identifier string
    - tension: local structural tension (0.0 – 1.0)
    - loop_frequency: oscillation frequency in Hz (e.g. 4.2)
  """
  def report_ctn_metrics(node_id, tension, loop_frequency) do
    GenServer.cast(__MODULE__, {:report_ctn_metrics, node_id, tension, loop_frequency})
  end

  @doc "Return current harvested energy and tau modifier."
  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  @doc "Reset energy accumulator (for testing / epoch resets)."
  def reset do
    GenServer.cast(__MODULE__, :reset)
  end

  # --------------------------------------------------------------------------
  # GenServer Callbacks
  # --------------------------------------------------------------------------

  @impl true
  def init(_opts) do
    Logger.info("⚡ [ParadoxPowerGrid] Paradox energy harvester initialized (Phase 5F)")
    {:ok, %{total_harvested_energy: 0.0, global_tau_modifier: 0.0}}
  end

  @impl true
  def handle_cast({:report_ctn_metrics, node_id, tension, loop_frequency}, state) do
    # Energy extraction: oscillatory friction of the infinite loop
    extracted_yield = tension * :math.log(loop_frequency + 1.0)
    new_energy = state.total_harvested_energy + extracted_yield

    # Depress global selection temperature logarithmically
    # High paradox containment = ultra-rigid structural conservation in normal zones
    tau_depression = :math.atan(new_energy * 0.01) * 0.5

    Logger.debug("[ParadoxPowerGrid] CTN #{node_id}: yield=#{Float.round(extracted_yield, 4)}, " <>
                 "total_energy=#{Float.round(new_energy, 2)}, tau_mod=#{Float.round(tau_depression, 4)}")

    # Push updated thermodynamic constraints down NATS JetStream
    publish_temperature_field(tau_depression, new_energy)

    {:noreply, %{state | total_harvested_energy: new_energy, global_tau_modifier: tau_depression}}
  end

  @impl true
  def handle_cast(:reset, _state) do
    Logger.info("[ParadoxPowerGrid] Energy accumulator reset")
    {:noreply, %{total_harvested_energy: 0.0, global_tau_modifier: 0.0}}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, {:ok, state}, state}
  end

  # --------------------------------------------------------------------------
  # Private Helpers
  # --------------------------------------------------------------------------

  defp publish_temperature_field(tau_depression, new_energy) do
    payload = %{
      global_tau_modifier: tau_depression,
      paradox_power_index: new_energy,
      source: :paradox_power_grid,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    try do
      MetaEvolutionStreamManager.publish("tiannara.meta.temperature.field", payload)
    rescue
      e -> Logger.warning("[ParadoxPowerGrid] Failed NATS publish: #{inspect(e)}")
    end
  end
end

# --------------------------------------------------------------------------
# Subsidy Distribution Algorithm
# --------------------------------------------------------------------------

defmodule Tiannara.Meta.ParadoxPowerGrid.Distributor do
  @moduledoc """
  Phase 5F — Paradox Battery Subsidy Distributor

  Subscribes to `tiannara.meta.power.telemetry` (raw joule telemetry from GPU),
  calculates the systemic selection temperature floor, and re-broadcasts to
  `tiannara.meta.temperature.field` so the WebGL injection pass can freeze
  high-fitness lineages in place.

  Formula:
      energy_subsidy = log(joules + 1) × 0.02
      target_tau     = max(base_tau - energy_subsidy, min_tau_floor)
  """

  use GenServer
  require Logger

  alias Tiannara.NATS.MetaEvolutionStreamManager

  @base_tau      0.15
  @min_tau_floor 0.005

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    subscribe_to_telemetry()
    Logger.info("🔋 [ParadoxPowerGrid.Distributor] Subsidy distributor initialized (Phase 5F)")
    {:ok, %{base_tau: @base_tau, min_tau_floor: @min_tau_floor, last_tau: @base_tau}}
  end

  @impl true
  def handle_info({:msg, %{body: body}}, state) do
    case Jason.decode(body) do
      {:ok, %{"harvested_joules" => joules, "active_knots" => knots}} when is_number(joules) ->
        energy_subsidy = :math.log(joules + 1.0) * 0.02
        target_tau = max(state.base_tau - energy_subsidy, state.min_tau_floor)

        Logger.debug("[Distributor] joules=#{Float.round(joules, 2)}, knots=#{knots}, " <>
                     "tau=#{Float.round(target_tau, 4)}")

        # Broadcast the new structural physics modifier to the entire GPU asset grid
        publish_temperature(target_tau, energy_subsidy, knots)

        {:noreply, %{state | last_tau: target_tau}}

      {:ok, _other} ->
        {:noreply, state}

      {:error, reason} ->
        Logger.warning("[Distributor] Failed to decode telemetry: #{inspect(reason)}")
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}

  # --------------------------------------------------------------------------
  # Private Helpers
  # --------------------------------------------------------------------------

  defp subscribe_to_telemetry do
    try do
      Gnat.sub(:tiannara_nats, self(), "tiannara.meta.power.telemetry")
    catch
      _, _ -> Logger.warning("[Distributor] NATS sub failed (process probably not running)")
    end
  end

  defp publish_temperature(target_tau, subsidy_index, knot_count) do
    payload = %{
      global_tau: target_tau,
      subsidy_index: subsidy_index,
      system_knot_count: knot_count,
      source: :paradox_distributor,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    try do
      MetaEvolutionStreamManager.publish("tiannara.meta.temperature.field", payload)
    rescue
      e -> Logger.warning("[Distributor] Failed NATS publish: #{inspect(e)}")
    end
  end
end
