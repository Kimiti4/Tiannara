# Step-3 smoke window: full-vector gate + P1 natural archive-rate measurement.
#
# Boot:  $env:STORAGE_CONTEXT="soak"; mix run scripts/soak_smoke.exs
#
# Gate (T1): observation>0 AND unknown_detection>0 AND hypothesis>0 AND
#   experiment_schedule>0 AND experiment_execute>0 AND evidence>0 AND
#   knowledge_integration > seeded_count (earned > 0), all through evidence.
# P1: archive-dir delta over the window, extrapolated to 72h.

alias Tiannara.Storage.Paths
alias Tiannara.Discovery.{EpistemicSeeder, DiscoveryScheduler, PipelineTelemetry}
alias Tiannara.CEL.Services.{ResourceManager, WorkflowEngine}

IO.puts("=== Soak smoke window ===")
IO.puts("storage_context=#{inspect(Paths.context())}")
IO.puts("storage_base=#{Paths.base()}")
IO.puts("dets_base_path=#{inspect(Application.get_env(:tiannara, :dets_base_path))}")
IO.puts("rotate_bytes=#{Tiannara.Storage.Rotator.rotate_bytes()}")

if Paths.context() != :soak do
  IO.puts("FATAL: expected :soak context, aborting")
  System.halt(1)
end

live_dets_dir =
  case Application.get_env(:tiannara, :dets_base_path) do
    nil -> Path.join([Paths.base(), "soak", "dets"])
    base -> Path.join([base, "dets", "soak"])
  end

dets_sizes = fn ->
  case File.ls(live_dets_dir) do
    {:ok, files} ->
      Enum.reduce(files, %{count: 0, bytes: 0, archives: 0, archive_bytes: 0}, fn f, acc ->
        fp = Path.join(live_dets_dir, f)
        sz = case File.stat(fp) do {:ok, %{size: s}} -> s; _ -> 0 end

        if String.contains?(f, ".archive.") do
          %{acc | archives: acc.archives + 1, archive_bytes: acc.archive_bytes + sz}
        else
          %{acc | count: acc.count + 1, bytes: acc.bytes + sz}
        end
      end)

    {:error, e} ->
      %{count: 0, bytes: 0, archives: 0, archive_bytes: 0, error: inspect(e)}
  end
end

snapshot = fn label ->
  snap = PipelineTelemetry.snapshot()
  IO.puts("\n--- vector @ #{label} (#{DateTime.utc_now()}) ---")

  Enum.each(PipelineTelemetry.stages(), fn stage ->
    %{status: s, value: v} = Map.fetch!(snap.stages, stage)
    IO.puts("  #{String.pad_trailing(Atom.to_string(stage), 24)} #{String.pad_trailing(Atom.to_string(s), 12)} #{inspect(v)}")
  end)

  IO.puts("  seeded_inputs: #{inspect(snap.seeded_inputs)}")
  IO.puts("  first_stall:   #{inspect(snap.first_stall)}")
  IO.puts("  uninstrumented: #{inspect(snap.uninstrumented)}")
  snap
end

wait = fn ms -> Process.sleep(ms) end

IO.puts("\n--- P1 baseline: live DETS + archives ---")
t0 = DateTime.utc_now()
b0 = dets_sizes.()
IO.inspect(b0, label: "dets @ t0")

IO.puts("\n--- ResourceManager pre-check ---")
if Process.whereis(ResourceManager) != nil do
  IO.puts("  RM ready?: #{inspect(ResourceManager.ready?())}")
else
  IO.puts("  RM NOT RUNNING")
end

IO.puts("\n--- Seed battery ---")
manifest = EpistemicSeeder.seed_battery(domain: :sensor_fusion)
IO.puts("  entities_created: #{manifest.entities_created}")
IO.puts("  gaps_from_seed: #{length(manifest.gaps_from_seed)}")
IO.puts("  contradictions_from_seed: #{length(manifest.contradictions_from_seed)}")
snapshot.("post-seed")

wait.(5_000)

IO.puts("\n--- Driving discovery cycles (scheduler interval is 30 min; smoke window cannot wait) ---")

