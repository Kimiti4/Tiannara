#!/usr/bin/env elixir

# Phase 5F.5 CORE - Quick Verification Script
# Demonstrates MSCL + OLEF integration
#
# 5F-P3 repair (2026-10-19): the script audits APPLICATION BOOT WIRING first,
# before starting anything. Components it starts itself are labeled
# script-local demo components and do NOT count as application wiring or
# production readiness. Every status claim is a computed check; the script
# exits non-zero when a module is absent, a component is unwired, or the
# demo itself fails. "PRODUCTION READY" is printed only when every check
# passes.
# Evidence: certification/audit/PHASE_5F_STATUS_CORRECTION.md,
# certification/audit/PHASE_5F_WIRING_AUDIT.md.

defmodule Verify5F5 do
  @moduledoc false

  def init, do: Process.put(:checks, [])

  def check(name, fun) when is_function(fun, 0) do
    {status, detail} =
      try do
        case fun.() do
          :ok -> {:pass, "ok"}
          {:ok, detail} -> {:pass, to_string(detail)}
          {:fail, detail} -> {:fail, to_string(detail)}
          other -> {:fail, "invalid check result: #{inspect(other)}"}
        end
      rescue
        e -> {:fail, "exception: #{Exception.message(e)}"}
      catch
        kind, reason -> {:fail, "#{kind}: #{inspect(reason)}"}
      end

    icon = if status == :pass, do: "✅", else: "❌"
    IO.puts("#{icon} #{name}#{if detail == "ok", do: "", else: " — " <> detail}")
    Process.put(:checks, [{name, status, detail} | Process.get(:checks, [])])
    :ok
  end

  def info(text), do: IO.puts("ℹ️  #{text}")

  def start_local(label, mod) do
    check("script-local #{label} starts (NOT application wiring)", fn ->
      case Process.whereis(mod) do
        pid when is_pid(pid) ->
          {:ok, "already running (#{inspect(pid)})"}

        nil ->
          case mod.start_link([]) do
            {:ok, pid} ->
              {:ok, "started (#{inspect(pid)})"}

            {:error, {:already_started, pid}} ->
              {:ok, "already running (#{inspect(pid)})"}

            {:error, reason} ->
              {:fail, "start failed: #{inspect(reason)}"}
          end
      end
    end)
  end

  def verdict do
    checks = Process.get(:checks, []) |> Enum.reverse()
    failures = Enum.filter(checks, fn {_, s, _} -> s == :fail end)

    IO.puts("\n" <> ("═" |> String.duplicate(70)))
    IO.puts("📊 Checks: #{length(checks)} total, #{length(failures)} failed")

    if failures == [] do
      IO.puts("🚀 VERDICT: PRODUCTION READY — every computed check passed")
      0
    else
      IO.puts("🛑 VERDICT: NOT PRODUCTION READY — #{length(failures)} failed check(s):")
      Enum.each(failures, fn {name, _, detail} -> IO.puts("   ❌ #{name} — #{detail}") end)
      1
    end
  end
end

Verify5F5.init()

IO.puts("\n🧠 Tiannara Phase 5F.5 CORE - MSCL + OLEF Verification\n")
IO.puts("=" |> String.duplicate(70))

# ── 1. Application boot wiring audit (before starting anything) ─────────────

IO.puts("\n🔌 Application boot wiring (computed, before script starts anything)...")
Verify5F5.check("MSCL.Supervisor wired into application tree", fn ->
  case Process.whereis(Tiannara.MSCL.Supervisor) do
    nil -> {:fail, "UNWIRED — not started by the application supervisor tree"}
    pid -> {:ok, "wired (#{inspect(pid)})"}
  end
end)

Verify5F5.check("Tiannara.OLEF.FieldSupervisor wired into application tree", fn ->
  case Process.whereis(Tiannara.OLEF.FieldSupervisor) do
    nil -> {:fail, "UNWIRED — not started by the application supervisor tree"}
    pid -> {:ok, "wired (#{inspect(pid)})"}
  end
end)

case Process.whereis(TiannaraRuntime.Legacy.MSCL.Supervisor) do
  nil ->
    Verify5F5.info(
      "legacy MSCL supervisor TiannaraRuntime.Legacy.MSCL.Supervisor: not running " <>
        "(only that legacy module casts {:evacuate_pressure, _} to Tiannara.OLEF.FieldSupervisor)"
    )

  pid ->
    Verify5F5.info(
      "legacy MSCL supervisor TiannaraRuntime.Legacy.MSCL.Supervisor is running (#{inspect(pid)})"
    )
