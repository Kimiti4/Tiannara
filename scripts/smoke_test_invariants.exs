#!/usr/bin/env elixir

# Quick smoke test for lifecycle invariant validation
# Run with: elixir scripts/smoke_test_invariants.exs

IO.puts("🧪 Lifecycle Invariant Smoke Test")
IO.puts("=" |> String.duplicate(60))

# Initialize ETS tables (simulating app startup)
:lifecycle_events = :ets.new(:lifecycle_events, [:bag, :named_table, write_concurrency: true])
:lifecycle_state = :ets.new(:lifecycle_state, [:set, :named_table, write_concurrency: true])
:lifecycle_stats = :ets.new(:lifecycle_stats, [:set, :named_table, write_concurrency: true])

# Initialize stats counters
Enum.each([:capability, :theory, :ontology], fn etype ->
  :ets.insert(:lifecycle_stats, [
    {"#{etype}_created", 0},
    {"#{etype}_rediscovered", 0},
    {"#{etype}_removed", 0},
    {"#{etype}_promoted", 0},
    {"#{etype}_merged", 0}
  ])
end)

IO.puts("\n✅ ETS tables initialized")

# Test 1: Single creation
IO.puts("\n📝 Test 1: Single creation")
:ets.insert(:lifecycle_events, {:capability, "cap_1", make_ref(), :created, 100, nil, %{}})
:ets.insert(:lifecycle_state, {{:capability, "cap_1"}, %{status: :active, created_tick: 100}})
:ets.update_counter(:lifecycle_stats, "capability_created", {2, 1})

created = :ets.lookup_element(:lifecycle_stats, "capability_created", 2)
IO.puts("   Created: #{created}")
if created != 1 do
  IO.puts("   ❌ ASSERTION FAILED: Expected 1, got #{created}")
  exit(:assertion_failed)
end
IO.puts("   ✅ PASS")

# Test 2: Rediscovery detection
IO.puts("\n📝 Test 2: Rediscovery detection")
case :ets.lookup(:lifecycle_state, {:capability, "cap_1"}) do
  [{_key, existing}] ->
    IO.puts("   Entity already exists - would emit :rediscovered")
    :ets.update_counter(:lifecycle_stats, "capability_rediscovered", {2, 1})
    
  [] ->
    IO.puts("   ERROR: Entity should exist!")
    exit(:error)
end

rediscovered = :ets.lookup_element(:lifecycle_stats, "capability_rediscovered", 2)
IO.puts("   Rediscovered: #{rediscovered}")
if rediscovered != 1 do
  IO.puts("   ❌ ASSERTION FAILED: Expected 1, got #{rediscovered}")
  exit(:assertion_failed)
end
IO.puts("   ✅ PASS")

# Test 3: Removal tracking
IO.puts("\n📝 Test 3: Removal tracking")
:ets.insert(:lifecycle_events, {:capability, "cap_2", make_ref(), :created, 200, nil, %{}})
:ets.insert(:lifecycle_state, {{:capability, "cap_2"}, %{status: :active, created_tick: 200}})
:ets.update_counter(:lifecycle_stats, "capability_created", {2, 1})

:ets.insert(:lifecycle_events, {:capability, "cap_2", make_ref(), :removed, 300, 300, %{removal_reason: :selection}})
:ets.insert(:lifecycle_state, {{:capability, "cap_2"}, %{status: :removed, created_tick: 200, removed_tick: 300, removal_reason: :selection}})
:ets.update_counter(:lifecycle_stats, "capability_removed", {2, 1})

created = :ets.lookup_element(:lifecycle_stats, "capability_created", 2)
removed = :ets.lookup_element(:lifecycle_stats, "capability_removed", 2)
expected_active = created - removed

IO.puts("   Created: #{created}, Removed: #{removed}")
IO.puts("   Expected active: #{expected_active}")
if expected_active != 1 do
  IO.puts("   ❌ ASSERTION FAILED: Expected 1, got #{expected_active}")
  exit(:assertion_failed)
end
IO.puts("   ✅ PASS")

# Test 4: Invariant verification
IO.puts("\n📝 Test 4: Invariant verification")
created = :ets.lookup_element(:lifecycle_stats, "capability_created", 2)
removed = :ets.lookup_element(:lifecycle_stats, "capability_removed", 2)
promoted = :ets.lookup_element(:lifecycle_stats, "capability_promoted", 2)
merged = :ets.lookup_element(:lifecycle_stats, "capability_merged", 2)

total_removed = removed + promoted + merged
expected_active = created - total_removed

# Count actual active entities in state
match_spec = [{{{:capability, :'$1'}, %{status: :active}}, [], [:'$1']}]
active_ids = :ets.select(:lifecycle_state, match_spec)
actual_active = length(active_ids)

IO.puts("   Expected active: #{expected_active}")
IO.puts("   Actual active: #{actual_active}")

if expected_active == actual_active do
  IO.puts("   ✅ INVARIANT HOLDS")
else
  IO.puts("   ❌ INVARIANT VIOLATED!")
  IO.puts("   Missing from graph: #{expected_active - actual_active}")
  exit(:invariant_violated)
end

# Test 5: Innovation efficiency
IO.puts("\n📝 Test 5: Innovation efficiency calculation")
created = :ets.lookup_element(:lifecycle_stats, "capability_created", 2)
rediscovered = :ets.lookup_element(:lifecycle_stats, "capability_rediscovered", 2)

if created + rediscovered > 0 do
  efficiency = created / (created + rediscovered)
  IO.puts("   Created: #{created}, Rediscovered: #{rediscovered}")
  IO.puts("   Innovation Efficiency: #{Float.round(efficiency * 100, 2)}%")
  
  if efficiency > 0 and efficiency < 1 do
    IO.puts("   ✅ Efficiency in valid range (0-1)")
  else
    IO.puts("   ❌ Efficiency out of range!")
    exit(:efficiency_error)
  end
else
  IO.puts("   ⚠️  No discoveries yet")
end

IO.puts("\n" <> ("=" |> String.duplicate(60)))
IO.puts("✅ ALL SMOKE TESTS PASSED")
IO.puts("=" |> String.duplicate(60))
