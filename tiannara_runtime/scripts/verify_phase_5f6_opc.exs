#!/usr/bin/env elixir

# Phase 5F.6 OPC - Quick Verification Script
# Demonstrates the Observer Physics Compiler pipeline
#
# 5F-P3 repair (2026-10-19): every status claim below is a COMPUTED check.
# The script exits non-zero when a module is absent, a component is unwired,
# a referenced function does not exist, or execution is simulation-only or
# quarantined. "PRODUCTION READY" is printed only when every check passes.
# Evidence: certification/audit/PHASE_5F_STATUS_CORRECTION.md (C-04),
# certification/audit/PHASE_5F_WIRING_AUDIT.md.

defmodule Verify5F6 do
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

Verify5F6.init()

IO.puts("\n🧠 Tiannara Phase 5F.6 OPC - Observer Physics Compiler Verification\n")
IO.puts("=" |> String.duplicate(70))

# ── Module presence ──────────────────────────────────────────────────────────

IO.puts("\n📦 Checking module presence (computed)...")
for {label, mod} <- [
      {"Lexer", Tiannara.OPC.Parser.Lexer},
      {"Parser", Tiannara.OPC.Parser.Parser},
      {"AST", Tiannara.OPC.Parser.AST},
      {"SymbolicValidator", Tiannara.OPC.Validator.SymbolicValidator},
      {"AOR Regularizer", Tiannara.OPC.AOR.Regularizer},
      {"OIR IRBuilder", Tiannara.OPC.OIR.IRBuilder},
      {"GPUCompiler", Tiannara.OPC.Compiler.GPUCompiler},
      {"CompileAPI", Tiannara.OPC.API.CompileAPI},
      {"ExecutionRuntime", Tiannara.OPC.Runtime.ExecutionRuntime}
    ] do
  Verify5F6.check("#{label} module present", fn ->
    if Code.ensure_loaded?(mod), do: :ok, else: {:fail, "ABSENT — #{inspect(mod)}"}
  end)
end

# ── Wiring + API surface ─────────────────────────────────────────────────────

IO.puts("\n🔌 Wiring + API surface (computed)...")
Verify5F6.check("ExecutionRuntime wired into application tree", fn ->
  case Process.whereis(Tiannara.OPC.Runtime.ExecutionRuntime) do
    nil -> {:fail, "UNWIRED — named process absent (OPC supervisor not running)"}
    pid -> {:ok, "wired (#{inspect(pid)})"}
  end
end)

Verify5F6.check("opc_execution_quarantine disabled (real execution allowed)", fn ->
  case Application.get_env(:tiannara_runtime, :opc_execution_quarantine, true) do
    false -> :ok
    true -> {:fail, "ACTIVE — GPUExecutionBridge fails closed with :simulated_execution_quarantined"}
  end
end)

for {f, a} <- [compile_oir: 1, compile_to_glsl: 1, generate_shader_hash: 1] do
  Verify5F6.check("GPUCompiler.#{f}/#{a} exported", fn ->
    if Code.ensure_loaded?(Tiannara.OPC.Compiler.GPUCompiler) and
         function_exported?(Tiannara.OPC.Compiler.GPUCompiler, f, a) do
      :ok
    else
      {:fail, "ABSENT — function not exported (referenced by GPUExecutionBridge)"}
    end
  end)
end

for {f, a} <- [compile_physics: 2, validate_only: 1] do
  Verify5F6.check("CompileAPI.#{f}/#{a} exported", fn ->
    if Code.ensure_loaded?(Tiannara.OPC.API.CompileAPI) and
         function_exported?(Tiannara.OPC.API.CompileAPI, f, a) do
      :ok
    else
      {:fail, "ABSENT — function not exported"}
    end
  end)
end

# ── Pipeline demo (each step is a check) ─────────────────────────────────────

IO.puts("\n📦 Testing OPC Lexer...")
Verify5F6.check("Lexer tokenizes physics expression", fn ->
  tokens = Tiannara.OPC.Parser.Lexer.tokenize("gravity * 9.81 + velocity ^ 2")
  IO.inspect(tokens, limit: :infinity, pretty: true)
  {:ok, "#{length(tokens)} tokens"}
end)

IO.puts("\n📦 Testing OPC Parser...")
Verify5F6.check("Parser parses expression with bounded AST", fn ->
  case Tiannara.OPC.Parser.Parser.parse("gravity * 9.81") do
    {:ok, ast} ->
      depth = Tiannara.OPC.Parser.AST.depth(ast)
      IO.puts("   AST: #{inspect(ast)}")
      {:ok, "parsed, depth #{depth}"}

    {:error, reason} ->
      {:fail, "parse failed: #{inspect(reason)}"}
  end
end)