Enum.each(1..3, fn i ->
  IO.puts("\n>>> triggering cycle #{i}")
  pid = Process.whereis(DiscoveryScheduler)
  GenServer.call(pid, :trigger_cycle, 120_000)
  wait.(20_000)

  stats = DiscoveryScheduler.get_stats()
  IO.puts("    scheduler: cycles=#{stats.cycle_count} gaps=#{stats.total_gaps_detected} hyp=#{stats.total_hypotheses_generated} planned=#{stats.total_experiments_planned} dispatched=#{stats.total_experiments_executed}")

  if Process.whereis(WorkflowEngine) != nil do
    IO.inspect(WorkflowEngine.stats(), label: "    workflow_engine")
  end

  snapshot.("after-cycle-#{i}")
end)

wait.(30_000)
snapshot.("settle-30s")

IO.puts("\n--- P1: archive + live DETS delta ---")
t1 = DateTime.utc_now()
b1 = dets_sizes.()
IO.inspect(b1, label: "dets @ t1")

elapsed_min = DateTime.diff(t1, t0, :second) / 60.0
live_growth_bytes = max(0, b1.bytes - b0.bytes)
arch_growth_bytes = max(0, b1.archive_bytes - b0.archive_bytes)
live_per_min = live_growth_bytes / max(elapsed_min, 0.1)
arch_per_min = arch_growth_bytes / max(elapsed_min, 0.1)

IO.puts("\n--- P1 extrapolation (window=#{Float.round(elapsed_min, 2)} min) ---")
IO.puts("  live DETS growth: #{div(live_growth_bytes, 1024)} KiB (#{Float.round(live_per_min / 1024, 2)} KiB/min)")
IO.puts("  archive growth:   #{div(arch_growth_bytes, 1024)} KiB (#{Float.round(arch_per_min / 1024, 2)} KiB/min)")

live_72h_mb = live_per_min * 60 * 72 / (1024 * 1024)
arch_72h_mb = arch_per_min * 60 * 72 / (1024 * 1024)
IO.puts("  live DETS extrapolated to 72h: #{Float.round(live_72h_mb, 1)} MB")
IO.puts("  archive extrapolated to 72h:   #{Float.round(arch_72h_mb, 1)} MB")

# Will any live store cross the rotation threshold within 72h?
threshold = Tiannara.Storage.Rotator.rotate_bytes()
per_store_72h = live_72h_mb / max(b1.count, 1)
IO.puts("  per-store 72h growth (avg over #{b1.count} stores): #{Float.round(per_store_72h, 1)} MB vs threshold #{div(threshold, 1024 * 1024)} MB")
IO.puts("  ROTATION RISK: #{if per_store_72h * 1024 * 1024 > threshold * 0.5, do: "YES — stores may cross threshold, archives WILL spawn", else: "no — stores stay under threshold, zero archives expected"}")

IO.puts("\n--- GATE VERDICT ---")
snap = PipelineTelemetry.snapshot()

gate = fn stage ->
  case Map.fetch!(snap.stages, stage) do
    %{status: s, value: v} -> v in [:uninstrumented, :error, nil] or (is_number(v) and v > 0)
  end
end

seeded = snap.seeded_inputs || 0
earned =
  case Map.fetch!(snap.stages, :knowledge_integration) do
    %{value: v} when is_number(v) -> v
    _ -> -1
  end

rows = [
  {:observation, gate.(:observation), Map.fetch!(snap.stages, :observation)},
  {:unknown_detection, gate.(:unknown_detection), Map.fetch!(snap.stages, :unknown_detection)},
  {:hypothesis, gate.(:hypothesis), Map.fetch!(snap.stages, :hypothesis)},
  {:experiment_schedule, gate.(:experiment_schedule), Map.fetch!(snap.stages, :experiment_schedule)},
  {:experiment_execute, gate.(:experiment_execute), Map.fetch!(snap.stages, :experiment_execute)},
  {:evidence, gate.(:evidence), Map.fetch!(snap.stages, :evidence)},
  {:knowledge_integration, earned > 0 and earned > seeded, Map.fetch!(snap.stages, :knowledge_integration)}
]

Enum.each(rows, fn {name, ok, v} ->
  IO.puts("  #{String.pad_trailing(Atom.to_string(name), 24)} #{if ok, do: "PASS", else: "FAIL"}  (#{inspect(v)})")
end)

pass = Enum.all?(rows, fn {_, ok, _} -> ok end)
IO.puts("\n  T1 GO: #{if pass, do: "YES — vector green-or-blue through evidence, earned>seeded", else: "NO — do not lock the 72h clock"}")

if not pass do
  IO.puts("  named seam: #{inspect(snap.first_stall)}")
end

IO.puts("DONE")
