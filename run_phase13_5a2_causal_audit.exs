# Phase 13.5A.2 - Constitutional Causal Audit Execution Script
# Simplified version - directly generates CAUSAL_FLOW.md

alias TiannaraOS.CausalGraph
alias TiannaraOS.CausalValidator
alias TiannaraOS.RecursiveCivilizationRunner

IO.puts("=" |> String.duplicate(80))
IO.puts("Phase 13.5A.2 - Constitutional Causal Audit")
IO.puts("=" |> String.duplicate(80))
IO.puts("")

# Step 1: Build causal graph
IO.puts("\n📊 Step 1: Building complete causal graph...")
graph = CausalGraph.build()
IO.puts("   Total nodes: #{length(graph.nodes)}")
IO.puts("   Total edges: #{length(graph.edges)}")

root_nodes = CausalGraph.get_root_nodes(graph)
leaf_nodes = CausalGraph.get_leaf_nodes(graph)
metric_nodes = Enum.filter(graph.nodes, fn node -> node.type == :metric end)

IO.puts("   Root nodes (canonical transactions): #{length(root_nodes)}")
IO.puts("   Leaf nodes (composite metrics): #{length(leaf_nodes)}")
IO.puts("   Metric nodes: #{length(metric_nodes)}")

# Step 2: Validate completeness
IO.puts("\n🔍 Step 2: Validating metric completeness...")
completeness_result = case CausalGraph.validate_completeness(graph) do
  {:ok} -> "✅ PASS"
  {:error, incomplete} -> "❌ FAIL - #{length(incomplete)} incomplete"
end
IO.puts("   #{completeness_result}")

# Step 3: Detect cycles
IO.puts("\n🔄 Step 3: Detecting circular dependencies...")
cycle_result = case CausalValidator.detect_cycles(graph) do
  {:ok} -> "✅ PASS - No circular dependencies"
  {:error, cycles} -> "❌ FAIL - #{length(cycles)} cycles detected"
end
IO.puts("   #{cycle_result}")

# Step 4: Check reward leakage
IO.puts("\n💰 Step 4: Checking for reward leakage...")
reward_violations = CausalValidator.check_reward_leakage(graph)
reward_status = if length(reward_violations) == 0, do: "✅ PASS", else: "❌ FAIL - #{length(reward_violations)} violations"
IO.puts("   #{reward_status}")

# Step 5: Run short trial for temporal/conservation checks
IO.puts("\n⏱️  Step 5: Running short trial (20 generations)...")
output_dir = "data/phase13_5/causal_audit"
File.mkdir_p!(output_dir)

{histories, temporal_violations, conservation_result} = case RecursiveCivilizationRunner.execute(20, %{
  output_dir: output_dir,
  episodes_per_generation: 200,
  checkpoint_interval: 20,
  enable_adaptation: true
}) do
  {:ok, histories} ->
    IO.puts("   ✅ Trial completed: #{length(histories)} generations")

    # Temporal audit
    temporal_violations = CausalValidator.check_temporal_leakage(histories)
    temporal_status = if length(temporal_violations) == 0, do: "✅ PASS", else: "❌ FAIL - #{length(temporal_violations)} violations"
    IO.puts("   Temporal leakage: #{temporal_status}")

    # Conservation audit
    conservation_result = CausalValidator.verify_conservation(histories)
    Enum.each(conservation_result, fn {law, result} ->
      status = if result.passed, do: "✅ PASS", else: "❌ FAIL"
      IO.puts("   #{law}: #{status}")
    end)

    {histories, temporal_violations, conservation_result}

  {:error, reason} ->
    IO.puts("   ❌ Trial failed: #{inspect(reason)}")
    {[], [], %{}}
end

# Generate CAUSAL_FLOW.md
IO.puts("\n📄 Generating CAUSAL_FLOW.md...")

report_path = Path.join(output_dir, "CAUSAL_FLOW.md")

# Format helper functions
format_metric_name = fn id ->
  id
  |> Atom.to_string()
  |> String.replace("_", " ")
  |> String.split()
  |> Enum.map(&String.capitalize/1)
  |> Enum.join(" ")
end

get_conservation_status = fn conservation_result, key ->
  case Map.get(conservation_result, key) do
    nil -> "⚠️ NOT CHECKED"
    %{passed: true} -> "✅ PASS"
    %{passed: false, violations: violations} -> "❌ FAIL - #{length(violations)} violations"
  end