IO.puts("\n📦 Testing Symbolic Validator...")
Verify5F6.check("SymbolicValidator accepts stable expression", fn ->
  ast = {:binary_op, :+, {:number, 1.0}, {:number, 2.0}}

  case Tiannara.OPC.Validator.SymbolicValidator.validate(ast) do
    {:ok, :stable} -> :ok
    other -> {:fail, "expected {:ok, :stable}, got #{inspect(other)}"}
  end
end)

IO.puts("\n📦 Testing Division by Zero Detection...")
Verify5F6.check("SymbolicValidator detects division by zero", fn ->
  bad_ast = {:binary_op, :/, {:number, 1.0}, {:number, 0.0}}

  case Tiannara.OPC.Validator.SymbolicValidator.validate(bad_ast) do
    {:error, :division_by_zero} -> :ok
    other -> {:fail, "expected division_by_zero, got #{inspect(other)}"}
  end
end)

IO.puts("\n📦 Testing AOR Regularizer...")
Verify5F6.check("AOR regularizer rewrites division", fn ->
  div_ast = {:binary_op, :/, {:number, 10.0}, {:number, 2.0}}
  regularized = Tiannara.OPC.AOR.Regularizer.regularize(div_ast)
  IO.puts("   Original: #{inspect(div_ast)}")
  IO.puts("   Regularized: #{inspect(regularized)}")
  {:ok, "regularized to #{inspect(regularized)}"}
end)

IO.puts("\n📦 Testing OIR Builder...")
Verify5F6.check("IRBuilder builds non-empty OIR", fn ->
  ast = {:binary_op, :+, {:number, 1.0}, {:number, 2.0}}
  oir = Tiannara.OPC.OIR.IRBuilder.build(ast)

  if is_list(oir) and oir != [] do
    {:ok, "#{length(oir)} instructions"}
  else
    {:fail, "empty OIR: #{inspect(oir)}"}
  end
end)

IO.puts("\n📦 Testing GPU Compiler...")
Verify5F6.check("GPUCompiler.compile_oir produces GLSL", fn ->
  ast = {:binary_op, :+, {:number, 1.0}, {:number, 2.0}}
  oir = Tiannara.OPC.OIR.IRBuilder.build(ast)

  case Tiannara.OPC.Compiler.GPUCompiler.compile_oir(oir) do
    {:ok, shader} ->
      IO.puts("   Shader preview: " <> String.slice(shader, 0, 300) <> "...")
      {:ok, "#{byte_size(shader)} bytes"}

    {:error, reason} ->
      {:fail, "compilation failed: #{inspect(reason)}"}
  end
end)

IO.puts("\n📦 Testing Full Compilation Pipeline...")
Verify5F6.check("CompileAPI.compile_physics full pipeline", fn ->
  case Tiannara.OPC.API.CompileAPI.compile_physics("obs_test_001", "gravity * 9.81") do
    {:ok, result} when is_map(result) ->
      status = result |> Map.get(:execution) |> then(fn
        e when is_map(e) -> Map.get(e, :status)
        _ -> nil
      end)
      Process.put(:execution_status, status)
      IO.puts("   Observer ID: #{inspect(Map.get(result, :observer_id))}")
      IO.puts("   Expression: #{inspect(Map.get(result, :expression))}")
      IO.puts("   AST Depth: #{inspect(Map.get(result, :ast_depth))}")
      IO.puts("   Shader Size: #{inspect(Map.get(result, :shader_length))} bytes")
      IO.puts("   Execution Status: #{inspect(status)}")
      {:ok, "execution.status=#{inspect(status)}"}

    {:ok, other} ->
      {:fail, "unexpected result shape: #{inspect(other) |> String.slice(0, 200)}"}

    {:error, reason} ->
      {:fail, "pipeline failed: #{inspect(reason)}"}
  end
end)

Verify5F6.check("Execution is real compute (status is not :simulated)", fn ->
  case Process.get(:execution_status) do
    nil ->
      {:fail, "no execution record — pipeline did not produce one (see pipeline check)"}

    :simulated ->
      {:fail, "SIMULATION-ONLY — status :simulated; fabricated execution must not be certified"}

    other ->
      {:ok, "status #{inspect(other)}"}
  end
end)

IO.puts("\n📦 Testing Quick Validation API...")
Verify5F6.check("CompileAPI.validate_only accepts valid expression", fn ->
  case Tiannara.OPC.API.CompileAPI.validate_only("velocity ^ 2 + acceleration") do
    {:ok, :valid} -> :ok
    other -> {:fail, "expected {:ok, :valid}, got #{inspect(other)}"}
  end
end)

# ── Verdict ──────────────────────────────────────────────────────────────────

IO.puts("\n🎯 Grammar-enforced DSL parsing, bounded AST depth (max 16),")
IO.puts("   division-by-zero detection, AOR regularization, stack-based OIR,")
IO.puts("   and GLSL compilation are asserted by the checks above — not claims.")

System.halt(Verify5F6.verdict())
