defmodule Tiannara.Meta.ObserverArbitrationLayer do
  @moduledoc """
  Phase 5F.2 — Observer Collapse Arbitration Layer (OCAL)

  Decision engine that resolves:
  > "Which observer reality survives shared execution space?"

  Operates as a physics-aware scheduler for ontology survival.

  ## The Three Outcomes

  ### 🧬 MERGE — Hybrid Reality Spawn
  Triggered: OSS delta < 10% AND high MSCL elasticity
  → Synthesize a new chimera observer from A + B
  → Shared causal history, merged CTN topology, blended physics

  ### 🧊 SUPPRESS — Dormant Reality
  Triggered: One observer stable but low utility
  → Observer is paused, not deleted
  → Cached manifold, resurrectable state, latent physics seed

  ### ☠️ COLLAPSE — Hard Termination
  Triggered: OSS critically low OR destructive interference
  → Observer removed from execution topology
  → Trace preserved in causal archive for future recompilation

  ## Fundamental Principle

  "Existence is a privilege, not a state."
  Reality is SELECTED under constraints of stability, interference, and compressibility.
  """

  use GenServer
  require Logger

  alias TiannaraRuntime.MCK
  alias Tiannara.NATS.MetaEvolutionStreamManager

  # Blend weight for chimera manifold synthesis (A gets 1 - @chimera_blend, B gets @chimera_blend)
  @chimera_blend 0.5

  # Suppressed observer TTL — auto-resurrect check interval
  @suppression_sweep_ms 120_000   # 2 minutes

  # --------------------------------------------------------------------------
  # Public API
  # --------------------------------------------------------------------------

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Execute the arbitration decision for a pair of observers.

  decision: :merge | :suppress | :collapse
  Returns the outcome map.
  """
  def resolve(decision, observer_a, observer_b, oss_a, oss_b) do
    GenServer.call(__MODULE__, {:resolve, decision, observer_a, observer_b, oss_a, oss_b})
  end

  @doc """
  Attempt resurrection of a suppressed observer.
  Returns {:ok, observer_id} or {:error, reason}.
  """
  def attempt_resurrection(observer_id) do
    GenServer.call(__MODULE__, {:resurrect, observer_id})
  end

  @doc """
  List all currently suppressed (dormant) observers.
  """
  def list_suppressed do
    GenServer.call(__MODULE__, :list_suppressed)
  end

  @doc """
  List all chimeras created by merge decisions.
  """
  def list_chimeras do
    GenServer.call(__MODULE__, :list_chimeras)
  end

  @doc """
  List all collapsed observers in the causal archive.
  """
  def list_collapsed_archive do
    GenServer.call(__MODULE__, :list_archive)
  end

  # --------------------------------------------------------------------------
  # GenServer Callbacks
  # --------------------------------------------------------------------------

  @impl true
  def init(_opts) do
    case :ets.info(:suppressed_observers) do
      :undefined -> :ets.new(:suppressed_observers, [:named_table, :set, :public])
      _ -> :ets.delete_all_objects(:suppressed_observers)
    end

    case :ets.info(:collapsed_causal_archive) do
      :undefined -> :ets.new(:collapsed_causal_archive, [:named_table, :bag, :public])
      _ -> :ets.delete_all_objects(:collapsed_causal_archive)
    end

    case :ets.info(:chimeras) do
      :undefined -> :ets.new(:chimeras, [:named_table, :set, :public])
      _ -> :ets.delete_all_objects(:chimeras)
    end

    schedule_suppression_sweep()

    Logger.info("🧭 [OCAL] Observer Arbitration Layer initialized (Phase 5F.2)")
    {:ok, %{chimera_count: 0, collapse_count: 0, suppress_count: 0, resurrect_count: 0}}
  end

  # ── MERGE — Hybrid Reality Spawn ──────────────────────────────────────────

  @impl true
  def handle_call({:resolve, :merge, a, b, oss_a, oss_b}, _from, state) do
    chimera_id = "CHIMERA-#{a.observer_id}-#{b.observer_id}-#{System.unique_integer([:positive])}"

    # Build chimera manifold from blended observer fields
    chimera_manifold = synthesize_chimera(a, b, oss_a, oss_b)

    # Register the new chimera in MCK
    MCK.register_observer(chimera_id, chimera_manifold)
    MCK.validate(Map.put(chimera_manifold, :observer_id, chimera_id))

    # Collapse both parents — they are now represented by the chimera
    MCK.collapse_observer(a.observer_id, :chimeric_merge)
    MCK.collapse_observer(b.observer_id, :chimeric_merge)

    outcome = %{
      decision: :merge,
      chimera_id: chimera_id,
      parents: {a.observer_id, b.observer_id},
      blended_oss: blend_oss(oss_a, oss_b)
    }

    :ets.insert(:chimeras, {chimera_id, chimera_manifold, a.observer_id, b.observer_id, DateTime.utc_now()})

    Logger.info("🧬 [OCAL] Chimera spawned: #{chimera_id} (parents: #{a.observer_id}, #{b.observer_id})")
    publish_ocal_event(:merge, outcome)

    {:reply, {:ok, outcome}, %{state | chimera_count: state.chimera_count + 1}}
  end

  # ── SUPPRESS — Dormant Reality ────────────────────────────────────────────

  @impl true
  def handle_call({:resolve, :suppress, a, b, oss_a, oss_b}, _from, state) do
    # Lower-OSS observer is suppressed; higher persists
    {loser, _winner, loser_oss} =
      if oss_a <= oss_b,
        do:   {a, b, oss_a},
        else: {b, a, oss_b}

    loser_id = Map.get(loser, :observer_id) || Map.get(loser, "observer_id", "unknown")

    # Pause the loser in MCK (collapse_observer moves it to archive)
    MCK.collapse_observer(loser_id, :suppressed)

    # Record in suppressed table with metadata for potential resurrection
    suppression_record = {
      loser_id,
      loser,
      loser_oss,
      :suppressed,
      DateTime.utc_now()
    }
    :ets.insert(:suppressed_observers, {loser_id, suppression_record})

    outcome = %{
      decision: :suppress,
      suppressed_id: loser_id,
      oss: loser_oss
    }

    Logger.info("🧊 [OCAL] Suppressed: #{loser_id} (OSS=#{Float.round(loser_oss, 3)})")
    publish_ocal_event(:suppress, outcome)

    {:reply, {:ok, outcome}, %{state | suppress_count: state.suppress_count + 1}}
  end

  # ── COLLAPSE — Hard Termination ───────────────────────────────────────────

  @impl true
  def handle_call({:resolve, :collapse, a, b, oss_a, oss_b}, _from, state) do
    {loser, winner, loser_oss, winner_oss} =
      if oss_a <= oss_b,
        do:   {a, b, oss_a, oss_b},
        else: {b, a, oss_b, oss_a}

    loser_id = Map.get(loser, :observer_id) || Map.get(loser, "observer_id", "unknown")
    winner_id = Map.get(winner, :observer_id) || Map.get(winner, "observer_id", "unknown")

    # Terminate loser in MCK
    MCK.collapse_observer(loser_id, :hard_collapse)

    # Archive trace for future recompilation under different bias vectors
    archive_entry = {
      loser_id,
      loser,
      loser_oss,
      :collapsed,
      DateTime.utc_now()
    }
    :ets.insert(:collapsed_causal_archive, {loser_id, archive_entry})

    outcome = %{
      decision: :collapse,
      collapsed_id: loser_id,
      surviving_id: winner_id,
      collapsed_oss: loser_oss,
      surviving_oss: winner_oss
    }

    Logger.warning("☠️  [OCAL] Collapsed: #{loser_id} (OSS=#{Float.round(loser_oss, 3)}), " <>
                   "Survivor: #{winner_id} (OSS=#{Float.round(winner_oss, 3)})")
    publish_ocal_event(:collapse, outcome)

    {:reply, {:ok, outcome}, %{state | collapse_count: state.collapse_count + 1}}
  end

  # ── Resurrection ──────────────────────────────────────────────────────────

  @impl true
  def handle_call({:resurrect, observer_id}, _from, state) do
    result = case :ets.lookup(:suppressed_observers, observer_id) do
      [{^observer_id, {_, manifold, _oss, _, _}}] ->
        :ets.delete(:suppressed_observers, observer_id)
        MCK.resurrect_observer(observer_id)
        Logger.info("🌱 [OCAL] Resurrected suppressed observer #{observer_id}")
        publish_ocal_event(:resurrect, %{observer_id: observer_id})
        {:ok, observer_id}

      [] ->
        # Try collapsed archive
        case :ets.lookup(:collapsed_causal_archive, observer_id) do
          [{^observer_id, {_, manifold, _oss, _, _}} | _] ->
            # Re-register in MCK for recompilation under potentially shifted bias
            MCK.register_observer(observer_id, manifold)
            MCK.validate(Map.put(manifold, :observer_id, observer_id))
            Logger.info("⚡ [OCAL] Recompiled collapsed observer #{observer_id} from archive")
            publish_ocal_event(:resurrect, %{observer_id: observer_id, source: :archive})
            {:ok, observer_id}

          [] ->
            {:error, :not_found}
        end
    end

    new_count = if match?({:ok, _}, result), do: state.resurrect_count + 1, else: state.resurrect_count
    {:reply, result, %{state | resurrect_count: new_count}}
  end

  @impl true
  def handle_call(:list_chimeras, _from, state) do
    chimeras = :ets.tab2list(:chimeras)
      |> Enum.map(fn {id, manifold, parent_a, parent_b, created_at} ->
        %{chimera_id: id, parent_a: parent_a, parent_b: parent_b, created_at: created_at}
      end)

    {:reply, {:ok, chimeras}, state}
  end

  @impl true
  def handle_call(:list_suppressed, _from, state) do
    suppressed = :ets.tab2list(:suppressed_observers)
      |> Enum.map(fn {id, {_, _, oss, _, suppressed_at}} ->
        %{observer_id: id, oss: oss, suppressed_at: suppressed_at}
      end)

    {:reply, {:ok, suppressed}, state}
  end

  @impl true
  def handle_call(:list_archive, _from, state) do
    archive = :ets.tab2list(:collapsed_causal_archive)
      |> Enum.map(fn {id, {_, _, oss, status, at}} ->
        %{observer_id: id, oss: oss, status: status, collapsed_at: at}
      end)

    {:reply, {:ok, archive}, state}
  end

  # ── Periodic Suppression Sweep ────────────────────────────────────────────

  @impl true
  def handle_info(:suppression_sweep, state) do
    suppressed = :ets.tab2list(:suppressed_observers)
    now = DateTime.utc_now()

    # Auto-resurrect observers suppressed for more than 10 minutes
    # (heuristic: suppressed too long = system conditions have changed)
    Enum.each(suppressed, fn {id, {_, _manifold, oss, _, suppressed_at}} ->
      age_seconds = DateTime.diff(now, suppressed_at)
      if age_seconds > 600 and oss > 0.40 do
        Logger.info("[OCAL] Auto-resurrect suppressed observer #{id} (age: #{age_seconds}s, OSS: #{oss})")
        GenServer.call(__MODULE__, {:resurrect, id})
      end
    end)

    schedule_suppression_sweep()
    {:noreply, state}
  end

  # --------------------------------------------------------------------------
  # Chimera Synthesis
  # --------------------------------------------------------------------------

  defp synthesize_chimera(a, b, oss_a, oss_b) do
    # Weight contribution proportional to OSS: higher-OSS observer dominates blend
    total = oss_a + oss_b + 0.001
    w_a   = oss_a / total
    w_b   = oss_b / total

    %{
      # Blended causal graph: A's edges weighted by w_a, B's by w_b
      # Append both with weighted tags for downstream MCK validation
      causality_graph: blend_causality_graphs(
        Map.get(a, :causality_graph, []),
        Map.get(b, :causality_graph, []),
        w_a, w_b
      ),

      # Time vector: weighted average of both observer time directions
      time_vector: blend_float_list(
        Map.get(a, :time_vector, [0.0, 0.0, 1.0]),
        Map.get(b, :time_vector, [0.0, 0.0, 1.0]),
        w_a
      ),

      # Physics compiler: prefer the higher-OSS parent's compiler
      physics_compiler: if(oss_a >= oss_b, do: Map.get(a, :physics_compiler, "GLSL"),
                                            else: Map.get(b, :physics_compiler, "GLSL")),

      # Entropy: superposition of both fields
      entropy_field: blend_float_list(
        Map.get(a, :entropy_field, [0.5]),
        Map.get(b, :entropy_field, [0.5]),
        w_a
      ),

      # CTN interference: full superposition
      ctn_interference: superpose_fields(
        Map.get(a, :ctn_interference, []),
        Map.get(b, :ctn_interference, [])
      ),

      coherence:    blend_scalar(Map.get(a, :coherence, 0.5), Map.get(b, :coherence, 0.5), w_a),
      msf:          blend_scalar(Map.get(a, :msf, 0.5), Map.get(b, :msf, 0.5), w_a),
      prediction:   blend_scalar(Map.get(a, :prediction, 0.5), Map.get(b, :prediction, 0.5), w_a),
      interference: max(Map.get(a, :interference, 0.5), Map.get(b, :interference, 0.5)),

      status: :registered,
      chimera: true,
      parent_ids: [Map.get(a, :observer_id), Map.get(b, :observer_id)]
    }
  end

  defp blend_oss(oss_a, oss_b) do
    Float.round((oss_a + oss_b) / 2.0, 6)
  end

  defp blend_scalar(a, b, w_a) when is_number(a) and is_number(b) do
    Float.round(a * w_a + b * (1.0 - w_a), 6)
  end
  defp blend_scalar(a, _b, _w_a), do: a

  defp blend_float_list(list_a, list_b, w_a) when is_list(list_a) and is_list(list_b) do
    max_len = max(length(list_a), length(list_b))
    a_pad   = list_a ++ List.duplicate(0.0, max_len - length(list_a))
    b_pad   = list_b ++ List.duplicate(0.0, max_len - length(list_b))

    Enum.zip(a_pad, b_pad)
    |> Enum.map(fn {va, vb} -> va * w_a + vb * (1.0 - w_a) end)
  end
  defp blend_float_list(a, b, _w_a), do: a || b || []

  defp blend_causality_graphs(edges_a, edges_b, w_a, w_b) do
    scaled_a = Enum.map(edges_a, fn
      %{from: f, to: t, weight: w} -> %{from: f, to: t, weight: w * w_a}
      {f, t, w} -> {f, t, w * w_a}
      e -> e
    end)

    scaled_b = Enum.map(edges_b, fn
      %{from: f, to: t, weight: w} -> %{from: f, to: t, weight: w * w_b}
      {f, t, w} -> {f, t, w * w_b}
      e -> e
    end)

    scaled_a ++ scaled_b
  end

  defp superpose_fields(field_a, field_b) when is_list(field_a) and is_list(field_b) do
    max_len = max(length(field_a), length(field_b))
    a_pad   = field_a ++ List.duplicate(0.0, max_len - length(field_a))
    b_pad   = field_b ++ List.duplicate(0.0, max_len - length(field_b))

    Enum.zip(a_pad, b_pad)
    |> Enum.map(fn {a, b} ->
      if is_number(a) and is_number(b), do: a + b * 0.5, else: a || b || 0.0
    end)
  end
  defp superpose_fields(a, b), do: a || b || []

  # --------------------------------------------------------------------------
  # NATS Events
  # --------------------------------------------------------------------------

  defp publish_ocal_event(decision, metadata) do
    payload = Map.merge(metadata, %{
      event_type: "ocal_#{decision}",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    })

    try do
      MetaEvolutionStreamManager.publish("tiannara.meta.ocal.decisions", payload)
    rescue
      e -> Logger.warning("[OCAL] NATS publish failed: #{inspect(e)}")
    end
  end

  defp schedule_suppression_sweep do
    Process.send_after(self(), :suppression_sweep, @suppression_sweep_ms)
  end
end