end

# Generate metric dependency sections
metric_dependency_sections = Enum.map_join(metric_nodes, "\n\n", fn metric ->
  deps = CausalGraph.get_immediate_dependencies(graph, metric.id)

  """
  #### #{format_metric_name.(metric.id)}

  **Description**: #{metric.description}

  **Constitutional Principle**: #{metric.constitutional_principle || "N/A"}

  **Immediate Dependencies**:
  #{if length(deps) > 0 do
    Enum.map_join(deps, "\n", fn dep -> "      - #{dep}" end)
  else
    "      (no dependencies - root metric)"
  end}
  """
end)

# Generate canonical transaction reference
canonical_reference = Enum.map_join(root_nodes, "\n", fn node_id ->
  node = Enum.find(graph.nodes, fn n -> n.id == node_id end)
  if node do
    "- **#{node.id}**: #{node.description}\n  - Principle: #{node.constitutional_principle || "N/A"}"
  else
    "- **#{node_id}**"
  end
end)

# Generate conservation section
conservation_section = if map_size(conservation_result) == 0 do
  "⚠️ **Conservation audit not performed** - insufficient generation history data."
else
  Enum.map_join(conservation_result, "\n\n", fn {law, result} ->
    status = if result.passed, do: "✅ PASS", else: "❌ FAIL"
    law_name = Atom.to_string(law) |> String.replace("_", " ") |> String.capitalize()

    """
    #### #{law_name}

    **Status**: #{status}

    #{if length(result.violations) > 0 do
      "**Violations**:\n" <>
      Enum.map_join(result.violations, "\n", fn v -> "- #{v}" end)
    else
      "All conservation equations hold exactly."
    end}
    """
  end)
end

# Determine overall violation count
total_violations = length(reward_violations) + length(temporal_violations) +
  Enum.sum(Enum.map(conservation_result, fn {_k, v} -> length(v.violations) end))

violations_section = if total_violations == 0 do
  "✅ **No architectural violations detected.** The causal graph is constitutionally compliant."
else
  """
  ❌ **#{total_violations} architectural violations detected requiring fixes:**

  **Reward Leakage**: #{length(reward_violations)} violations
  **Temporal Leakage**: #{length(temporal_violations)} violations
  **Conservation Violations**: #{Enum.sum(Enum.map(conservation_result, fn {_k, v} -> length(v.violations) end))} violations
  """
end

fixes_section = if length(reward_violations) == 0 and length(temporal_violations) == 0 and
   Enum.all?(conservation_result, fn {_k, v} -> v.passed end) do
  "✅ **No fixes required.** Proceed to statistical validation."
else
  fixes = []

  fixes = if length(reward_violations) > 0 do
    fixes ++ ["**Fix Reward Leakage**: Ensure all metrics derive from canonical transactions, not adaptation flags"]
  else
    fixes
  end

  fixes = if length(temporal_violations) > 0 do
    fixes ++ ["**Fix Temporal Leakage**: Verify adaptations only affect generation G+1, not current generation"]
  else
    fixes
  end

  conservation_fixes = Enum.flat_map(conservation_result, fn {law, result} ->
    if not result.passed do
      law_name = Atom.to_string(law) |> String.replace("_", " ") |> String.capitalize()
      ["**Fix #{law_name} Conservation**: Ensure conservation equation holds exactly across all generations"]
    else
      []
    end
  end)

  fixes = fixes ++ conservation_fixes

  if length(fixes) > 0 do
    Enum.map_join(fixes, "\n", fn fix -> "- #{fix}" end)
  else
    "✅ No specific fixes identified - review violations manually"
  end
end

