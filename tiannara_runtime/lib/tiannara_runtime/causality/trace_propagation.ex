defmodule TiannaraRuntime.Causality.TracePropagation do
  @moduledoc """
  PHASE 4C: TraceID Propagation System
  
  Injects and maintains trace_id across all CAL/CIS/Cortex events to enable
  full causal chain reconstruction.
  
  Design Principle: Every event must belong to a trace chain with clear
  parent-child relationships for complete decision lineage.
  
  Usage:
    # Start new trace (root event)
    trace_id = TracePropagation.start_trace(event_type, metadata)
    
    # Continue existing trace (child event)
    child_trace_id = TracePropagation.continue_trace(parent_trace_id, event_type, metadata)
    
    # Get trace context from event
    trace_id = TracePropagation.get_trace_id(event)
  """
  
  require Logger
  
  @doc """
  Start a new trace chain (root event).
  
  Returns: trace_id (UUID string)
  """
  def start_trace(event_type, metadata \\ %{}) do
    trace_id = generate_trace_id()
    
    trace_context = %{
      trace_id: trace_id,
      parent_trace_id: nil,
      root_event: event_type,
      depth: 0,
      started_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      metadata: metadata
    }
    
    Logger.debug("🔍 Starting new trace: #{trace_id} (#{event_type})")
    
    # Store trace context for future reference
    store_trace_context(trace_id, trace_context)
    
    trace_id
  end
  
  @doc """
  Continue an existing trace (create child event).
  
  Returns: new trace_id for the child event
  """
  def continue_trace(parent_trace_id, event_type, metadata \\ %{}) do
    # Get parent context
    parent_context = get_trace_context(parent_trace_id)
    
    if is_nil(parent_context) do
      Logger.warning("⚠️ Parent trace not found: #{parent_trace_id}, creating new trace")
      start_trace(event_type, metadata)
    else
      child_trace_id = generate_trace_id()
      
      child_context = %{
        trace_id: child_trace_id,
        parent_trace_id: parent_trace_id,
        root_event: parent_context.root_event,
        depth: parent_context.depth + 1,
        started_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        metadata: metadata
      }
      
      Logger.debug("🔍 Continuing trace: #{child_trace_id} (depth: #{child_context.depth})")
      
      # Store child context
      store_trace_context(child_trace_id, child_context)
      
      # Link parent → child relationship
      link_trace_events(parent_trace_id, child_trace_id, event_type)
      
      child_trace_id
    end
  end
  
  @doc """
  Extract trace_id from an event payload.
  
  Returns: trace_id or nil if not present
  """
  def get_trace_id(event) when is_map(event) do
    Map.get(event, "trace_id") || Map.get(event, :trace_id)
  end
  
  def get_trace_id(_event), do: nil
  
  @doc """
  Enrich event with trace context.
  
  Returns: enriched event map with trace metadata
  """
  def enrich_with_trace(event, trace_id) do
    trace_context = get_trace_context(trace_id)
    
    if trace_context do
      event
      |> Map.put("trace_id", trace_id)
      |> Map.put("parent_trace_id", trace_context.parent_trace_id)
      |> Map.put("trace_depth", trace_context.depth)
      |> Map.put("root_event", trace_context.root_event)
    else
      event
      |> Map.put("trace_id", trace_id)
    end
  end
  
  @doc """
  Get full trace chain for a given trace_id.
  
  Returns: {:ok, [trace_context]} ordered from root to leaf
  """
  def get_trace_chain(trace_id) do
    case get_trace_context(trace_id) do
      nil ->
        {:error, "Trace not found: #{trace_id}"}
      
      context ->
        # Walk up to find root
        root_context = find_root(context)
        
        # Walk down from root to collect all descendants
        chain = collect_descendants(root_context.trace_id)
        
        {:ok, chain}
    end
  end
  
  @doc """
  Get all direct children of a trace.
  
  Returns: [child_trace_id]
  """
  def get_children(trace_id) do
    case get_trace_context(trace_id) do
      nil -> []
      _context ->
        # Query stored relationships
        get_stored_children(trace_id)
    end
  end
  
  @doc """
  Get trace ancestry (all parents up to root).
  
  Returns: [parent_trace_id] ordered from immediate parent to root
  """
  def get_ancestry(trace_id) do
    case get_trace_context(trace_id) do
      nil -> []
      context ->
        walk_ancestry(context, [])
    end
  end
  
  # Private Functions
  
  defp generate_trace_id() do
    "trace_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
  end
  
  defp store_trace_context(trace_id, context) do
    # In production, this would use ETS or database
    # For now, using process dictionary (will be replaced with proper storage)
    Process.put({:trace_context, trace_id}, context)
  end
  
  defp get_trace_context(trace_id) do
    Process.get({:trace_context, trace_id})
  end
  
  defp link_trace_events(parent_id, child_id, event_type) do
    # Store parent→child relationship
    children = get_stored_children(parent_id)
    new_children = [{child_id, event_type} | children]
    Process.put({:trace_children, parent_id}, new_children)
  end
  
  defp get_stored_children(trace_id) do
    Process.get({:trace_children, trace_id}, [])
  end
  
  defp find_root(context) do
    if is_nil(context.parent_trace_id) do
      context
    else
      parent_context = get_trace_context(context.parent_trace_id)
      if parent_context do
        find_root(parent_context)
      else
        context
      end
    end
  end
  
  defp collect_descendants(trace_id) do
    context = get_trace_context(trace_id)
    
    if context do
      children = get_stored_children(trace_id)
      
      # Collect current node
      [context | Enum.flat_map(children, fn {child_id, _event_type} ->
        collect_descendants(child_id)
      end)]
    else
      []
    end
  end
  
  defp walk_ancestry(context, acc) do
    if is_nil(context.parent_trace_id) do
      Enum.reverse(acc)
    else
      parent_context = get_trace_context(context.parent_trace_id)
      
      if parent_context do
        walk_ancestry(parent_context, [context.parent_trace_id | acc])
      else
        Enum.reverse(acc)
      end
    end
  end
end
