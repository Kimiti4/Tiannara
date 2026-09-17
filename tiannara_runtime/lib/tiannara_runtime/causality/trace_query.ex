defmodule TiannaraRuntime.Causality.TraceQuery do
  @moduledoc """
  PHASE 4C.3: Trace Query API
  
  Provides high-level query interface for reconstructing full causal chains
  and decision trees from trace_id.
  
  This is the primary API used by UI components for cognitive forensics.
  
  Usage:
    # Get complete decision tree for an event
    {:ok, tree} = TraceQuery.get_decision_tree(trace_id)
    
    # Get causal explanation (human-readable)
    {:ok, explanation} = TraceQuery.explain_causality(event_id)
    
    # Replay causal chain in order
    {:ok, replay} = TraceQuery.replay_chain(trace_id)
  """
  
  require Logger
  
  @doc """
  Get complete decision tree for a trace.
  
  Returns hierarchical structure showing all events in the trace chain.
  
  Example output:
    %{
      root: %{event_id, type, metadata},
      children: [
        %{event_id, type, metadata, children: [...]},
        ...
      ]
    }
  """
  def get_decision_tree(trace_id) do
    case TiannaraRuntime.Causality.TracePropagation.get_trace_chain(trace_id) do
      {:ok, chain} ->
        # Build tree structure from flat chain
        tree = build_tree(chain)
        {:ok, tree}
      
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc """
  Get causal chain as ordered list of events.
  
  Returns: {:ok, [event]} ordered from root to leaf
  """
  def get_causal_chain(trace_id) do
    TiannaraRuntime.Causality.TracePropagation.get_trace_chain(trace_id)
  end
  
  @doc """
  Get ancestors of a specific event with full context.
  
  Returns: {:ok, [event_with_context]}
  """
  def get_event_ancestry(event_id) do
    # Get trace_id from event
    trace_id = extract_trace_id_from_event(event_id)
    
    if trace_id do
      # Get full chain
      case get_causal_chain(trace_id) do
        {:ok, chain} ->
          # Find event position
          event_index = Enum.find_index(chain, fn ctx -> ctx.trace_id == event_id end)
          
          if event_index do
            # Return all events before this one
            ancestors = Enum.take(chain, event_index)
            {:ok, ancestors}
          else
            {:error, "Event not found in trace chain"}
          end
        
        {:error, reason} ->
          {:error, reason}
      end
    else
      {:error, "Event has no trace_id"}
    end
  end
  
  @doc """
  Get all CIS interventions affecting an event.
  
  Returns: {:ok, [intervention_details]}
  """
  def get_affecting_interventions(event_id) do
    case TiannaraRuntime.Causality.CausalGraph.get_interventions(event_id) do
      {:ok, interventions} ->
        # Enrich with additional context
        enriched = Enum.map(interventions, fn intervention ->
          %{
            intervention_id: intervention.id,
            type: intervention.type,
            timestamp: intervention.created_at,
            metadata: intervention.metadata
          }
        end)
        
        {:ok, enriched}
      
      error ->
        error
    end
  end
  
  @doc """
  Get all CAL decisions influencing an event.
  
  Returns: {:ok, [decision_details]}
  """
  def get_influencing_decisions(event_id) do
    case TiannaraRuntime.Causality.CausalGraph.get_cal_decisions(event_id) do
      {:ok, decisions} ->
        enriched = Enum.map(decisions, fn decision ->
          %{
            decision_id: decision.id,
            type: decision.type,
            timestamp: decision.created_at,
            metadata: decision.metadata
          }
        end)
        
        {:ok, enriched}
      
      error ->
        error
    end
  end
  
  @doc """
  Generate human-readable causal explanation for an event.
  
  Returns: {:ok, explanation_text}
  """
  def explain_causality(event_id) do
    with {:ok, ancestors} <- get_event_ancestry(event_id),
         {:ok, interventions} <- get_affecting_interventions(event_id),
         {:ok, decisions} <- get_influencing_decisions(event_id) do
      
      explanation = build_explanation(event_id, ancestors, interventions, decisions)
      {:ok, explanation}
    else
      {:error, reason} ->
        {:error, "Cannot explain causality: #{reason}"}
    end
  end
  
  @doc """
  Replay entire causal chain in chronological order.
  
  Returns: {:ok, [replay_step]}
  """
  def replay_chain(trace_id) do
    case get_causal_chain(trace_id) do
      {:ok, chain} ->
        replay_steps = Enum.map(chain, fn context ->
          %{
            step: context.depth + 1,
            trace_id: context.trace_id,
            event_type: context.root_event,
            timestamp: context.started_at,
            parent: context.parent_trace_id,
            metadata: context.metadata
          }
        end)
        
        {:ok, replay_steps}
      
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc """
  Get graph statistics for a trace.
  
  Returns: %{chain_length, intervention_count, decision_count, max_depth}
  """
  def get_trace_stats(trace_id) do
    case get_causal_chain(trace_id) do
      {:ok, chain} ->
        stats = %{
          chain_length: length(chain),
          intervention_count: count_by_type(chain, "cis_intervention"),
          decision_count: count_by_type(chain, "cal_decision"),
          max_depth: Enum.max_by(chain, fn c -> c.depth end).depth
        }
        
        {:ok, stats}
      
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Private Functions
  
  defp build_tree(chain) do
    # Find root (depth 0)
    root = Enum.find(chain, fn ctx -> ctx.depth == 0 end)
    
    if root do
      %{
        root: format_node(root),
        children: build_children(root.trace_id, chain)
      }
    else
      %{root: nil, children: []}
    end
  end
  
  defp build_children(parent_id, chain) do
    children = Enum.filter(chain, fn ctx -> ctx.parent_trace_id == parent_id end)
    
    Enum.map(children, fn child ->
      %{
        node: format_node(child),
        children: build_children(child.trace_id, chain)
      }
    end)
  end
  
  defp format_node(context) do
    %{
      trace_id: context.trace_id,
      event_type: context.root_event,
      depth: context.depth,
      timestamp: context.started_at,
      metadata: context.metadata
    }
  end
  
  defp extract_trace_id_from_event(event_id) do
    # In production, this would query event store
    # For now, assume event_id IS the trace_id
    event_id
  end
  
  defp build_explanation(event_id, ancestors, interventions, decisions) do
    lines = [
      "🔍 Causal Explanation for Event: #{event_id}",
      "",
      "📊 Chain Overview:",
      "  • Total ancestors: #{length(ancestors)}",
      "  • CIS interventions: #{length(interventions)}",
      "  • CAL decisions: #{length(decisions)}",
      ""
    ]
    
    ancestor_lines = if length(ancestors) > 0 do
      ["🔗 Ancestry Chain:"] ++
      Enum.map(Enum.with_index(ancestors), fn {ancestor, idx} ->
        "  #{idx + 1}. #{ancestor.root_event} (depth: #{ancestor.depth})"
      end) ++ [""]
    else
      ["  (No ancestors found)", ""]
    end
    
    intervention_lines = if length(interventions) > 0 do
      ["⚡ CIS Interventions:"] ++
      Enum.map(interventions, fn int ->
        "  • #{int.intervention_id} at #{int.timestamp}"
      end) ++ [""]
    else
      ["  (No interventions)", ""]
    end
    
    decision_lines = if length(decisions) > 0 do
      ["🎯 CAL Decisions:"] ++
      Enum.map(decisions, fn dec ->
        "  • #{dec.decision_id} at #{dec.timestamp}"
      end) ++ [""]
    else
      ["  (No decisions)", ""]
    end
    
    Enum.concat(lines, ancestor_lines)
    |> Enum.concat(intervention_lines)
    |> Enum.concat(decision_lines)
    |> Enum.join("\n")
  end
  
  defp count_by_type(chain, target_type) do
    Enum.count(chain, fn ctx ->
      ctx.root_event == target_type
    end)
  end
end
