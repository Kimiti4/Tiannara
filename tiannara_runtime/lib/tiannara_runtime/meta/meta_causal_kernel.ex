defmodule TiannaraRuntime.MCK do
  @moduledoc """
  Meta-Causal Compilation Kernel (MCK) — Phase 5F

  Replaces GCK completely. There is no global consistency in 5F.
  Each observer manifold is validated on its own self-consistency
  under its own causal logic.

  ## Decision Tree

      self_consistency < 0.4              → :reject_compile
      causal_loop_density > 0.9           → :accept_as_topology
      entropy_gradient_flat               → :collapse_to_null_observer
      otherwise                           → :compile_reality

  ## Authority Model (Split — Option 3)

  GPU owns:
    - local manifold evolution
    - field tensors
    - CTN interference
    - topology deformation

  Elixir owns:
    - observer lifecycle
    - arbitration
    - memory
    - stability governance
    - persistence / replay / safety
  """

  use GenServer
  require Logger

  alias Tiannara.NATS.MetaEvolutionStreamManager
  alias Tiannara.Meta.MSCL

  # ETS table for compiled observer manifolds
  @manifold_table :compiled_observer_manifolds

  # Self-consistency threshold to reject compilation
  @reject_threshold 0.4

  # Loop density threshold to accept as topology without further validation
  @topology_threshold 0.9

  # --------------------------------------------------------------------------
  # Public API
  # --------------------------------------------------------------------------

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Validate and compile an observer's causal manifold.

  ## Parameters
    - observer_state: map containing keys:
        :observer_id   - unique observer identifier
        :causality_graph  - list of {from, to, weight} edges
        :time_vector      - list of floats (observer-local time direction)
        :entropy_field    - list of floats
        :ctn_interference - list of complex-valued interference samples

  ## Returns
    - {:ok, :compiled, observer_id}
    - {:ok, :accepted_as_topology, observer_id}
    - {:ok, :null_observer, observer_id}
    - {:error, :rejected, observer_id}
  """
  def validate(observer_state) do
    GenServer.call(__MODULE__, {:validate, observer_state})
  end

  @doc """
  Register a new observer into the kernel registry.
  Lifecycle: register → compile → mutate → interfere → arbitrate → collapse → suppress → resurrect → merge
  """
  def register_observer(observer_id, initial_manifold) do
    GenServer.cast(__MODULE__, {:register, observer_id, initial_manifold})
  end

  @doc """
  Collapse an observer — removes its compiled manifold from active registry.
  """
  def collapse_observer(observer_id, reason \\ :natural) do
    GenServer.cast(__MODULE__, {:collapse, observer_id, reason})
  end

  @doc """
  Resurrect a previously collapsed observer by re-compiling from archived state.
  """
  def resurrect_observer(observer_id) do
    GenServer.call(__MODULE__, {:resurrect, observer_id})
  end

  @doc """
  Merge two observer manifolds. The surviving manifold inherits interference patterns
  from the consumed one. GPU-side field tensors are reconciled via NATS event.
  """
  def merge_observers(surviving_id, consumed_id) do
    GenServer.call(__MODULE__, {:merge, surviving_id, consumed_id})
  end

  @doc """
  List all active compiled manifolds.
  """
  def list_observers do
    :ets.tab2list(@manifold_table)
    |> Enum.map(fn {id, manifold, status, compiled_at} ->
      %{observer_id: id, manifold: manifold, status: status, compiled_at: compiled_at}
    end)
  end

  @doc """
  Retrieve a specific compiled manifold.
  """
  def get_manifold(observer_id) do
    case :ets.lookup(@manifold_table, observer_id) do
      [{^observer_id, manifold, status, compiled_at}] ->
        {:ok, %{observer_id: observer_id, manifold: manifold, status: status, compiled_at: compiled_at}}
      [] ->
        {:error, :not_found}
    end
  end

  # --------------------------------------------------------------------------
  # GenServer Callbacks
  # --------------------------------------------------------------------------

  @impl true
  def init(_opts) do
    :ets.new(@manifold_table, [:named_table, :set, :public])
    # Archive for collapsed observers
    :ets.new(:collapsed_observer_archive, [:named_table, :bag, :public])

    Logger.info("🌌 [MCK] Meta-Causal Compilation Kernel initialized (Phase 5F)")
    {:ok, %{compiled_count: 0, rejected_count: 0, topology_count: 0, null_count: 0}}
  end

  @impl true
  def handle_call({:validate, observer_state}, _from, state) do
    observer_id = Map.get(observer_state, :observer_id, "unknown-#{System.unique_integer()}")

    result = cond do
      self_consistency(observer_state) < @reject_threshold ->
        Logger.warning("[MCK] Observer #{observer_id}: rejected (self-consistency < #{@reject_threshold})")
        publish_mck_event(observer_id, :rejected, %{reason: :low_self_consistency})
        {:error, :rejected, observer_id}

      causal_loop_density(observer_state) > @topology_threshold ->
        Logger.info("[MCK] Observer #{observer_id}: accepted as topology (loop density > #{@topology_threshold})")
        store_manifold(observer_id, observer_state, :topology)
        publish_mck_event(observer_id, :accepted_as_topology, %{loop_density: causal_loop_density(observer_state)})
        {:ok, :accepted_as_topology, observer_id}

      entropy_gradient_flat?(observer_state) ->
        Logger.info("[MCK] Observer #{observer_id}: collapsed to null observer (flat entropy gradient)")
        :ets.insert(:collapsed_observer_archive, {observer_id, observer_state, :null, DateTime.utc_now()})
        publish_mck_event(observer_id, :null_observer, %{reason: :flat_entropy})
        {:ok, :null_observer, observer_id}

      true ->
        Logger.info("[MCK] Observer #{observer_id}: reality compiled successfully")
        store_manifold(observer_id, observer_state, :compiled)
        publish_mck_event(observer_id, :compiled, %{})

        # 5F.2: After successful compilation, check all existing observers for pairwise
        # interference conflicts and delegate arbitration to OCG
        check_interference_with_existing(observer_id, observer_state)

        # 5F.1: Evaluate this manifold through MSCL to establish its MSF score.
        # MSF feeds into OCG's OSS computation via hydrate_msf/1.
        run_mscl_evaluation(observer_id, observer_state)

        {:ok, :compiled, observer_id}
    end

    new_state = update_stats(state, result)
    {:reply, result, new_state}
  end

  @impl true
  def handle_call({:resurrect, observer_id}, _from, state) do
    archived = :ets.lookup(:collapsed_observer_archive, observer_id)

    result = case archived do
      [] ->
        {:error, :not_in_archive}

      [{^observer_id, manifold, _status, _at} | _] ->
        # Re-run validation on archived manifold
        revived = Map.put(manifold, :observer_id, observer_id)
        store_manifold(observer_id, revived, :resurrected)
        publish_mck_event(observer_id, :resurrected, %{})
        Logger.info("[MCK] Observer #{observer_id} resurrected from archive")
        {:ok, :resurrected, observer_id}
    end

    {:reply, result, state}
  end

  @impl true
  def handle_call({:merge, surviving_id, consumed_id}, _from, state) do
    with {:ok, %{manifold: survivor}} <- get_manifold(surviving_id),
         {:ok, %{manifold: consumed}} <- get_manifold(consumed_id) do

      # Merge CTN interference patterns — surviving inherits consumed's interference
      merged_ctn = merge_interference_fields(
        Map.get(survivor, :ctn_interference, []),
        Map.get(consumed, :ctn_interference, [])
      )

      updated = Map.put(survivor, :ctn_interference, merged_ctn)
      store_manifold(surviving_id, updated, :merged)

      # Archive the consumed observer
      :ets.insert(:collapsed_observer_archive, {consumed_id, consumed, :consumed_by_merge, DateTime.utc_now()})
      :ets.delete(@manifold_table, consumed_id)

      publish_mck_event(surviving_id, :merge_complete, %{consumed_id: consumed_id})
      Logger.info("[MCK] Observer #{consumed_id} merged into #{surviving_id}")

      {:reply, {:ok, :merged, surviving_id}, state}
    else
      {:error, :not_found} ->
        {:reply, {:error, :observer_not_found}, state}
    end
  end

  @impl true
  def handle_cast({:register, observer_id, initial_manifold}, state) do
    manifold = Map.put(initial_manifold, :observer_id, observer_id)
    store_manifold(observer_id, manifold, :registered)
    publish_mck_event(observer_id, :registered, %{})
    Logger.info("[MCK] Observer #{observer_id} registered (pending compilation)")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:collapse, observer_id, reason}, state) do
    case :ets.lookup(@manifold_table, observer_id) do
      [{^observer_id, manifold, _status, _at}] ->
        :ets.insert(:collapsed_observer_archive, {observer_id, manifold, {:collapsed, reason}, DateTime.utc_now()})
        :ets.delete(@manifold_table, observer_id)
        publish_mck_event(observer_id, :collapsed, %{reason: reason})
        Logger.info("[MCK] Observer #{observer_id} collapsed (reason: #{inspect(reason)})")

      [] ->
        Logger.warning("[MCK] Collapse requested for unknown observer #{observer_id}")
    end

    {:noreply, state}
  end

  # --------------------------------------------------------------------------
  # Validation Helpers
  # --------------------------------------------------------------------------

  defp self_consistency(observer_state) do
    # Measures internal coherence: ratio of non-conflicting causal edges
    edges = Map.get(observer_state, :causality_graph, [])
    if Enum.empty?(edges) do
      0.5
    else
      total = length(edges)
      # Count edges where weight > 0 (forward causal direction) as consistent
      consistent = Enum.count(edges, fn
        {_from, _to, w} when is_number(w) -> w > 0
        %{weight: w} when is_number(w) -> w > 0
        %{"weight" => w} when is_number(w) -> w > 0
        _ -> true
      end)
      consistent / total
    end
  end

  defp causal_loop_density(observer_state) do
    # Fraction of edges forming loops relative to total edge count
    edges = Map.get(observer_state, :causality_graph, [])
    if Enum.empty?(edges) do
      0.0
    else
      # Build a simple adjacency set to detect cycles
      edge_set = MapSet.new(edges, fn
        {from, to, _w} -> {from, to}
        %{from: from, to: to} -> {from, to}
        %{"from" => from, "to" => to} -> {from, to}
        edge -> edge
      end)

      loop_edges = Enum.count(edge_set, fn
        {from, to} -> MapSet.member?(edge_set, {to, from})
        _ -> false
      end)

      loop_edges / max(MapSet.size(edge_set), 1)
    end
  end

  defp entropy_gradient_flat?(observer_state) do
    entropy_field = Map.get(observer_state, :entropy_field, [])
    if length(entropy_field) < 2 do
      true
    else
      values = Enum.map(entropy_field, fn x -> if is_number(x), do: x, else: 0.0 end)
      max_val = Enum.max(values, fn -> 0.0 end)
      min_val = Enum.min(values, fn -> 0.0 end)
      # Flat = variance less than 0.02
      (max_val - min_val) < 0.02
    end
  end

  # --------------------------------------------------------------------------
  # Manifold Storage & Merge
  # --------------------------------------------------------------------------

  defp store_manifold(observer_id, manifold, status) do
    :ets.insert(@manifold_table, {observer_id, manifold, status, DateTime.utc_now()})
  end

  defp merge_interference_fields(base, consumed) do
    # Element-wise complex-field superposition
    max_len = max(length(base), length(consumed))
    base_padded   = base   ++ List.duplicate(0.0, max_len - length(base))
    consumed_padded = consumed ++ List.duplicate(0.0, max_len - length(consumed))

    Enum.zip(base_padded, consumed_padded)
    |> Enum.map(fn {a, b} ->
      # Superposition: amplitudes add, phases interact
      cond do
        is_number(a) and is_number(b) -> a + b * 0.5
        is_number(a) -> a
        is_number(b) -> b
        true -> 0.0
      end
    end)
  end

  # --------------------------------------------------------------------------
  # 5F.2 — OCG Integration: Interference Check After Compilation
  # --------------------------------------------------------------------------

  # CTN interference density threshold above which we escalate to OCG
  @interference_escalation_threshold 0.55

  defp check_interference_with_existing(new_id, new_state) do
    existing = :ets.tab2list(@manifold_table)

    Enum.each(existing, fn {existing_id, existing_manifold, status, _at} ->
      if existing_id != new_id and status in [:compiled, :topology, :resurrected] do
        # Compute cross-observer CTN interference density
        interference = compute_cross_interference(new_state, existing_manifold)

        if interference > @interference_escalation_threshold do
          Logger.info("[MCK] High interference (#{Float.round(interference, 3)}) between " <>
                      "#{new_id} ↔ #{existing_id} — escalating to OCG")

          # Build OSS-ready observer maps for OCG
          obs_new = build_oss_map(new_id, new_state, interference)
          obs_existing = build_oss_map(existing_id, existing_manifold, interference)

          # Delegate arbitration to OCG (async — does not block compilation)
          try do
            Tiannara.Meta.ObserverCollapseGovernor.evaluate_pair(obs_new, obs_existing)
          rescue
            e -> Logger.warning("[MCK] OCG delegation failed: #{inspect(e)}")
          end
        end
      end
    end)
  end

  defp compute_cross_interference(state_a, state_b) do
    ctn_a = Map.get(state_a, :ctn_interference, [])
    ctn_b = Map.get(state_b, :ctn_interference, [])

    if Enum.empty?(ctn_a) or Enum.empty?(ctn_b) do
      0.0
    else
      len = min(length(ctn_a), length(ctn_b))
      a_slice = Enum.take(ctn_a, len)
      b_slice = Enum.take(ctn_b, len)

      # Overlap density: fraction of positions where both fields are non-zero
      overlapping = Enum.zip(a_slice, b_slice)
        |> Enum.count(fn {a, b} ->
          is_number(a) and is_number(b) and abs(a) > 0.1 and abs(b) > 0.1
        end)

      overlapping / max(len, 1)
    end
  end

  defp build_oss_map(observer_id, manifold, interference) do
    %{
      observer_id:  observer_id,
      coherence:    Map.get(manifold, :coherence, 0.5),
      msf:          Map.get(manifold, :msf, 0.5),
      prediction:   Map.get(manifold, :prediction, 0.5),
      interference: interference,
      causality_graph:  Map.get(manifold, :causality_graph, []),
      ctn_interference: Map.get(manifold, :ctn_interference, []),
      entropy_field:    Map.get(manifold, :entropy_field, []),
      physics_compiler: Map.get(manifold, :physics_compiler, "GLSL")
    }
  end

  # 5F.1 — MSCL Evaluation after compilation
  defp run_mscl_evaluation(observer_id, observer_state) do
    mscl_payload = %{
      observer_id:      observer_id,
      coherence:        Map.get(observer_state, :coherence, 0.5),
      resistance:       Map.get(observer_state, :resistance, 0.7),
      ctn_interference: compute_interference_scalar(observer_state),
      loop_density:     causal_loop_density(observer_state),
      physics_delta:    Map.get(observer_state, :physics_delta, 0.0),
      resonance:        1.0
    }

    try do
      MSCL.evaluate_manifold(observer_id, mscl_payload)
    rescue
      e -> Logger.warning("[MCK] MSCL evaluation failed for #{observer_id}: #{inspect(e)}")
    end
  end

  defp compute_interference_scalar(observer_state) do
    field = Map.get(observer_state, :ctn_interference, [])
    if Enum.empty?(field) do
      0.0
    else
      values = Enum.filter(field, &is_number/1)
      if Enum.empty?(values) do
        0.0
      else
        avg = Enum.sum(values) / length(values)
        min(abs(avg), 1.0)
      end
    end
  end

  # --------------------------------------------------------------------------
  # NATS Events
  # --------------------------------------------------------------------------

  defp publish_mck_event(observer_id, event_type, metadata) do
    payload = Map.merge(metadata, %{
      event_type: "mck_#{event_type}",
      observer_id: observer_id,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    })

    try do
      MetaEvolutionStreamManager.publish("tiannara.meta.mck.observer.events", payload)
    rescue
      e -> Logger.warning("[MCK] Failed to publish NATS event #{event_type}: #{inspect(e)}")
    end
  end

  # --------------------------------------------------------------------------
  # Stats
  # --------------------------------------------------------------------------

  defp update_stats(state, {:ok, :compiled, _}),            do: %{state | compiled_count: state.compiled_count + 1}
  defp update_stats(state, {:ok, :accepted_as_topology, _}), do: %{state | topology_count: state.topology_count + 1}
  defp update_stats(state, {:ok, :null_observer, _}),        do: %{state | null_count: state.null_count + 1}
  defp update_stats(state, {:error, :rejected, _}),          do: %{state | rejected_count: state.rejected_count + 1}
  defp update_stats(state, _),                               do: state
end
