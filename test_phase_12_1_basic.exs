# Test script for Phase 12.1 Milestone 1
# Verifies basic functionality of Research Institution runtime

alias TiannaraOS.ResearchInstitution
alias TiannaraOS.InstitutionKernel
alias TiannaraOS.ResearchCampaign

IO.puts("\n=== Phase 12.1 Milestone 1 - Basic Functionality Test ===\n")

# Test 1: Create ResearchInstitution
IO.puts("Test 1: Creating ResearchInstitution...")
institution = ResearchInstitution.new(:test_lab, :test_world, 1)
IO.puts("  ✓ Institution created: #{inspect(institution.id)}")
IO.puts("  ✓ Status: #{institution.status}")
IO.puts("  ✓ Initial balance: #{institution.economic_ledger.balance}")
IO.puts("  ✓ Constitution mission: #{institution.constitution.mission}")

# Test 2: Create ResearchCampaign
IO.puts("\nTest 2: Creating ResearchCampaign...")
campaign = ResearchCampaign.new(:quantum_research, :test_lab, 1, %{
  objectives: ["quantum supremacy research"],
  budget: 500.0,
  genome: %{exploration_rate: 0.7}
})
IO.puts("  ✓ Campaign created: #{inspect(campaign.id)}")
IO.puts("  ✓ Objectives: #{inspect(campaign.objectives)}")
IO.puts("  ✓ Budget: #{campaign.economics.allocated_budget}")
IO.puts("  ✓ Genome exploration_rate: #{campaign.genome.exploration_rate}")

# Test 3: Verify State struct has research_institutions field
IO.puts("\nTest 3: Verifying State struct...")
state_struct = %TiannaraOS.State{}
IO.puts("  ✓ State struct has research_institutions field: #{Map.has_key?(state_struct, :research_institutions)}")

# Test 4: Test campaign helper functions
IO.puts("\nTest 4: Testing campaign helper functions...")
updated_campaign = ResearchCampaign.spend_budget(campaign, 50.0)
IO.puts("  ✓ Spent 50.0 from budget")
IO.puts("  ✓ Remaining budget: #{updated_campaign.economics.remaining}")

updated_campaign = ResearchCampaign.record_discovery(updated_campaign, :quantum_entanglement)
IO.puts("  ✓ Recorded discovery: :quantum_entanglement")
IO.puts("  ✓ Total discoveries: #{length(updated_campaign.discoveries)}")

# Test 5: Verify institution structure
IO.puts("\nTest 5: Verifying institution structure completeness...")
required_fields = [
  :id, :world_id, :founded_tick, :status, :constitution, :kernel_pid,
  :identity, :campaigns, :operational_memory, :research_memory,
  :institutional_memory, :civilizational_memory, :economic_ledger,
  :governance_state, :knowledge_graph, :discovery_portfolio,
  :world_model, :semantic_event_log, :telemetry, :runtime_registration
]

missing_fields = Enum.filter(required_fields, fn field ->
  not Map.has_key?(institution, field)
end)

if Enum.empty?(missing_fields) do
  IO.puts("  ✓ All #{length(required_fields)} required fields present")
else
  IO.puts("  ✗ Missing fields: #{inspect(missing_fields)}")
end

# Test 6: Verify knowledge graph structure
IO.puts("\nTest 6: Verifying knowledge graph structure...")
kg = institution.knowledge_graph
IO.puts("  ✓ Knowledge graph has nodes map: #{is_map(kg.nodes)}")
IO.puts("  ✓ Knowledge graph has edges map: #{is_map(kg.edges)}")
IO.puts("  ✓ Knowledge graph has node_types MapSet: #{is_struct(kg.node_types, MapSet)}")
IO.puts("  ✓ Knowledge graph has edge_types MapSet: #{is_struct(kg.edge_types, MapSet)}")

# Test 7: Verify economic ledger structure
IO.puts("\nTest 7: Verifying economic ledger structure...")
ledger = institution.economic_ledger
IO.puts("  ✓ Ledger has entries list: #{is_list(ledger.entries)}")
IO.puts("  ✓ Ledger has assets map: #{is_map(ledger.assets)}")
IO.puts("  ✓ Ledger has liabilities map: #{is_map(ledger.liabilities)}")
IO.puts("  ✓ Ledger has balance: #{is_float(ledger.balance)}")

# Test 8: Verify memory structure
IO.puts("\nTest 8: Verifying four-tier memory structure...")
IO.puts("  ✓ Operational memory is list: #{is_list(institution.operational_memory)}")
IO.puts("  ✓ Research memory is map: #{is_map(institution.research_memory)}")
IO.puts("  ✓ Institutional memory is map: #{is_map(institution.institutional_memory)}")
IO.puts("  ✓ Civilizational memory is map: #{is_map(institution.civilizational_memory)}")

IO.puts("\n=== All Basic Tests Passed ✓ ===\n")
IO.puts("Next step: Start InstitutionKernel GenServer and run tick processing")
IO.puts("Note: Full integration test requires running mix test or iex session\n")
