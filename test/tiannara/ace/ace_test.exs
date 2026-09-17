defmodule Tiannara.ACE.ACETest do
  use ExUnit.Case, async: false

  setup do
    start_supervised!(Tiannara.ACE.Supervisor)
    :ok
  end

  describe "functional: design evolution" do
    test "evolves designs through simulation-based selection" do
      proposal = %Tiannara.ACE.Models.EngineeringProposal{
        id: UUID.uuid4(),
        problem_statement: "Design efficient energy storage system",
        target_system: :energy_system,
        required_capabilities: [],
        constraints: []
      }

      {:ok, evolved, best} = Tiannara.ACE.DesignEvolutionEngine.evolve_design(:ace_design_evolution, proposal)

      assert length(evolved.design_candidates) > 0
      assert best.fitness > 0
      assert best.generation > 0
    end
  end

  describe "functional: simulation and confidence" do
    test "simulates designs and calculates confidence" do
      design = %Tiannara.ACE.Models.DesignCandidate{
        id: UUID.uuid4(),
        proposal_id: "p1",
        design_spec: %{architecture: "test"}
      }

      {:ok, result} = Tiannara.ACE.CivilizationDigitalTwin.simulate(:ace_digital_twin, design, :standard)

      assert result.confidence_level > 0
      assert result.edge_cases_tested == 100
    end
  end

  describe "functional: engineering institutions" do
    test "default institutions exist and record designs" do
      institutions = Tiannara.ACE.EngineeringInstitutions.list_institutions(:ace_institutions)
      assert length(institutions) == 5

      Tiannara.ACE.EngineeringInstitutions.record_design(:ace_institutions, :energy, %{id: "d1"})
      inst = Tiannara.ACE.EngineeringInstitutions.get_institution(:ace_institutions, :energy)
      assert "d1" in inst.designs_produced
    end
  end

  describe "constitutional: verification first" do
    test "every proposal receives confidence assessment" do
      proposal = %Tiannara.ACE.Models.EngineeringProposal{
        id: UUID.uuid4(),
        problem_statement: "Test system",
        required_capabilities: [],
        constraints: []
      }

      sim_result = %Tiannara.ACE.Models.SimulationResult{
        id: UUID.uuid4(),
        design_id: "d1",
        confidence_level: 0.85,
        failure_scenarios: [],
        success_metrics: %{safety_compliance: 0.95}
      }

      {:ok, confidence} = Tiannara.ACE.EngineeringConfidence.assess(:ace_confidence, proposal, [sim_result])

      assert confidence.overall_confidence > 0
      assert confidence.recommendation in [:proceed_to_prototype, :proceed_with_caution, :requires_more_validation, :reject]
    end
  end

  describe "constitutional: augments human intelligence" do
    test "proposals require human approval" do
      result = Tiannara.ACE.Orchestrator.engineer_system("Design energy storage system", [], [])

      assert result.proposal.approval_status != :approved
      assert result.confidence.overall_confidence > 0
    end
  end
end
