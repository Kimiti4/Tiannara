defmodule TiannaraOS.EvidenceEngine do
  @moduledoc """
  Core engine for Evidence Graph operations and Justification-Based Truth Maintenance (JTMS++) propagation.
  """

  alias TiannaraOS.State
  alias TiannaraOS.EvidenceNode

  require Logger

  # Refutation semantics
  @refutation_multiplier 0.7
  @failed_replication_penalty 0.2
  @contested_threshold 0.5
  @invalid_threshold 0.25

  # --- PUBLIC API ---

  @doc "Registers a new node in the Evidence Graph."
  @spec add_node(State.t(), atom(), EvidenceNode.t()) :: State.t()
  def add_node(%State{} = state, node_id, %EvidenceNode{} = node) do
    # Synchronize confidence if it was defaulted to 1.0 but value is explicitly set
    updated_confidence =
      if node.confidence == 1.0 and node.value != nil and node.value != 1.0 do
        node.value
      else
        node.confidence
      end

    node = %{node | id: node_id, confidence: updated_confidence}
    new_graph = Map.put(state.evidence_graph, node_id, node)
    %{state | evidence_graph: new_graph}
  end

  @doc "Establishes a relation (dependency link) between two nodes in the graph."
  @spec add_relation(State.t(), atom(), atom(), atom(), float(), integer() | nil, integer()) :: State.t()
  def add_relation(%State{} = state, from_id, relation_type, to_id, strength \\ 1.0, half_life_ticks \\ nil, current_tick \\ 0) do
    graph = state.evidence_graph

    case {Map.get(graph, from_id), Map.get(graph, to_id)} do
      {nil, _} ->
        Logger.warning("EvidenceEngine: Cannot find relation source node #{from_id}")
        state

      {_, nil} ->
        Logger.warning("EvidenceEngine: Cannot find relation target node #{to_id}")
        state

      {from_node, to_node} ->
        from_meta = from_node.metadata || %{}
        to_meta = to_node.metadata || %{}
        from_rels = Map.get(from_meta, :relations, %{})
        to_rels = Map.get(to_meta, :relations, %{})

        updated_from_rels =
          Map.put(from_rels, to_id, %{
            direction: :dependent,
            relation: relation_type,
            strength: strength,
            half_life_ticks: half_life_ticks,
            last_refreshed_tick: current_tick
          })

        updated_to_rels =
          Map.put(to_rels, from_id, %{
            direction: :justification,
            relation: relation_type,
            strength: strength,
            half_life_ticks: half_life_ticks,
            last_refreshed_tick: current_tick
          })

        updated_from = %{
          from_node
          | dependents: Enum.uniq([to_id | from_node.dependents]),
            metadata: Map.put(from_meta, :relations, updated_from_rels)
        }

        updated_to = %{
          to_node
          | justifications: Enum.uniq([from_id | to_node.justifications]),
            metadata: Map.put(to_meta, :relations, updated_to_rels)
        }

        new_graph = graph |> Map.put(from_id, updated_from) |> Map.put(to_id, updated_to)
        %{state | evidence_graph: new_graph}
    end
  end

  @doc "Decays relation strengths exponentially based on half-life configuration over elapsed ticks."
  @spec decay_relations(State.t(), integer()) :: State.t()
  def decay_relations(%State{} = state, current_tick) do
    new_graph =
      Map.new(state.evidence_graph, fn {node_id, node} ->
        meta = node.metadata || %{}
        rels = Map.get(meta, :relations, %{})

        if rels == %{} do
          {node_id, node}
        else
          decayed_rels =
            Map.new(rels, fn {other_id, rel_meta} ->
              case rel_meta.half_life_ticks do
                nil ->
                  {other_id, rel_meta}

                half_life when is_integer(half_life) and half_life > 0 ->
                  elapsed = current_tick - rel_meta.last_refreshed_tick

                  if elapsed > 0 do
                    new_strength = rel_meta.strength * :math.pow(0.5, elapsed / half_life)
                    updated_meta = %{rel_meta | strength: new_strength, last_refreshed_tick: current_tick}
                    {other_id, updated_meta}
                  else
                    {other_id, rel_meta}
                  end

                _ ->
                  {other_id, rel_meta}
              end
            end)

          updated_meta = Map.put(meta, :relations, decayed_rels)
          {node_id, %{node | metadata: updated_meta}}
        end
      end)

    %{state | evidence_graph: new_graph}
  end

  # --- JTMS++ CASCADE PROPAGATION ---

  @doc """
  Cascades a confidence delta through the evidence graph using damped propagation.
  Implements budget protection to prevent CPU death spirals.
  """
  @spec cascade_jtms_delta(State.t(), atom(), float(), atom()) :: State.t()
  def cascade_jtms_delta(%State{} = state, source_id, delta, event_type) do
    damping_factor = get_in(state.governance, [:damping_factor]) || 0.9
    max_ops = get_in(state.governance, [:max_cascade_operations]) || 1000
    cascade_id = generate_cascade_id()
    
    # Initialize queue with [source_id, delta, depth=0] (depth 0 for root)
    initial_queue = [{source_id, delta, 0}]
    visited = MapSet.new([source_id])
    
    process_cascade(state, initial_queue, visited, cascade_id, 0, max_ops, damping_factor, event_type)
  end

  defp process_cascade(state, [], _visited, cascade_id, ops_count, _max_ops, _damping, _event_type) do
    # Cascade complete
    Logger.info("JTMS++ Cascade #{cascade_id} completed with #{ops_count} operations")
    state
  end

  defp process_cascade(state, _queue, _visited, cascade_id, ops_count, max_ops, _damping, _event_type) when ops_count >= max_ops do
    # Budget exceeded - pause and persist
    Logger.warning("JTMS++ Cascade #{cascade_id} paused at #{ops_count} operations (budget: #{max_ops})")
    put_in(state.governance[:paused_cascades], Map.put(
      state.governance[:paused_cascades] || %{},
      cascade_id,
      %{remaining_queue: :persisted, ops_count: ops_count}
    ))
  end

  defp process_cascade(state, [{current_id, current_delta, depth} | rest_queue], visited, cascade_id, ops_count, max_ops, damping_factor, event_type) do
    # Check budget BEFORE processing
    if ops_count >= max_ops do
      Logger.warning("JTMS++ Cascade #{cascade_id} paused at #{ops_count} operations (budget: #{max_ops})")
      put_in(state.governance[:paused_cascades], Map.put(
        state.governance[:paused_cascades] || %{},
        cascade_id,
        %{remaining_queue: :persisted, ops_count: ops_count}
      ))
    else
      graph = state.evidence_graph
      
      case Map.get(graph, current_id) do
        nil ->
          # Node doesn't exist - log and continue
          Logger.warning("JTMS++ Cascade: Missing node #{current_id}, skipping")
          process_cascade(state, rest_queue, visited, cascade_id, ops_count + 1, max_ops, damping_factor, event_type)
        
        current_node ->
          # Apply delta to current node
          old_confidence = current_node.confidence
          new_confidence = clamp_confidence(old_confidence + current_delta)
          actual_delta = new_confidence - old_confidence
          
          updated_node = %{current_node | confidence: new_confidence}
          new_graph = Map.put(graph, current_id, updated_node)
          
          # Log to dependency history
          history_entry = %{
            timestamp: System.system_time(:millisecond),
            source_node: current_id,
            target_node: current_id,
            relation: :self_update,
            delta: actual_delta,
            event_type: event_type,
            cascade_id: cascade_id,
            cascade_depth: depth
          }
          
          updated_state = %{state | 
            evidence_graph: new_graph,
            dependency_history: [history_entry | state.dependency_history]
          }
          
          # Propagate to dependents
          dependents = current_node.dependents || []
          relations = get_in(current_node.metadata, [:relations]) || %{}
          
          {new_state, new_queue} = Enum.reduce(dependents, {updated_state, rest_queue}, fn dep_id, {acc_state, acc_queue} ->
            if MapSet.member?(visited, dep_id) do
              # Already visited - skip to prevent cycles
              {acc_state, acc_queue}
            else
              case Map.get(acc_state.evidence_graph, dep_id) do
                nil ->
                  Logger.warning("JTMS++ Cascade: Dependent #{dep_id} not found")
                  {acc_state, acc_queue}
                
                _dep_node ->
                  # Get relation strength
                  rel_meta = Map.get(relations, dep_id, %{})
                  strength = Map.get(rel_meta, :strength, 1.0)
                  
                  # Calculate damped delta
                  effective_delta = actual_delta * strength * damping_factor
                  
                  # Add to queue for next processing
                  {acc_state, acc_queue ++ [{dep_id, effective_delta, depth + 1}]}
              end
            end
          end)
          
          process_cascade(new_state, new_queue, visited, cascade_id, ops_count + 1, max_ops, damping_factor, event_type)
      end
    end
  end

  @doc """
  Registers a successful replication event, triggering positive recovery cascade.
  """
  @spec register_successful_replication(State.t(), atom(), atom()) :: State.t()
  def register_successful_replication(%State{} = state, _replication_id, target_id) do
    graph = state.evidence_graph
    
    case Map.get(graph, target_id) do
      nil ->
        Logger.warning("JTMS++ Replication: Target node #{target_id} not found")
        state
      
      _target_node ->
        # Positive delta for successful replication
        recovery_delta = 0.1  # Configurable recovery amount
        
        # Apply recovery cascade
        cascade_jtms_delta(state, target_id, recovery_delta, :recovery)
    end
  end

  @doc """
  Registers a failed replication event, triggering negative degradation cascade.

  Every failure reduces the node's evidence value by a growing penalty. Once
  the value falls below the validity threshold the node is refuted and the
  standard refutation cascade propagates through the graph.
  """
  @spec register_failed_replication(State.t(), atom(), atom()) :: State.t()
  def register_failed_replication(%State{} = state, replication_id, target_id) do
    case Map.get(state.evidence_graph, target_id) do
      nil ->
        Logger.warning("JTMS++ Failed Replication: Target node #{target_id} not found")
        state

      node ->
        attempts = failed_replication_attempts(node) + 1
        state = degrade_replication_value(state, node, replication_id, attempts)

        # Confidence degradation cascade (JTMS confidence channel)
        state = cascade_jtms_delta(state, target_id, -0.15, :degradation)

        case Map.get(state.evidence_graph, target_id) do
          %{validity: :invalid} -> refute_evidence(state, target_id)
          _ -> state
        end
    end
  end

  @doc """
  Refutes a piece of evidence.

  The evidence is marked invalid, every direct dependent is degraded by the
  refutation multiplier, the theories justified by the degraded nodes are
  recalculated from their claims, and anything falling below the validity
  threshold is retired together with a cascading invalidation of its
  dependents.
  """
  @spec refute_evidence(State.t(), atom()) :: State.t()
  def refute_evidence(%State{} = state, evidence_id) do
    case Map.get(state.evidence_graph, evidence_id) do
      nil ->
        state

      evidence ->
        state = put_node(state, mark_refuted(evidence))
        broadcast({:evidence_refuted, evidence_id})

        {state, degraded_ids} = degrade_dependents(state, evidence_id)
        {state, recalculated_ids} = recalculate_justifying_theories(state, degraded_ids)

        run_invalidation_cascade(state, [evidence_id | degraded_ids ++ recalculated_ids])
    end
  end

  @doc """
  Computes comprehensive civilization metrics from the current state.
  """
  @spec get_civilization_metrics(State.t()) :: map()
  def get_civilization_metrics(%State{} = state) do
    graph = state.evidence_graph
    discoveries = state.discoveries
    programs = state.research_programs
    
    # Theory confidence metrics
    theory_nodes = graph |> Map.values() |> Enum.filter(&(&1.type == :theory))
    avg_theory_conf = if length(theory_nodes) > 0 do
      Enum.sum_by(theory_nodes, & &1.confidence) / length(theory_nodes)
    else
      1.0
    end
    
    # Discovery metrics
    active_discs = discoveries |> Map.values() |> Enum.filter(&(&1.status != :retired))
    retired_discs = discoveries |> Map.values() |> Enum.filter(&(&1.status == :retired))
    
    # Program metrics
    active_progs = programs |> Map.values() |> Enum.filter(&(&1.status == :active))
    suspended_progs = programs |> Map.values() |> Enum.filter(&(&1.status == :suspended))
    
    # Dependency events
    total_dep_events = length(state.dependency_history)
    
    # Epistemic shock score (based on large negative events)
    recent_shocks = state.dependency_history
    |> Enum.filter(fn e -> e.event_type == :degradation && e.delta < -0.1 end)
    |> length()
    
    epistemic_shock_score = min(1.0, recent_shocks / 100.0)
    
    # Recovery rate
    recovery_events = state.dependency_history
    |> Enum.filter(fn e -> e.event_type == :recovery end)
    |> length()
    
    degradation_events = state.dependency_history
    |> Enum.filter(fn e -> e.event_type == :degradation end)
    |> length()
    
    recovery_rate = if degradation_events > 0 do
      recovery_events / degradation_events
    else
      1.0
    end
    
    # Epistemic stability (variance of theory confidences)
    epistemic_stability = if length(theory_nodes) > 1 do
      mean = avg_theory_conf
      variance = Enum.sum_by(theory_nodes, fn t -> :math.pow(t.confidence - mean, 2) end) / length(theory_nodes)
      1.0 - min(1.0, variance * 10)  # Lower variance = higher stability
    else
      1.0
    end
    
    # Knowledge velocity (validated discoveries per time unit)
    validated_count = discoveries |> Map.values() |> Enum.filter(&(&1.status == :validated)) |> length()
    knowledge_velocity = validated_count / max(1, total_dep_events / 100)
    
    %{average_theory_confidence: avg_theory_conf,
      active_discoveries: length(active_discs),
      retired_discoveries: length(retired_discs),
      active_programs: length(active_progs),
      suspended_programs: length(suspended_progs),
      total_dependency_events: total_dep_events,
      recovery_rate: recovery_rate,
      epistemic_stability: epistemic_stability,
      epistemic_shock_score: epistemic_shock_score,
      knowledge_velocity: knowledge_velocity,
      worlds: %{}}
  end

  # --- REFUTATION HELPERS ---

  defp put_node(%State{} = state, %EvidenceNode{} = node) do
    %{state | evidence_graph: Map.put(state.evidence_graph, node.id, node)}
  end

  defp mark_refuted(%EvidenceNode{} = node) do
    now = DateTime.utc_now()
    metadata = node.metadata || %{}

    updated_meta =
      metadata
      |> Map.put(:provenance, ["refuted" | List.wrap(Map.get(metadata, :provenance))])
      |> Map.put(:last_updated_at, now)

    %{node | validity: :invalid, metadata: updated_meta}
  end

  defp degrade_dependents(%State{} = state, source_id) do
    source = Map.get(state.evidence_graph, source_id)
    dependents = if source, do: source.dependents || [], else: []

    {state, degraded_ids} =
      Enum.reduce(dependents, {state, []}, fn dep_id, {acc_state, acc_ids} ->
        case Map.get(acc_state.evidence_graph, dep_id) do
          nil ->
            {acc_state, acc_ids}

          dependent ->
            case degrade_node(dependent, source_id) do
              nil -> {acc_state, acc_ids}
              updated -> {put_node(acc_state, updated), [dep_id | acc_ids]}
            end
        end
      end)

    {state, Enum.reverse(degraded_ids)}
  end

  defp degrade_node(%EvidenceNode{} = node, source_id) do
    if is_number(node.value) do
      new_value = node.value * @refutation_multiplier
      now = DateTime.utc_now()
      metadata = node.metadata || %{}

      updated_meta =
        metadata
        |> Map.put(:provenance, ["degraded_by_evidence:#{source_id}" | List.wrap(Map.get(metadata, :provenance))])
        |> Map.put(:confidence_history, [
          %{value: new_value, updated_at: now} | List.wrap(Map.get(metadata, :confidence_history))
        ])
        |> Map.put(:last_updated_at, now)

      %{node | value: new_value, validity: validity_for(new_value), metadata: updated_meta}
    else
      nil
    end
  end

  defp recalculate_justifying_theories(%State{} = state, changed_ids) do
    theory_ids =
      changed_ids
      |> Enum.flat_map(fn id ->
        case Map.get(state.evidence_graph, id) do
          nil ->
            []

          node ->
            (node.justifications || [])
            |> Enum.filter(fn justification -> node_type(state, justification) == :theory end)
        end
      end)
      |> Enum.uniq()

    {state, recalculated_ids} =
      Enum.reduce(theory_ids, {state, []}, fn theory_id, {acc_state, acc_ids} ->
        case recalculate_theory(acc_state, theory_id) do
          {:changed, new_state} -> {new_state, [theory_id | acc_ids]}
          {:unchanged, new_state} -> {new_state, acc_ids}
        end
      end)

    {state, Enum.reverse(recalculated_ids)}
  end

  defp recalculate_theory(%State{} = state, theory_id) do
    theory = Map.get(state.evidence_graph, theory_id)

    if is_nil(theory) or theory.type != :theory do
      {:unchanged, state}
    else
      claim_ids =
        theory_claim_ids(state, theory)
        |> Enum.filter(&is_number(node_value(state, &1)))

      if claim_ids == [] do
        {:unchanged, state}
      else
        new_value = Enum.sum(Enum.map(claim_ids, &node_value(state, &1))) / length(claim_ids)

        if new_value == theory.value do
          {:unchanged, state}
        else
          now = DateTime.utc_now()
          metadata = theory.metadata || %{}
          provenance = Enum.map(claim_ids, &"recalculated_from_claim:#{&1}")

          updated_meta =
            metadata
            |> Map.update(:provenance, provenance, fn existing -> provenance ++ List.wrap(existing) end)
            |> Map.put(:confidence_history, [
              %{value: new_value, updated_at: now} | List.wrap(Map.get(metadata, :confidence_history))
            ])
            |> Map.put(:last_updated_at, now)

          new_validity = validity_for(new_value)
          state = put_node(state, %{theory | value: new_value, validity: new_validity, metadata: updated_meta})

          broadcast({:theory_confidence_changed, theory_id, new_value})
          if new_validity == :invalid, do: broadcast({:theory_retired, theory_id})

          {:changed, state}
        end
      end
    end
  end

  defp theory_claim_ids(%State{} = state, theory) do
    linked = Enum.uniq((theory.dependents || []) ++ (theory.justifications || []))
    Enum.filter(linked, fn id -> node_type(state, id) == :claim end)
  end

  defp run_invalidation_cascade(%State{} = state, root_ids) do
    root_ids = Enum.uniq(root_ids)

    invalid_roots =
      Enum.filter(root_ids, fn id ->
        case Map.get(state.evidence_graph, id) do
          %{validity: :invalid} -> true
          _ -> false
        end
      end)

    process_invalidation(state, invalid_roots, MapSet.new(root_ids))
  end

  defp process_invalidation(%State{} = state, [], _visited), do: state

  defp process_invalidation(%State{} = state, [node_id | rest], visited) do
    node = Map.get(state.evidence_graph, node_id)

    if is_nil(node) do
      process_invalidation(state, rest, visited)
    else
      {state, visited, queued} =
        Enum.reduce(node.dependents || [], {state, visited, []}, fn dep_id, {acc_state, acc_visited, acc_queued} ->
          if MapSet.member?(acc_visited, dep_id) do
            {acc_state, acc_visited, acc_queued}
          else
            acc_visited = MapSet.put(acc_visited, dep_id)

            case Map.get(acc_state.evidence_graph, dep_id) do
              nil ->
                {acc_state, acc_visited, acc_queued}

              dependent ->
                {put_node(acc_state, invalidate_node(dependent, node_id)), acc_visited, [dep_id | acc_queued]}
            end
          end
        end)

      process_invalidation(state, rest ++ Enum.reverse(queued), visited)
    end
  end

  defp invalidate_node(%EvidenceNode{} = node, source_id) do
    now = DateTime.utc_now()
    metadata = node.metadata || %{}

    updated_meta =
      metadata
      |> Map.put(:provenance, ["invalidated_by:#{source_id}" | List.wrap(Map.get(metadata, :provenance))])
      |> Map.put(:last_updated_at, now)

    case node.type do
      :theory -> broadcast({:theory_retired, node.id})
      :discovery -> broadcast({:discovery_retired, node.id})
      _ -> :ok
    end

    new_value = if is_number(node.value), do: 0.0, else: node.value
    %{node | value: new_value, validity: :invalid, metadata: updated_meta}
  end

  defp failed_replication_attempts(%EvidenceNode{} = node) do
    case Map.get(node.metadata || %{}, :replication_attempts) do
      attempts when is_integer(attempts) and attempts > 0 -> attempts
      _ -> 0
    end
  end

  defp degrade_replication_value(%State{} = state, %EvidenceNode{} = node, replication_id, attempts) do
    metadata = node.metadata || %{}

    if is_number(node.value) do
      new_value = max(0.0, node.value - @failed_replication_penalty * attempts)
      now = DateTime.utc_now()

      updated_meta =
        metadata
        |> Map.put(:replication_attempts, attempts)
        |> Map.put(:provenance, ["failed_replication:#{replication_id}" | List.wrap(Map.get(metadata, :provenance))])
        |> Map.put(:confidence_history, [
          %{value: new_value, updated_at: now} | List.wrap(Map.get(metadata, :confidence_history))
        ])
        |> Map.put(:last_updated_at, now)

      put_node(state, %{node | value: new_value, validity: validity_for(new_value), metadata: updated_meta})
    else
      put_node(state, %{node | metadata: Map.put(metadata, :replication_attempts, attempts)})
    end
  end

  defp validity_for(value) when is_number(value) do
    cond do
      value >= @contested_threshold -> :valid
      value >= @invalid_threshold -> :contested
      true -> :invalid
    end
  end

  defp validity_for(_value), do: :valid

  defp node_value(state, node_id) do
    case Map.get(state.evidence_graph, node_id) do
      nil -> nil
      node -> node.value
    end
  end

  defp node_type(state, node_id) do
    case Map.get(state.evidence_graph, node_id) do
      nil -> nil
      node -> node.type
    end
  end

  defp broadcast(event) do
    case Process.whereis(Tiannara.PubSub) do
      nil -> :ok
      _pid -> Phoenix.PubSub.broadcast(Tiannara.PubSub, "tiannara_events", event)
    end
  end

  # --- HELPER FUNCTIONS ---

  defp clamp_confidence(conf) do
    max(0.0, conf)
  end

  defp generate_cascade_id() do
    "cascade_#{System.system_time(:millisecond)}_#{:rand.uniform(10000)}"
  end
end
