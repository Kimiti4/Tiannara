defmodule TiannaraOS.Governance.Validation.CampaignPlanner do
  @moduledoc """
  CampaignPlanner - Builds execution plan from campaign registry (DAG construction).
  
  This module takes campaign specifications and constructs a directed acyclic graph
  of execution dependencies, then produces a phased execution plan.
  
  Responsibilities:
  - Validate dependency graph is acyclic
  - Topologically sort campaigns into phases
  - Detect circular dependencies
  - Calculate maximum concurrency per phase
  """

  @type campaign_spec :: map()
  @type execution_plan :: map()

  @doc """
  Build execution plan from list of campaign specs.
  
  Returns phased execution plan respecting dependencies.
  """
  @spec build_execution_plan([campaign_spec()]) :: {:ok, execution_plan()} | {:error, term()}
  def build_execution_plan(campaigns) do
    with :valid <- validate_dependencies(campaigns),
         :acyclic <- detect_cycles(campaigns),
         phases <- topological_sort(campaigns) do
      
      plan = %{
        phases: phases,
        total_phases: length(phases),
        dependency_graph: build_adjacency_list(campaigns),
        max_concurrency: calculate_max_concurrency(phases)
      }
      
      {:ok, plan}
    else
      {:cycle_detected, cycle} -> {:error, "Circular dependency detected: #{inspect(cycle)}"}
      {:invalid_deps, details} -> {:error, "Invalid dependencies: #{inspect(details)}"}
    end
  end

  @doc """
  Detect circular dependencies in campaign graph.
  
  Returns :valid if acyclic, or {:cycle_detected, cycle_path} if cyclic.
  """
  @spec detect_cycles([campaign_spec()]) :: :valid | {:cycle_detected, [String.t()]}
  def detect_cycles(campaigns) do
    adj_list = build_adjacency_list(campaigns)
    visited = MapSet.new()
    rec_stack = MapSet.new()
    
    case Enum.find(campaigns, fn campaign ->
      has_cycle?(campaign.campaign_id, adj_list, visited, rec_stack, [])
    end) do
      nil -> :valid
      {_, cycle} -> {:cycle_detected, cycle}
    end
  end

  @doc """
  Topologically sort campaigns into execution phases.
  
  Returns list of phases, where each phase is a list of campaign IDs that can execute in parallel.
  """
  @spec topological_sort([campaign_spec()]) :: [[String.t()]]
  def topological_sort(campaigns) do
    # Calculate in-degree for each node
    in_degrees = calculate_in_degrees(campaigns)
    
    # Start with nodes that have no dependencies
    queue = in_degrees
    |> Enum.filter(fn {_id, degree} -> degree == 0 end)
    |> Enum.map(fn {id, _} -> id end)
    
    # BFS to assign phases
    assign_phases(queue, campaigns, in_degrees, [], 0)
  end

  @doc """
  Validate that all dependencies reference existing campaigns.
  """
  @spec validate_dependencies([campaign_spec()]) :: :valid | {:invalid_deps, map()}
  def validate_dependencies(campaigns) do
    campaign_ids = MapSet.new(Enum.map(campaigns, & &1.campaign_id))
    
    invalid = Enum.reduce(campaigns, %{}, fn campaign, acc ->
      missing_deps = Enum.filter(campaign.dependencies, fn dep ->
        not MapSet.member?(campaign_ids, dep)
      end)
      
      if Enum.empty?(missing_deps) do
        acc
      else
        Map.put(acc, campaign.campaign_id, missing_deps)
      end
    end)
    
    if Enum.empty?(invalid) do
      :valid
    else
      {:invalid_deps, invalid}
    end
  end

  # Private Functions

  defp build_adjacency_list(campaigns) do
    Enum.reduce(campaigns, %{}, fn campaign, acc ->
      Map.put(acc, campaign.campaign_id, campaign.dependencies)
    end)
  end

  defp has_cycle?(node, adj_list, visited, rec_stack, path) do
    visited = MapSet.put(visited, node)
    rec_stack = MapSet.put(rec_stack, node)
    path = [node | path]
    
    neighbors = Map.get(adj_list, node, [])
    
    Enum.find_value(neighbors, false, fn neighbor ->
      cond do
        not MapSet.member?(visited, neighbor) ->
          has_cycle?(neighbor, adj_list, visited, rec_stack, path)
        
        MapSet.member?(rec_stack, neighbor) ->
          # Found cycle - return cycle path
          cycle_start = Enum.find_index(path, fn n -> n == neighbor end)
          cycle = Enum.slice(path, cycle_start..-1//1) |> Enum.reverse()
          {node, cycle}
        
        true ->
          false
      end
    end)
  end

  defp calculate_in_degrees(campaigns) do
    # Initialize all nodes with degree 0
    degrees = Enum.reduce(campaigns, %{}, fn campaign, acc ->
      Map.put(acc, campaign.campaign_id, 0)
    end)
    
    # Count incoming edges
    Enum.reduce(campaigns, degrees, fn campaign, acc ->
      Enum.reduce(campaign.dependencies, acc, fn dep, inner_acc ->
        Map.update(inner_acc, dep, 1, &(&1 + 1))
      end)
    end)
  end

  defp assign_phases([], _campaigns, _in_degrees, phases, _phase_num) do
    Enum.reverse(phases)
  end

  defp assign_phases(queue, campaigns, in_degrees, phases, phase_num) do
    # Current phase is the queue
    current_phase = Enum.sort(queue)
    
    # Get all nodes in current phase
    campaign_map = Enum.into(campaigns, %{}, fn c -> {c.campaign_id, c} end)
    
    # Calculate new in-degrees after removing current phase nodes
    new_in_degrees = Enum.reduce(queue, in_degrees, fn node, acc ->
      # Remove this node
      acc = Map.delete(acc, node)
      
      # Decrease in-degree of neighbors
      neighbors = get_dependents(node, campaign_map)
      Enum.reduce(neighbors, acc, fn neighbor, inner_acc ->
        Map.update(inner_acc, neighbor, 0, &(&1 - 1))
      end)
    end)
    
    # Next queue is nodes with in-degree 0
    next_queue = new_in_degrees
    |> Enum.filter(fn {_id, degree} -> degree == 0 end)
    |> Enum.map(fn {id, _} -> id end)
    
    assign_phases(next_queue, campaigns, new_in_degrees, [current_phase | phases], phase_num + 1)
  end

  defp get_dependents(node_id, campaign_map) do
    campaign_map
    |> Enum.filter(fn {_id, campaign} ->
      node_id in campaign.dependencies
    end)
    |> Enum.map(fn {id, _} -> id end)
  end

  defp calculate_max_concurrency(phases) do
    phases
    |> Enum.map(&length/1)
    |> Enum.max(fn -> 0 end)
  end
end
