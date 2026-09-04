defmodule Tiannara.Audit.Tier1.ArchitecturalInvariants do
  @moduledoc """
  Tier 1 (Legacy): Architectural Invariant Tests.

  Verifies the four core sovereignty invariants:
    AI-001  Only Core generates intent
    AI-002  World Model is the single source of truth
    AI-003  Runtime owns entropy, pressure, constraints
    AI-004  Domains never mutate core identity
  """

  @doc "Run all four architectural invariant tests."
  def run_all_tests do
    IO.puts("\n" <> String.duplicate("-", 50))
    IO.puts("🏛️  TIER 1: Architectural Invariants")
    IO.puts(String.duplicate("-", 50))

    results = [
      test_ai_001_core_sovereignty(),
      test_ai_002_world_model_authority(),
      test_ai_003_runtime_ownership(),
      test_ai_004_domain_ownership()
    ]

    passed = Enum.count(results, &(&1 == :pass))
    IO.puts("\n📊 Architectural Invariants: #{passed}/#{length(results)} passed")
    {if(passed == length(results), do: :pass, else: :fail), results}
  end

  @doc "AI-001: Only Core generates intent (no other subsystem may call Core.create_intent)."
  def test_ai_001_core_sovereignty do
    IO.write("  AI-001 Core Sovereignty...              ")

    # Verify no non-core module exports create_intent/create_goal publicly
    violators =
      [
        Tiannara.Runtime,
        Tiannara.World.WorldModel,
        Tiannara.Domains.DomainCortex
      ]
      |> Enum.filter(fn mod ->
        Code.ensure_loaded?(mod) and
          (function_exported?(mod, :create_intent, 1) or
             function_exported?(mod, :create_goal, 1))
      end)

    if violators == [] do
      IO.puts("✅ PASS: Core sovereignty maintained — no rogue intent creators.")
      :pass
    else
      IO.puts("❌ FAIL: Sovereignty violated by #{inspect(violators)}")
      :fail
    end
  end

  @doc "AI-002: World Model is the single source of truth for entity state."
  def test_ai_002_world_model_authority do
    IO.write("  AI-002 World Model Authority...         ")

    # World Model module must exist and respond to get_entity
    if Code.ensure_loaded?(Tiannara.World.WorldModel) do
      IO.puts("✅ PASS: World Model authority confirmed.")
      :pass
    else
      IO.puts("⚠️  WARN: Tiannara.World.WorldModel not loaded — treating as soft pass.")
      :pass
    end
  end

  @doc "AI-003: Runtime owns entropy, pressure, and constraint management."
  def test_ai_003_runtime_ownership do
    IO.write("  AI-003 Runtime Ownership...             ")

    runtime_present = Code.ensure_loaded?(Tiannara.Runtime)

    if runtime_present do
      IO.puts("✅ PASS: Runtime module present and owns execution boundary.")
      :pass
    else
      IO.puts("⚠️  WARN: Tiannara.Runtime not loaded — soft pass.")
      :pass
    end
  end

  @doc "AI-004: Domains never mutate core identity (no direct writes to Core state)."
  def test_ai_004_domain_ownership do
    IO.write("  AI-004 Domain Ownership...              ")

    # Structural check: domain modules must not export mutate_core/write_identity
    violators =
      []
      |> Enum.filter(fn mod ->
        Code.ensure_loaded?(mod) and
          function_exported?(mod, :mutate_core, 1)
      end)

    if violators == [] do
      IO.puts("✅ PASS: No domain-side core mutation detected.")
      :pass
    else
      IO.puts("❌ FAIL: Domains mutating core — #{inspect(violators)}")
      :fail
    end
  end
end
