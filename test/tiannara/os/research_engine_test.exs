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

  test "Research program stage machine fails closed until a real capability is connected", %{state: state} do
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

    # No stage may advance while the downstream capability is unavailable:
    # goals, hypotheses, experiments, evidence and discoveries are never
    # fabricated (dfa47818: "explicitly unavailable until the corresponding
    # executor/validator is connected").
    for stage <- [:goal_generation, :hypothesis_generation, :experimentation, :evidence_synthesis, :discovery_candidate] do
      p = %{program | stage: stage}

      assert {:error, {:research_capability_unavailable, ^stage}} =
               ResearchProgramEngine.tick_program(p, state)
    end

    # Fail closed leaves every field untouched: no fabricated artifacts,
    # no budget drain, no discovery registered.
    assert program.goals == []
    assert program.hypotheses == []
    assert program.active_experiments == []
    assert program.evidence_ids == []
    assert program.discoveries == []
    assert program.budget == %{credits: 100.0, compute: 100.0, attention: 100.0}
    assert program.status == :active
    assert state.discoveries == %{}
    assert state.research_programs[:program_crypto].stage == :goal_generation
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
    # Add candidate discovery proposed by program, backed by two evidence records
    state = DiscoveryExchange.propose_discovery(
      state,
      :disc_test,
      :prog_test,
      :inst_test,
      :world_test,
      [:ev_test, :ev_test_two]
    )

    # Initial state verification — a fresh proposal carries no evidence score
    disc = Map.get(state.discoveries, :disc_test)
    assert disc.validation_level == :l1
    assert disc.evidence_score == 0.0

    # Evidence evaluation records a score of 0.7 across the two evidence records
    disc = %{disc | evidence_score: 0.7}
    state = %{state | discoveries: Map.put(state.discoveries, :disc_test, disc)}

    # Promote to L2 (requires evidence_score >= 0.6 and at least two evidence records)
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
    assert asset.valuation == 70.0
  end

  test "Discovery asset marketplace operations", %{state: state} do
    # Assets can only be instantiated from a discovery that carries evidence
    state = DiscoveryExchange.propose_discovery(
      state,
      :disc_asset_test,
      :prog_test,
      :inst_test,
      :world_test,
      [:ev_test, :ev_test_two]
    )

    disc = Map.get(state.discoveries, :disc_asset_test)
    disc = %{disc | evidence_score: 0.7}
    state = %{state | discoveries: Map.put(state.discoveries, :disc_asset_test, disc)}

    assert {:ok, state} = DiscoveryExchange.create_discovery_asset(state, :disc_asset_test)
    assert Map.has_key?(state.discovery_assets, :disc_asset_test)

    # Initial valuation follows confidence (1.0) * 100.0
    assert Map.get(state.discovery_assets, :disc_asset_test).valuation == 100.0

    # Buy the asset license
    assert {:ok, state} = DiscoveryExchange.transact_discovery(state, :disc_asset_test, :buyer_tenant_xyz, 500.0)
    asset = Map.get(state.discovery_assets, :disc_asset_test)
    assert asset.maturity == :commercial
    assert :buyer_tenant_xyz in asset.buyers
    assert asset.valuation == 650.0
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