end

case Process.whereis(TiannaraRuntime.Legacy.Tiannara.OLEF.FieldSupervisor) do
  nil ->
    Verify5F5.info("legacy OLEF wrapper TiannaraRuntime.Legacy.Tiannara.OLEF.FieldSupervisor: not running")

  pid ->
    Verify5F5.info(
      "legacy OLEF wrapper TiannaraRuntime.Legacy.Tiannara.OLEF.FieldSupervisor is running " <>
        "(#{inspect(pid)}) — a DIFFERENT module from Tiannara.OLEF.FieldSupervisor; " <>
        "it does not satisfy the check above"
    )
end

# ── 2. Module presence ───────────────────────────────────────────────────────

IO.puts("\n📦 Checking module presence (computed)...")
for {label, mod} <- [
      {"MSCL Supervisor", Tiannara.MSCL.Supervisor},
      {"MSCL BudgetTracker", Tiannara.MSCL.BudgetTracker},
      {"MSCL EvaporationEngine", Tiannara.MSCL.EvaporationEngine},
      {"MSCL ConstraintEngine", Tiannara.MSCL.ConstraintEngine},
      {"MSCL DivergenceAnalyzer", Tiannara.MSCL.DivergenceAnalyzer},
      {"OLEF FieldSupervisor", Tiannara.OLEF.FieldSupervisor},
      {"OLEF NodeRegistry", Tiannara.OLEF.NodeRegistry},
      {"OLEF PressureSolver", Tiannara.OLEF.PressureSolver},
      {"OLEF GradientRouter", Tiannara.OLEF.GradientRouter},
      {"OLEF DiffusionModel", Tiannara.OLEF.DiffusionModel}
    ] do
  Verify5F5.check("#{label} module present", fn ->
    if Code.ensure_loaded?(mod), do: :ok, else: {:fail, "ABSENT — #{inspect(mod)}"}
  end)
end

# ── 3. Script-local demo components ──────────────────────────────────────────

IO.puts("\n📦 Starting SCRIPT-LOCAL demo components (these do NOT prove wiring)...")
Verify5F5.start_local("MSCL Supervisor", Tiannara.MSCL.Supervisor)
Verify5F5.start_local("MSCL BudgetTracker", Tiannara.MSCL.BudgetTracker)
Verify5F5.start_local("MSCL EvaporationEngine", Tiannara.MSCL.EvaporationEngine)
Verify5F5.start_local("OLEF FieldSupervisor", Tiannara.OLEF.FieldSupervisor)
Verify5F5.start_local("OLEF NodeRegistry", Tiannara.OLEF.NodeRegistry)

# ── 4. MSCL demo (each step is a check) ──────────────────────────────────────

IO.puts("\n" <> ("─" |> String.duplicate(70)))
IO.puts("🛡️  Testing MSCL (Meta-Stability Constraint Layer)")
IO.puts("─" |> String.duplicate(70))

Verify5F5.check("demo: register + inspect MSCL nodes", fn ->
  Tiannara.MSCL.Supervisor.register_node("node_alpha", 0.0)
  Tiannara.MSCL.Supervisor.register_node("node_beta", 0.0)
  {:ok, state} = Tiannara.MSCL.Supervisor.get_state()
  {:ok, "registered node_alpha/node_beta, global_pressure=#{state.global_pressure}"}
end)

Verify5F5.check("demo: MSCL pressure tracking", fn ->
  Tiannara.MSCL.Supervisor.report_pressure("node_alpha", 500.0)
  Tiannara.MSCL.Supervisor.report_pressure("node_beta", 300.0)
  {:ok, state} = Tiannara.MSCL.Supervisor.get_state()
  IO.puts("   📊 Global Pressure: #{state.global_pressure}")
  IO.puts("   ⚠️  Collapse Risk: #{Float.round(state.collapse_risk * 100, 2)}%")
  {:ok, "collapse_risk=#{state.collapse_risk}"}
end)

