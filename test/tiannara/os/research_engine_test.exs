defmodule TiannaraOS.ResearchEngineTest do
  use ExUnit.Case, async: true

  alias TiannaraOS.State
  alias TiannaraOS.ResearchProgram
  alias TiannaraOS.ResearchProgramEngine
  alias TiannaraOS.DiscoveryAssetEconomy, as: DiscoveryExchange
  alias TiannaraOS.HumanCollaborator

  setup do
    # Build standard initial state
    collaborators = %{
      human_expert_1: %HumanCollaborator{
        id: :human_expert_1,
        expertise: [:cryptography, :system_security],
        trust_score: 0.9,
        role: :domain_expert,
        organization: "Security Group"
      },
      human_auditor: %HumanCollaborator{
        id: :human_auditor,
        expertise: [:governance],
        trust_score: 0.95,
        role: :auditor,
        organization: "Auditing Board"
      }
    }

    state = %State{
      research_programs: %{},
      collaborators: collaborators,
      discovery_assets: %{},
      discoveries: %{}
    }

    {:ok, state: state}
  end

  test "Research program ticks through complete stage lifecycle", %{state: state} do
    program = %ResearchProgram{
      id: :program_crypto,
      world_id: :world_sec_twin,
      institution_id: :inst_sec_lab,
      stage: :goal_generation,
      life_stage: :apprentice,
      budget: %{
        credits: 100.0,
        compute: 100.0,
        attention: 100.0
      }
    }

    # Put program into state
    state = %{state | research_programs: Map.put(state.research_programs, program.id, program)}

    # Tick 1: Goal Generation -> Hypothesis Generation
    assert {:ok, p1, state} = ResearchProgramEngine.tick_program(program, state)
    assert p1.stage == :hypothesis_generation
    assert p1.started_at != nil
    assert p1.budget.attention == 98.0
    assert "Identify insecure dependencies" in p1.goals

    # Tick 2: Hypothesis Generation -> Experimentation
    assert {:ok, p2, state} = ResearchProgramEngine.tick_program(p1, state)
    assert p2.stage == :experimentation
    assert length(p2.hypotheses) == 1
    assert p2.budget.compute == 95.0

    # Tick 3: Experimentation -> Evidence Synthesis
    assert {:ok, p3, state} = ResearchProgramEngine.tick_program(p2, state)
    assert p3.stage == :evidence_synthesis
    assert length(p3.active_experiments) == 1
    assert p3.budget.compute == 90.0

    # Tick 4: Evidence Synthesis -> Discovery Candidate
    assert {:ok, p4, state} = ResearchProgramEngine.tick_program(p3, state)
    assert p4.stage == :discovery_candidate
    assert length(p4.evidence_ids) == 1
    assert p4.budget.credits == 90.0

    # Tick 5: Discovery Candidate -> Completed with proposed Discovery candidate
    assert {:ok, p5, state} = ResearchProgramEngine.tick_program(p4, state)
    assert p5.status == :completed
    assert p5.outcome == :success
    assert p5.completed_at != nil
    assert length(p5.discoveries) == 1

    discovery_id = List.first(p5.discoveries)
    assert Map.has_key?(state.discoveries, discovery_id)
    disc = Map.get(state.discoveries, discovery_id)
    assert disc.origin_program_id == :program_crypto
    assert disc.origin_world_id == :world_sec_twin
    assert disc.validation_level == :l1
    assert disc.status == :candidate
  end

  test "Research program engine suspends program on insufficient budget", %{state: state} do
    program = %ResearchProgram{
      id: :poor_program,
      world_id: :world_sec_twin,
      institution_id: :inst_sec_lab,
      stage: :goal_generation,
      life_stage: :apprentice,
      budget: %{
        credits: 100.0,
        compute: 100.0,
        attention: 1.0 # Requires 2.0 to tick
      }
    }

    state = %{state | research_programs: Map.put(state.research_programs, program.id, program)}

    assert {:ok, updated, next_state} = ResearchProgramEngine.tick_program(program, state)
    assert updated.status == :suspended
    assert updated.outcome == :failure
    assert updated.stage == :goal_generation
    assert Map.get(next_state.research_programs, :poor_program).status == :suspended
  end

  test "Discovery evaluation ladder promotes through levels L1 -> L5", %{state: state} do
    # Add candidate discovery proposed by program
    state = DiscoveryExchange.propose_discovery(
      state,
      :disc_test,
      :prog_test,
      :inst_test,
      :world_test,
      [:ev_test]
    )

    # Initial state verification
    disc = Map.get(state.discoveries, :disc_test)
    assert disc.validation_level == :l1

    # Promote to L2 (requires evidence_score > 0.6)
    # Propose puts evidence_score = 0.7 by default, so L1 -> L2 promotion triggers automatically
    state = DiscoveryExchange.evaluate_validation_ladder(state, :disc_test)
    disc = Map.get(state.discoveries, :disc_test)
    assert disc.validation_level == :l2

    # Update replication_score to promote to L3 (requires replication_score > 0.5)
    updated_disc = %{disc | replication_score: 0.6}
    state = %{state | discoveries: Map.put(state.discoveries, :disc_test, updated_disc)}
    state = DiscoveryExchange.evaluate_validation_ladder(state, :disc_test)
    disc = Map.get(state.discoveries, :disc_test)
    assert disc.validation_level == :l3

    # Update transferability_score to promote to L4 (requires transferability_score > 0.5)
    updated_disc = %{disc | transferability_score: 0.7}
    state = %{state | discoveries: Map.put(state.discoveries, :disc_test, updated_disc)}
    state = DiscoveryExchange.evaluate_validation_ladder(state, :disc_test)
    disc = Map.get(state.discoveries, :disc_test)
    assert disc.validation_level == :l4

    # L4 to L5 requires both a trusted human sign-off AND CI passed
    # Add CI passed to metadata
    updated_disc = put_in(disc.metadata[:ci_passed], true)
    state = %{state | discoveries: Map.put(state.discoveries, :disc_test, updated_disc)}

    # Perform Human sign-off (expert trust is 0.9 > 0.7)
    assert {:ok, state} = DiscoveryExchange.sign_off_human(state, :disc_test, :human_expert_1, "Security validation complete")
    disc = Map.get(state.discoveries, :disc_test)
    assert disc.validation_level == :l5
    assert disc.status == :validated
    assert length(disc.validation_history) >= 5

    # Hitting L5 must automatically instantiate a DiscoveryAsset
    assert Map.has_key?(state.discovery_assets, :disc_test)
    asset = Map.get(state.discovery_assets, :disc_test)
    assert asset.maturity == :validated
    assert asset.valuation == 1000.0
  end

  test "Discovery asset marketplace operations", %{state: state} do
    # Add a validated discovery asset
    state = DiscoveryExchange.create_discovery_asset(state, :disc_asset_test)
    assert Map.has_key?(state.discovery_assets, :disc_asset_test)

    # Buy the asset license
    assert {:ok, state} = DiscoveryExchange.transact_discovery(state, :disc_asset_test, :buyer_tenant_xyz, 500.0)
    asset = Map.get(state.discovery_assets, :disc_asset_test)
    assert asset.maturity == :commercial
    assert :buyer_tenant_xyz in asset.buyers
    assert asset.valuation == 1050.0
    assert length(asset.transaction_history) == 1
    assert List.first(asset.transaction_history).amount == 500.0
  end

  test "Discovery packaging format structure", %{state: state} do
    state = DiscoveryExchange.propose_discovery(
      state,
      :disc_pack_test,
      :prog_test,
      :inst_test,
      :world_test,
      [:ev_test]
    )

    assert {:ok, package} = DiscoveryExchange.package_discovery(state, :disc_pack_test)
    assert package.discovery_id == :disc_pack_test
    assert package.source_world == :world_test
    assert package.origin_program_id == :prog_test
    assert String.starts_with?(package.signature, "SHA256-SIMULATED-")
  end
end
