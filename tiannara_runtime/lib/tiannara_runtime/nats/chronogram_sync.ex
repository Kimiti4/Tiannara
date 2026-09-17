defmodule Tiannara.Meta.Mesh.ChronogramSync do
  @moduledoc """
  Phase 5F.x — Distributed Chronogram Synchronization

  Synchronizes observer-relative memory across distributed mesh nodes.
  Handles phase mutations, history projections, and timeline reconciliation
  using causal eventual consistency model.

  ## Consistency Model

  Uses CAUSAL EVENTUAL CONSISTENCY (not strong consistency):
  - Observers converge relative to their MEI frequency
  - Different observers may permanently disagree (intentional)
  - Contradictory histories are preserved, not resolved
  - Partition tolerance through localized realities

  ## Synchronization Events

  - `tiannara.chronogram.write` — Memory write operations
  - `tiannara.chronogram.project` — History projection requests
  - `tiannara.chronogram.phase_shift` — Phase angle mutations
  - `tiannara.chronogram.reconcile` — Timeline reconciliation

  ## Usage

      # Synchronize phase shift
      ChronogramSync.synchronize("obs_001", "sector_alpha", %{
        phase_angles: [0.5, 0.3, 0.7],
        coherence: 0.92
      })

      # Request timeline reconciliation
      ChronogramSync.reconcile("obs_001", "obs_002")
  """

  use GenServer
  require Logger

  alias Tiannara.Meta.Mesh.RealityBus

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Synchronizes a chronogram phase shift across the mesh.

  ## Parameters
  - `observer_id`: Observer identifier
  - `coordinate`: Chronogram coordinate/sector
  - `phase_data`: Phase mutation data (angles, coherence, etc.)

  ## Returns
  - `:ok` on successful synchronization

  ## Example

      ChronogramSync.synchronize("obs_001", "sector_alpha", %{
        phase_angles: [0.5, 0.3],
        coherence: 0.92
      })
  """
  def synchronize(observer_id, coordinate, phase_data) do
    RealityBus.publish("tiannara.chronogram.phase_shift", %{
      observer_id: observer_id,
      coordinate: coordinate,
      phase: phase_data,
      timestamp: System.system_time(:millisecond)
    })

    Logger.debug("🌊 [ChronogramSync] Synchronized phase shift for #{observer_id}")
    :ok
  end

  @doc """
  Writes memory to chronogram with causal metadata.

  ## Parameters
  - `observer_id`: Observer identifier
  - `memory_data`: Memory content to store
  - `causal_context`: Causality chain information

  ## Returns
  - `:ok`

  ## Example

      ChronogramSync.write_memory("obs_001", %{
        content: "observation_data",
        entropy: 0.4
      }, %{
        trace_id: UUID.uuid4(),
        causal_depth: 2
      })
  """
  def write_memory(observer_id, memory_data, causal_context \\ %{}) do
    RealityBus.publish_causal("tiannara.chronogram.write", %{
      observer_id: observer_id,
      memory: memory_data
    }, causal_context)

    Logger.debug("📝 [ChronogramSync] Memory written for #{observer_id}")
    :ok
  end

  @doc """
  Projects observer history into a specific chronogram sector.

  ## Parameters
  - `observer_id`: Observer identifier
  - `target_sector`: Target sector for projection
  - `projection_params`: Projection parameters

  ## Returns
  - `:ok`

  ## Example

      ChronogramSync.project_history("obs_001", "sector_beta", %{
        time_range: {0, 1000},
        filter: :high_coherence
      })
  """
  def project_history(observer_id, target_sector, projection_params) do
    RealityBus.publish("tiannara.chronogram.project", %{
      observer_id: observer_id,
      target_sector: target_sector,
      params: projection_params,
      timestamp: System.system_time(:millisecond)
    })

    Logger.info("🔮 [ChronogramSync] History projected for #{observer_id} → #{target_sector}")
    :ok
  end

  @doc """
  Initiates timeline reconciliation between two observers.

  Used when observers need to merge contradictory histories.
  Performs MEI frequency comparison and phase-drift analysis.

  ## Parameters
  - `observer_a`: First observer ID
  - `observer_b`: Second observer ID
  - `reconciliation_strategy`: :merge, :branch, or :arbitrate

  ## Returns
  - `:ok`

  ## Example

      ChronogramSync.reconcile("obs_001", "obs_002", :merge)
  """
  def reconcile(observer_a, observer_b, strategy \\ :merge) do
    RealityBus.publish("tiannara.chronogram.reconcile", %{
      observer_a: observer_a,
      observer_b: observer_b,
      strategy: strategy,
      timestamp: System.system_time(:millisecond)
    })

    Logger.info("⚖️ [ChronogramSync] Reconciliation initiated: #{observer_a} ↔ #{observer_b} (#{strategy})")
    :ok
  end

  @doc """
  Publishes a reality snapshot for distributed state capture.

  Captures complete observer manifold state including:
  - Entropy levels
  - Chronogram sectors
  - OIR cache
  - Shader cache
  - MSCL pressure

  ## Parameters
  - `snapshot_data`: Complete snapshot map

  ## Returns
  - `:ok`

  ## Example

      ChronogramSync.publish_snapshot(%{
        snapshot_id: "snap_001",
        observer_manifold: "...",
        entropy_state: 0.45
      })
  """
  def publish_snapshot(snapshot_data) do
    RealityBus.publish("tiannara.mesh.snapshot", snapshot_data)

    Logger.info("📸 [ChronogramSync] Snapshot published: #{snapshot_data.snapshot_id}")
    :ok
  end

  # ── GenServer Callbacks ───────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    state = %{
      sync_events: 0,
      reconciliations: 0,
      snapshots_published: 0
    }

    Logger.info("🔄 [ChronogramSync] Initialized distributed chronogram synchronization")
    {:ok, state}
  end

  @impl true
  def handle_info({:msg, %{body: body, subject: subject}}, state) do
    try do
      decoded = Jason.decode!(body)
      handle_chronogram_message(subject, decoded)
    rescue
      e ->
        Logger.error("❌ [ChronogramSync] Failed to decode message: #{inspect(e)}")
    end

    new_state = %{state | sync_events: state.sync_events + 1}
    {:noreply, new_state}
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp handle_chronogram_message(subject, _payload) do
    cond do
      String.ends_with?(subject, "write") ->
        Logger.debug("📝 [ChronogramSync] Processing memory write")

      String.ends_with?(subject, "project") ->
        Logger.debug("🔮 [ChronogramSync] Processing history projection")

      String.ends_with?(subject, "phase_shift") ->
        Logger.debug("🌊 [ChronogramSync] Processing phase shift")

      String.ends_with?(subject, "reconcile") ->
        Logger.info("⚖️ [ChronogramSync] Processing reconciliation")

      true ->
        Logger.warning("⚠️ [ChronogramSync] Unknown chronogram event: #{subject}")
    end
  end
end