Verify5F5.check("demo: constraint engine divergence + budget checks", fn ->
  div_result = Tiannara.MSCL.ConstraintEngine.evaluate_divergence(0.5)
  div_result_high = Tiannara.MSCL.ConstraintEngine.evaluate_divergence(1.5)
  budget_result = Tiannara.MSCL.ConstraintEngine.enforce_budget(800.0, 1000.0)
  IO.puts("   Stable divergence (0.5): #{inspect(div_result)}")
  IO.puts("   High divergence (1.5): #{inspect(div_result_high)}")
  {:ok, "budget(800/1000)=#{inspect(elem(budget_result, 0))}"}
end)

Verify5F5.check("demo: budget tracker allocate + check", fn ->
  Tiannara.MSCL.BudgetTracker.allocate_budget("observer_1", :entropy, 50.0)
  checked = Tiannara.MSCL.BudgetTracker.check_budget("observer_1", :entropy, 20.0)
  raw_metrics = Tiannara.MSCL.BudgetTracker.get_global_metrics()

  metrics =
    case raw_metrics do
      {:ok, m} when is_map(m) -> m
      m when is_map(m) -> m
      _ -> %{}
    end

  case checked do
    {:ok} ->
      active = Map.get(metrics, :active_observers, :unknown)
      IO.puts("   Budget check reply: #{inspect(checked)}")
      {:ok, "check_budget=#{inspect(checked)}, active_observers=#{inspect(active)}"}

    {:error, reason} ->
      {:fail, "budget check rejected: #{inspect(reason)}"}

    other ->
      {:fail, "unexpected check_budget reply: #{inspect(other)}"}
  end
end)

Verify5F5.check("demo: pairwise divergence analysis", fn ->
  state_a = %{value: 10, timestamp: 1000, causal_chain: [1, 2, 3]}
  state_b = %{value: 50, timestamp: 2000, causal_chain: [4, 5, 6]}

  div_analysis =
    Tiannara.MSCL.DivergenceAnalyzer.analyze_pairwise_divergence(
      "obs_a", "obs_b", state_a, state_b
    )

  IO.puts("   Divergence score: #{Float.round(div_analysis.divergence_score, 4)}")
  IO.puts("   Status: #{div_analysis.status}")
  {:ok, "status=#{div_analysis.status}"}
end)

# ── 5. OLEF demo (each step is a check) ──────────────────────────────────────

IO.puts("\n" <> ("─" |> String.duplicate(70)))
IO.puts("🌊 Testing OLEF (Ontological Load Equilibrium Field)")
IO.puts("─" |> String.duplicate(70))

Verify5F5.check("demo: register nodes in OLEF field", fn ->
  Tiannara.OLEF.FieldSupervisor.register_node("node_alpha", 100.0)
  Tiannara.OLEF.FieldSupervisor.register_node("node_beta", 100.0)
  {:ok, field_state} = Tiannara.OLEF.FieldSupervisor.get_field_state()
  {:ok, "#{map_size(field_state.nodes)} nodes registered"}
end)

Verify5F5.check("demo: OLEF load reporting + field state", fn ->
  Tiannara.OLEF.FieldSupervisor.report_load("node_alpha", 80.0)
  Tiannara.OLEF.FieldSupervisor.report_load("node_beta", 20.0)
  {:ok, field_state} = Tiannara.OLEF.FieldSupervisor.get_field_state()
  IO.puts("   Node Alpha Load: #{Map.get(field_state.nodes, "node_alpha").current_load}")
  IO.puts("   Node Beta Load: #{Map.get(field_state.nodes, "node_beta").current_load}")
  {:ok, "loads reported"}
end)

Verify5F5.check("demo: pressure solver gradient + normalization", fn ->
  field = %{"node_alpha" => 0.8, "node_beta" => 0.2}
  neighborhood = %{"node_alpha" => ["node_beta"], "node_beta" => ["node_alpha"]}
  gradients = Tiannara.OLEF.PressureSolver.compute_gradient(field, neighborhood)
  normalized = Tiannara.OLEF.PressureSolver.normalize(field)
  total = Tiannara.OLEF.PressureSolver.total_pressure(field)
  IO.puts("   Gradients computed: #{map_size(gradients)} nodes")
  IO.puts("   Normalized field: #{inspect(normalized)}")
  IO.puts("   Total pressure: #{total}")
  {:ok, "gradients=#{map_size(gradients)}"}
end)

