defmodule Tiannara.Observability do
  @moduledoc """
  In-process observability probes for the Tiannara main app.

  Used by the soak test engine and by the `/api/v1/runtime/snapshot` and
  `/api/v1/discovery/snapshot` endpoints.

  Caveats (disclosed, not hidden):
    * The monitor runs inside the system it watches. If Tiannara dies,
      the monitor dies with it — it cannot report on its own death.
    * The monitor's own footprint is included in the numbers it reports.
  """

  alias Tiannara.ControlCenter
  alias Tiannara.Discovery.DiscoveryScheduler
  alias Tiannara.World.UnifiedWorldModel

  @doc "Runtime memory, process, run-queue and subsystem-health snapshot."
  def runtime_snapshot do
    runtime = %{
      memory_mb: memory_mb(),
      process_count: process_count(),
      run_queue: run_queue(),
      uptime_seconds: uptime_seconds(),
      at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    runtime
    |> Map.merge(subsystem_snapshot())
  rescue
    _ ->
      %{
        memory_mb: 0.0,
        process_count: 0,
        run_queue: 0,
        uptime_seconds: 0,
        subsystems_healthy: 0,
        subsystems_total: 0,
        all_healthy: false,
        probe: :error,
        at: DateTime.utc_now() |> DateTime.to_iso8601()
      }
  end

  @doc "Discovery pipeline snapshot: scheduler liveness and cumulative discovery counters."
  def discovery_snapshot do
    stats = safe_get(DiscoveryScheduler, :get_stats)
    world = safe_get(UnifiedWorldModel, :stats)
    type_counts = Map.get(world, :entity_type_distribution, %{})

    %{
      scheduler_alive: Process.whereis(DiscoveryScheduler) != nil,
      discovery_cycles: Map.get(stats, :completed_cycles, Map.get(stats, :cycle_count, 0)),
      gaps_detected: Map.get(stats, :total_gaps_detected, 0),
      hypotheses_generated: Map.get(stats, :total_hypotheses_generated, 0),
      knowledge_entities:
        Map.get(type_counts, :knowledge_entity, Map.get(type_counts, "knowledge_entity", 0)),
      world_entities: Map.get(world, :entity_count, Map.get(world, :total_entities, 0)),
      at: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  rescue
    _ ->
      %{
        scheduler_alive: false,
        discovery_cycles: 0,
        gaps_detected: 0,
        hypotheses_generated: 0,
        knowledge_entities: 0,
        world_entities: 0,
        probe: :error,
        at: DateTime.utc_now() |> DateTime.to_iso8601()
      }
  end

  @doc """
  Interprets a discovery snapshot (or a fresh one) into an honest status label.

  No hard "discoveries > 0" pass criterion here: zero new knowledge entities is
  correct behaviour when no gaps exist.
  """
  def discovery_interpretation(snapshot \\ nil) do
    snapshot = snapshot || discovery_snapshot()

    cond do
      not Map.get(snapshot, :scheduler_alive, false) ->
        %{
          status: :scheduler_down,
          label: "Discovery scheduler is not running",
          details: "DiscoveryScheduler process is absent — discovery pipeline cannot cycle"
        }

      Map.get(snapshot, :discovery_cycles, 0) == 0 ->
        %{
          status: :no_cycles,
          label: "No discovery cycles completed yet",
          details: "Scheduler is alive but has not completed a discovery cycle"
        }

      Map.get(snapshot, :gaps_detected, 0) > 0 and Map.get(snapshot, :knowledge_entities, 0) == 0 ->
        %{
          status: :possible_stall,
          label: "Gaps found but nothing synthesized",
          details:
            "#{Map.get(snapshot, :gaps_detected, 0)} gaps detected yet 0 knowledge entities — investigation warranted"
        }

      Map.get(snapshot, :knowledge_entities, 0) > 0 ->
        %{
          status: :active,
          label: "Discovery pipeline producing knowledge",
          details:
            "#{Map.get(snapshot, :knowledge_entities, 0)} knowledge entities in the world model"
        }

      true ->
        %{
          status: :healthy_quiet,
          label: "Discovery healthy and quiet",
          details: "Cycles running, no gaps — zero new entities is correct, not a failure"
        }
    end
  end

  defp memory_mb, do: (:erlang.memory(:total) / 1_048_576) |> Float.round(2)
  defp process_count, do: :erlang.system_info(:process_count)
  defp run_queue, do: :erlang.statistics(:run_queue)

  defp uptime_seconds do
    safe_get(ControlCenter, :uptime)
    |> case do
      v when is_integer(v) -> v
      _ -> 0
    end
  end

  defp subsystem_snapshot do
    status = safe_get(ControlCenter, :status)

    case status do
      s when is_map(s) ->
        %{
          subsystems_healthy: Map.get(s, :healthy, 0),
          subsystems_total: Map.get(s, :total, 0),
          all_healthy:
            Map.get(s, :total, 0) > 0 and Map.get(s, :healthy, 0) == Map.get(s, :total, 0)
        }

      _ ->
        %{
          subsystems_healthy: 0,
          subsystems_total: 0,
          all_healthy: false,
          subsystem_probe: :unavailable
        }
    end
  end

  defp safe_get(mod, fun) do
    if Code.ensure_loaded?(mod) and Process.whereis(mod) != nil do
      apply(mod, fun, [])
    else
      :unavailable
    end
  rescue
    _ -> :unavailable
  catch
    :exit, _ -> :unavailable
  end
end
