defmodule TiannaraRuntime.WorldModel.DigitalTwin.Engines.InterventionScheduler do
  @moduledoc """
  Phase 17.7.4 — InterventionScheduler engine.
  Manages the scheduling and execution of interventions: immediate, delayed, conditional, recurring, adaptive.
  """

  alias TiannaraRuntime.WorldModel.DigitalTwin.ScheduledIntervention

  @doc """
  Schedules interventions for a simulation scenario.
  Returns {:ok, [ScheduledIntervention.t()]} or {:error, reason}.
  """
  def schedule(interventions) do
    deps = build_dependency_graph(interventions)
    ordered = topological_order(interventions, deps)

    case ordered do
      {:ok, sorted} -> {:ok, sorted}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Returns interventions due at a given tick.
  """
  def due_interventions(interventions, tick) do
    Enum.filter(interventions, fn si ->
      case si.schedule_type do
        :immediate -> si.trigger_tick == tick
        :delayed -> si.trigger_tick == tick
        :conditional -> si.trigger_tick == tick
        :recurring ->
          si.trigger_tick == tick ||
            (si.trigger_tick < tick && rem(tick - si.trigger_tick, si.recurrence || 1) == 0)
        :adaptive -> false
      end
    end)
  end

  @doc """
  Applies an intervention to the twin state.
  """
  def apply_intervention(intervention, twin_state) do
    target = intervention.intervention["target"] || intervention.intervention[:target]
    value = intervention.intervention["value"] || intervention.intervention[:value]
    field = intervention.intervention["field"] || intervention.intervention[:field]

    new_states =
      Map.update(twin_state.model_states, target, %{}, fn existing ->
        existing =
          if value != nil and field != nil do
            Map.put(existing, field, value)
          else
            if value != nil do
              Map.put(existing, "value", value)
            else
              existing
            end
          end

        Map.put(existing, "modified_by", intervention.scheduled_id)
      end)

    %{twin_state | model_states: new_states}
  end

  defp build_dependency_graph(interventions) do
    Enum.reduce(interventions, %{}, fn si, graph ->
      deps = si.dependencies || []
      Map.put(graph, si.scheduled_id, deps)
    end)
  end

  defp topological_order(interventions, deps) do
    ids = MapSet.new(interventions, & &1.scheduled_id)

    cycle = detect_cycle(deps, ids)
    if cycle != [] do
      {:error, :cyclic_dependency, cycle}
    else
      sorted = Enum.sort_by(interventions, fn si ->
        {si.trigger_tick || 0, length(Map.get(deps, si.scheduled_id, []))}
      end)
      {:ok, sorted}
    end
  end

  defp detect_cycle(deps, all_ids) do
    visited = MapSet.new()
    rec_stack = MapSet.new()

    result = Enum.reduce_while(all_ids, :no_cycle, fn id, _acc ->
      if MapSet.member?(visited, id) do
        {:cont, :no_cycle}
      else
        case dfs_cycle(id, deps, visited, rec_stack, []) do
          {:ok, new_visited, _} ->
            visited = new_visited
            {:cont, :no_cycle}
          {:error, cycle} ->
            {:halt, {:cycle, cycle}}
        end
      end
    end)

    case result do
      :no_cycle -> []
      {:cycle, cycle} -> cycle
    end
  end

  defp dfs_cycle(node, deps, visited, rec_stack, path) do
    if MapSet.member?(rec_stack, node) do
      {:error, [node | path]}
    else
      if MapSet.member?(visited, node) do
        {:ok, visited, rec_stack}
      else
        visited = MapSet.put(visited, node)
        rec_stack = MapSet.put(rec_stack, node)
        path = [node | path]

        neighbors = Map.get(deps, node, [])

        result =
          if neighbors == [] do
            {:ok, visited, rec_stack}
          else
            Enum.reduce_while(neighbors, {visited, rec_stack}, fn neighbor, {vis, rec} ->
              case dfs_cycle(neighbor, deps, vis, rec, path) do
                {:ok, new_vis, new_rec} -> {:cont, {new_vis, new_rec}}
                {:error, _} = err -> {:halt, err}
              end
            end)
          end

        case result do
          {:ok, visited, rec_stack} ->
            rec_stack = MapSet.delete(rec_stack, node)
            {:ok, visited, rec_stack}
          {visited, rec_stack} ->
            rec_stack = MapSet.delete(rec_stack, node)
            {:ok, visited, rec_stack}
          {:error, _} = err ->
            err
        end
      end
    end
  end
end