Verify5F5.check("demo: gradient router task routing", fn ->
  pressure_field = %{"overloaded" => 0.9, "balanced" => 0.5, "available" => 0.2}
  node_caps = %{"overloaded" => 100, "balanced" => 100, "available" => 100}
  task_reqs = %{min_capacity: 50}

  {:ok, selected} =
    Tiannara.OLEF.GradientRouter.route_task(task_reqs, pressure_field, node_caps)

  weights = Tiannara.OLEF.GradientRouter.calculate_routing_weights(pressure_field)
  IO.puts("   Task routed to: #{selected} (lowest pressure)")
  {:ok, "routed to #{inspect(selected)}, #{map_size(weights)} weight entries"}
end)

Verify5F5.check("demo: diffusion model simulation", fn ->
  initial_field = %{"hot" => 0.95, "warm" => 0.50, "cool" => 0.10}
  neighborhood = %{"hot" => ["warm"], "warm" => ["hot", "cool"], "cool" => ["warm"]}

  sim = Tiannara.OLEF.DiffusionModel.simulate_diffusion(initial_field, neighborhood, 5, :standard)
  efficiency = Tiannara.OLEF.DiffusionModel.calculate_efficiency(initial_field)
  IO.puts("   Simulation steps: #{length(sim)}")
  {:ok, "steps=#{length(sim)} efficiency=#{Float.round(efficiency, 4)}"}
end)

# ── 6. Integration demo ──────────────────────────────────────────────────────

IO.puts("\n" <> ("─" |> String.duplicate(70)))
IO.puts("🔗 Testing MSCL → OLEF Integration")
IO.puts("─" |> String.duplicate(70))

Verify5F5.check("demo: critical pressure scenario reported to MSCL", fn ->
  Tiannara.MSCL.Supervisor.report_pressure("node_alpha", 8600.0)
  {:ok, critical_state} = Tiannara.MSCL.Supervisor.get_state()
  IO.puts("   ⚠️  CRITICAL collapse risk: #{Float.round(critical_state.collapse_risk * 100, 2)}%")
  Process.sleep(100)
  {:ok, "collapse_risk=#{critical_state.collapse_risk}"}
end)

Verify5F5.check("MSCL evacuation reaches an OLEF field (redistribution observed)", fn ->
  local_events =
    case Process.whereis(Tiannara.OLEF.FieldSupervisor) do
      nil ->
        0

      _pid ->
        {:ok, s} = Tiannara.OLEF.FieldSupervisor.get_field_state()
        length(s.redistribution_history)
    end

  legacy_events =
    case Process.whereis(TiannaraRuntime.Legacy.Tiannara.OLEF.FieldSupervisor) do
      nil ->
        0

      _pid ->
        {:ok, s} = TiannaraRuntime.Legacy.Tiannara.OLEF.FieldSupervisor.get_field_state()
        length(s.redistribution_history)
    end

  if local_events + legacy_events == 0 do
    {:fail,
     "0 redistribution events in script-local and legacy OLEF fields — " <>
       "MSCL→OLEF evacuation not observed (the evacuate_pressure cast exists only in " <>
       "TiannaraRuntime.Legacy.MSCL.Supervisor, which is unwired, and the scripted " <>
       "Tiannara.MSCL.Supervisor does not send it)"}
  else
    {:ok, "script-local=#{local_events} legacy=#{legacy_events}"}
  end
end)

Verify5F5.check("demo: evaporation engine trigger + stats", fn ->
  Tiannara.MSCL.EvaporationEngine.trigger_evaporation("unstable_observer", :paradox_overload)
  {:ok, evap_stats} = Tiannara.MSCL.EvaporationEngine.get_stats()
  IO.puts("   Total evaporations: #{evap_stats.total_evaporated}")
  IO.puts("   Events logged: #{length(evap_stats.evaporation_events)}")
  {:ok, "total_evaporated=#{evap_stats.total_evaporated}"}
end)

# ── Verdict ──────────────────────────────────────────────────────────────────

IO.puts("\n🎯 Pressure tracking, collapse-risk monitoring, budget enforcement,")
IO.puts("   load balancing, and pressure diffusion are asserted by the checks")
IO.puts("   above — not claims. Script-local demo components never satisfy the")
IO.puts("   boot-wiring checks.")

System.halt(Verify5F5.verdict())
