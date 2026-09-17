defmodule Tiannara.Discovery.SchedulerEvidenceWireTest do
  use ExUnit.Case, async: false

  alias Tiannara.Discovery.{DiscoveryEngine, DiscoveryScheduler, EpistemicSeeder}
  alias Tiannara.World.{UnifiedRealityGraph, UnifiedWorldModel}

  setup do
    Application.ensure_all_started(:tiannara)

    case Tiannara.ControlCenter.start_link([]) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      {:error, _} -> :ok
    end

    wait_until(fn -> Process.whereis(DiscoveryEngine) != nil end, 20_000)
    wait_until(fn -> Process.whereis(DiscoveryScheduler) != nil end, 20_000)
    wait_until(fn -> Process.whereis(Tiannara.CEL.Services.EventBus) != nil end, 20_000)
    :ok
  end

  describe "scheduler evidence wire" do
    test "executed discoveries route experiment evidence into DiscoveryEngine" do
      seed = EpistemicSeeder.seed_battery()
      assert length(seed.entity_ids) >= 1

      world_before = world_counts()

      assert DiscoveryScheduler.trigger_cycle() == :ok

      raw = :sys.get_state(DiscoveryScheduler)

      refute Enum.any?(Map.keys(raw), fn k -> is_binary(k) and String.starts_with?(k, "wf_") end),
             "workflow tracking leaked into top-level state - active_workflows contract broken"

      # Give the cycle + async workflow completion a beat before diagnosing.
      Process.sleep(1_000)

      case wait_for_evidence(20_000) do
        :ok ->
          assert :sys.get_state(DiscoveryScheduler).active_workflows == %{}

        :timeout ->
          flunk(diagnosis(world_before, seed))
      end
    end
  end

  # ── happy-path wait ─────────────────────────────────────

  defp wait_for_evidence(timeout_ms) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    do_wait(deadline)
  end

  defp do_wait(deadline) do
    case scheduler_stats() do
      %{completed_evidence_events: e} when e > 0 ->
        :ok

      _ ->
        if System.monotonic_time(:millisecond) > deadline do
          :timeout
        else
          Process.sleep(100)
          do_wait(deadline)
        end
    end
  end

  # ── one-run localization ────────────────────────────────

  defp diagnosis(world_before, seed) do
    stats = scheduler_stats()

    """
    EVIDENCE WIRE DID NOT CLOSE. Stage-by-stage localization:

      world before:  #{inspect(world_before)}
      world after:   #{inspect(world_counts())}
      seeded ids:    #{inspect(seed.entity_ids)}
      scheduler:     #{inspect(stats)}
      workflow_eng:  up=#{Process.whereis(Tiannara.CEL.Services.WorkflowEngine) != nil}
                     stats=#{inspect(maybe_stats(Tiannara.CEL.Services.WorkflowEngine, :stats))}
      discovery_eng: #{inspect(maybe_stats(DiscoveryEngine, :get_stats))}

    READ IT AS (first matching line is the open joint):
      uwm>0 but urg==0            -> seeds live in UWM but the scheduler's
        fetch_world_entities scans URG, so it sees an EMPTY world => no gaps,
        no dispatch. (Stores disagree; align the write contract.)
      urg>0 but gaps==0           -> world visible, but the integrity report found
        no contradiction; check seeded observations' property keys/values satisfy
        contradiction_pairs/2 (same key, differing values).
      planned>0 but executed==0   -> selection or start_workflow failed; check
        workflow_eng up=true and dispatch_experiment error reasons in the log.
      executed>0 but events==0    -> workflows ran but wf.outcome_evidence is empty;
        the engine is not attaching step evidence on completion.
    """
  end

  defp world_counts, do: %{uwm: uwm_count(), urg: urg_count()}

  defp uwm_count do
    try do
      case UnifiedWorldModel.stats() do
        %{total_entities: n} -> n
        _ -> :unknown
      end
    rescue
      _ -> :down
    catch
      :exit, _ -> :down
    end
  end

  defp urg_count do
    try do
      case UnifiedRealityGraph.query_entities(predicate: fn _ -> true end, limit: 500) do
        {:ok, ids} when is_list(ids) -> length(ids)
        _ -> :unknown
      end
    rescue
      _ -> :down
    catch
      :exit, _ -> :down
    end
  end

  defp scheduler_stats do
    try do
      DiscoveryScheduler.get_stats()
    rescue
      _ -> %{scheduler: :down}
    catch
      :exit, _ -> %{scheduler: :down}
    end
  end

  defp maybe_stats(mod, fun) do
    if Process.whereis(mod) != nil and function_exported?(mod, fun, 0) do
      apply(mod, fun, [])
    else
      :unavailable
    end
  rescue
    _ -> :error
  catch
    :exit, _ -> :error
  end

  defp wait_until(fun, timeout_ms \\ 15_000) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms

    retry = fn retry ->
      if fun.() do
        :ok
      else
        if System.monotonic_time(:millisecond) > deadline do
          flunk("timed out waiting for condition")
        else
          Process.sleep(100)
          retry.(retry)
        end
      end
    end

    retry.(retry)
  end
end