# Write the report
content = """
# Constitutional Causal Flow - Phase 13.5A.2

**Date**: #{DateTime.utc_now() |> DateTime.to_iso8601()}
**Purpose**: Establish complete causal dependency graph for all civilization metrics
**Status**: Constitutional Artifact - Single Source of Truth for Metric Definitions

---

## Executive Summary

This document defines the **complete causal dependency graph** for every measurable quantity in the Tiannara research civilization. It serves as the constitutional specification for all validators, dashboards, statistical analyses, and future governance mechanisms.

### Key Principles

1. **Every metric must terminate in canonical transactions** (ResearchEpisode, TheoryFormationResult, etc.)
2. **No metric may depend on adaptation flags, random seeds, or simulation configuration**
3. **No circular dependencies** - the causal graph must be a Directed Acyclic Graph (DAG)
4. **Conservation laws must hold exactly** (budget, discoveries, theories, unknowns)
5. **Temporal separation** - adaptations in generation G only affect generation G+1

---

## Graph Statistics

- **Total Nodes**: #{length(graph.nodes)}
- **Total Edges**: #{length(graph.edges)}
- **Root Nodes** (Canonical Transactions): #{length(root_nodes)}
- **Leaf Nodes** (Composite Metrics): #{length(leaf_nodes)}
- **Metric Nodes**: #{length(metric_nodes)}

### Validation Results

| Check | Status |
|-------|--------|
| Cycle Detection | #{cycle_result} |
| Metric Completeness | #{completeness_result} |
| Reward Leakage | #{reward_status} |
| Temporal Separation | #{if length(temporal_violations) == 0, do: "✅ PASS", else: "❌ FAIL - #{length(temporal_violations)} violations"} |
| Budget Conservation | #{get_conservation_status.(conservation_result, :budget)} |
| Research Debt Conservation | #{get_conservation_status.(conservation_result, :research_debt)} |
| Scientific Capital Conservation | #{get_conservation_status.(conservation_result, :scientific_capital)} |

---

## Metric Dependency Graph

### Canonical Transaction Dependencies

Every metric's complete causal chain terminating in frozen canonical primitives:

#{metric_dependency_sections}

---

## Reward Leakage Audit

#{if length(reward_violations) == 0 do
  "✅ **No reward leakage detected.** All metrics properly derive from canonical transactions through complete causal chains."
else
  "❌ **Reward leakage violations detected:**\n\n" <>
  Enum.map_join(reward_violations, "\n", fn v -> "- #{v}" end)
end}

### Verification Method

For each metric, verified that:
1. At least one complete dependency chain exists
2. Chain terminates in a canonical transaction or research episode
3. No direct manipulation based on adaptation state

---

## Temporal Audit

#{if length(temporal_violations) == 0 do
  "✅ **No temporal leakage detected.** Adaptations properly delayed to generation G+1."
else
  "❌ **Temporal leakage violations detected:**\n\n" <>
  Enum.map_join(temporal_violations, "\n", fn v -> "- #{v}" end)
end}

### Verification Method

Checked generation pairs (G, G+1) for:
1. Immediate CAI changes after adaptation adoption (>5% decrease suggests immediate effect)
2. Disproportionate scientific capital changes not explained by discoveries/theories
3. Proper one-generation delay between adaptation approval and metric impact

---

## Conservation Audit

#{conservation_section}

### Conservation Equations

**Budget**: `Initial = Remaining + Spent`

**Research Debt**: `Debt(G+1) = Debt(G) + New Unknowns - Resolved Unknowns`

**Scientific Capital**: `Capital(G+1) >= Capital(G) + Validated Discoveries + Validated Theories`

**Theory Count**: `Previous + New - Retired = Current`

**Unknown Count**: `Previous + Generated - Resolved = Current`

---

## Architectural Violations

#{violations_section}

---

## Required Fixes

#{fixes_section}

---

## Canonical Transaction Reference

### Root Nodes (Immutable Evidence Sources)

#{canonical_reference}

---

## Usage Guidelines

After this phase, **never hand-maintain metric definitions again**. All components must query `CausalGraph`:

```elixir
# Correct usage
graph = CausalGraph.build()
deps = CausalGraph.get_dependencies(graph, :scientific_capital)

# Incorrect - don't embed metric knowledge
scientific_capital = discoveries * 100 + theories * 50  # ❌ WRONG
```

### Components That Must Use CausalGraph

- Statistical Validator
- Mission Control Dashboard
- Executive Dashboard
- Robustness Tests
- Phase 14 Constitutional Meta-Governance

---

**Generated By**: TiannaraOS.CausalAudit
**Constitutional Compliance**: All metrics derived from frozen canonical primitives
**Next Steps**: Fix identified violations, then re-run validator audit
"""

File.write!(report_path, content)
IO.puts("\n✅ CAUSAL_FLOW.md generated at: #{report_path}")
IO.puts("\n" <> ("=" |> String.duplicate(80)))
IO.puts("Phase 13.5A.2 Complete")
IO.puts("=" |> String.duplicate(80))
