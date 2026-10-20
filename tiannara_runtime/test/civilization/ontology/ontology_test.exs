defmodule TiannaraRuntime.Civilization.Ontology.OntologyTest do
  use ExUnit.Case
  @moduletag :civilization
  @moduletag :ontology

  alias TiannaraRuntime.Civilization.Ontology.CivilizationState
  alias TiannaraRuntime.Civilization.Ontology.GovernanceModel
  alias TiannaraRuntime.Civilization.Ontology.InfrastructureModel
  alias TiannaraRuntime.Civilization.Ontology.EconomyModel
  alias TiannaraRuntime.Civilization.Ontology.CultureModel
  alias TiannaraRuntime.Civilization.Ontology.KnowledgeModel
  alias TiannaraRuntime.Civilization.Ontology.TechnologyPortfolio

  test "CivilizationState new/1 creates with defaults and validate/1 passes" do
    {:ok, state} = CivilizationState.new(%{civilization_id: "civ_test"})
    assert state.civilization_id == "civ_test"
    assert state.stability == 1.0
    assert state.entropy == 0.0
    assert state.resilience == 1.0
    assert state.innovation_rate == 0.0
    assert state.institutional_health == 1.0
    assert state.scientific_output == 0.0
    assert state.economic_output == 0.0
    assert state.infrastructure_health == 1.0
    assert state.governance_health == 1.0
    assert String.starts_with?(state.id, "cs_")
    assert String.length(state.id) == 19
    assert is_binary(state.fingerprint)
    assert CivilizationState.validate(state) == :ok
  end

  test "GovernanceModel new/1 creates with defaults and validate/1 passes" do
    {:ok, model} = GovernanceModel.new(%{civilization_id: "civ_test"})
    assert model.civilization_id == "civ_test"
    assert model.escalation_paths == []
    assert model.authority_graph == %{}
    assert model.oversight_graph == %{}
    assert model.policy_graph == %{}
    assert String.starts_with?(model.id, "gm_")
    assert GovernanceModel.validate(model) == :ok
  end

  test "InfrastructureModel new/1 creates with defaults and validate/1 passes" do
    {:ok, model} = InfrastructureModel.new(%{civilization_id: "civ_test"})
    assert model.civilization_id == "civ_test"
    assert model.energy == %{}
    assert model.transport == %{}
    assert model.communication == %{}
    assert model.water == %{}
    assert model.food == %{}
    assert model.manufacturing == %{}
    assert model.digital == %{}
    assert model.scientific == %{}
    assert model.medical == %{}
    assert model.security == %{}
    assert String.starts_with?(model.id, "im_")
    assert InfrastructureModel.validate(model) == :ok
  end

  test "EconomyModel new/1 creates with defaults and validate/1 passes" do
    {:ok, model} = EconomyModel.new(%{civilization_id: "civ_test"})
    assert model.civilization_id == "civ_test"
    assert model.resources == %{}
    assert model.production == %{}
    assert model.trade == %{}
    assert model.consumption == %{}
    assert model.allocation == %{}
    assert model.reserve == %{}
    assert model.capital == %{}
    assert model.scientific_capital == %{}
    assert String.starts_with?(model.id, "em_")
    assert EconomyModel.validate(model) == :ok
  end

  test "CultureModel new/1 creates with defaults and validate/1 passes" do
    {:ok, model} = CultureModel.new(%{civilization_id: "civ_test"})
    assert model.civilization_id == "civ_test"
    assert model.values == []
    assert model.norms == []
    assert model.education == %{}
    assert model.knowledge_transmission == %{}
    assert model.innovation_tolerance == 0.5
    assert model.cooperation == 0.5
    assert String.starts_with?(model.id, "cm_")
    assert CultureModel.validate(model) == :ok
  end

  test "KnowledgeModel new/1 creates with defaults and validate/1 passes" do
    {:ok, model} = KnowledgeModel.new(%{civilization_id: "civ_test"})
    assert model.civilization_id == "civ_test"
    assert model.repositories == []
    assert model.research_programs == []
    assert model.theories == []
    assert model.proofs == []
    assert model.scientific_capital == 0.0
    assert model.knowledge_entropy == 0.0
    assert model.knowledge_continuity == 1.0
    assert String.starts_with?(model.id, "km_")
    assert KnowledgeModel.validate(model) == :ok
  end

  test "TechnologyPortfolio new/1 creates with defaults and validate/1 passes" do
    {:ok, model} = TechnologyPortfolio.new(%{civilization_id: "civ_test"})
    assert model.civilization_id == "civ_test"
    assert model.technologies == []
    assert model.maturity == %{}
    assert model.dependencies == %{}
    assert model.replacement_graph == %{}
    assert model.evolution_graph == %{}
    assert model.risk == 0.0
    assert String.starts_with?(model.id, "tp_")
    assert TechnologyPortfolio.validate(model) == :ok
  end

  test "generate_id/1 returns correct prefix for each struct" do
    assert String.starts_with?(CivilizationState.generate_id(%{civilization_id: "c1"}), "cs_")
    assert String.starts_with?(GovernanceModel.generate_id(%{civilization_id: "c1"}), "gm_")
    assert String.starts_with?(InfrastructureModel.generate_id(%{civilization_id: "c1"}), "im_")
    assert String.starts_with?(EconomyModel.generate_id(%{civilization_id: "c1"}), "em_")
    assert String.starts_with?(CultureModel.generate_id(%{civilization_id: "c1"}), "cm_")
    assert String.starts_with?(KnowledgeModel.generate_id(%{civilization_id: "c1"}), "km_")
    assert String.starts_with?(TechnologyPortfolio.generate_id(%{civilization_id: "c1"}), "tp_")
  end
end
