defmodule Tiannara.Phase4.AutonomousResearchEngineTest do
  use ExUnit.Case, async: true

  alias Tiannara.Phase4.AutonomousResearchEngine

  describe "ExecutiveService Behaviour" do
    test "returns the correct service id" do
      assert AutonomousResearchEngine.id() == :autonomous_research_engine
    end

    test "returns the correct version" do
      assert AutonomousResearchEngine.version() == "1.0.0"
    end

    test "defines capabilities" do
      caps = AutonomousResearchEngine.capabilities()
      assert :autonomous_hypothesis_generation in caps
      assert :experiment_dispatch in caps
      assert :result_fusion in caps
    end

    test "defines dependencies" do
      deps = AutonomousResearchEngine.dependencies()
      assert :workflow_engine in deps
      assert :knowledge_coordinator in deps
      assert :ontology_manager in deps
    end

    test "has high priority" do
      assert AutonomousResearchEngine.priority() == :high
    end
  end
end
