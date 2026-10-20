defmodule TiannaraRuntime.OmegaRobustnessTest do
  use ExUnit.Case, async: false

  # QUARANTINED (CI-A inventory, baseline e7f81b97): both tests require a
  # privately-owned ConstitutionalPersistenceLayer on a custom storage path,
  # but the application boot tree owns the named CPL process
  # (:already_started). Re-admitting needs an isolation design (stop
  # policy, configurable name, or isolated app instance) — Stage B.
  @moduletag :quarantine

  alias TiannaraRuntime.OS.Persistence.ConstitutionalPersistenceLayer, as: CPL
  alias TiannaraRuntime.Omega

  setup do
    base =
      Path.join(System.tmp_dir!(), "tiannara_omega_test_#{System.unique_integer([:positive])}")

    on_exit(fn -> File.rm_rf(base) end)
    {:ok, base: base}
  end

  test "CPL reloads persisted events and checkpoints without state marker", %{base: base} do
    cpl_path = Path.join(base, "cpl")

    {:ok, pid} = CPL.start_link(storage_path: cpl_path, checkpoint_interval: 60_000)
    assert {:ok, _event} = CPL.record_event(:observation, %{source: "test"})
    assert {:ok, _checkpoint} = CPL.create_checkpoint(:runtime_state, %{healthy: true})
    stats = CPL.get_recovery_stats()
    assert stats.total_events == 1
    assert stats.hash_chain_intact

    GenServer.stop(pid)

    {:ok, pid} = CPL.start_link(storage_path: cpl_path, checkpoint_interval: 60_000)
    reloaded = CPL.get_recovery_stats()

    assert reloaded.total_events == 1
    assert reloaded.total_checkpoints >= 1
    assert reloaded.hash_chain_intact

    GenServer.stop(pid)
  end

  test "Omega supervisor provides readiness primitives without external services", %{base: base} do
    cpl_path = Path.join(base, "cpl")
    memory_path = Path.join(base, "memory")

    start_supervised!({CPL, storage_path: cpl_path, checkpoint_interval: 60_000})

    start_supervised!(
      {Omega.Supervisor,
       heartbeat: [interval: 20],
       scheduler: [jobs: [{:runtime_metrics, 20, :high}]],
       executive_memory: [storage_path: memory_path, checkpoint_interval: 60_000],
       checkpoint_reliability: [interval: 60_000],
       event_store_audit: [interval: 60_000],
       runtime_health: [interval: 60_000]}
    )

    assert Omega.Supervisor.status().heartbeat
    assert :ok = Omega.ExecutiveMemory.put(:active_soak, %{status: :running})
    assert %{status: :running} = Omega.ExecutiveMemory.get(:active_soak)
    assert {:ok, _checkpoint} = Omega.ExecutiveMemory.checkpoint()

    assert :ok = Omega.DependencyIsolation.register(:nats, failure_threshold: 1, cooldown_ms: 30)
    Omega.DependencyIsolation.report_failure(:nats, :unavailable)
    Process.sleep(5)
    refute Omega.DependencyIsolation.available?(:nats)
    Process.sleep(35)
    assert Omega.DependencyIsolation.available?(:nats)

    assert {:ok, _event} =
             Omega.SentinelEventBus.publish(:unknown_observed, %{status: :unknown}, %{test: true})

    Process.sleep(80)

    assert Omega.Heartbeat.status().sequence > 0
    assert Omega.SentinelEventBus.stats().event_count > 0
    assert Omega.ConstitutionalScheduler.status().ticks > 0

    assert %{queued: queued, experiments_enabled: false} =
             Omega.ResearchDirectorReadiness.status()

    assert queued > 0

    assert %{hash_chain_intact: true} = CPL.get_recovery_stats()
  end
end
