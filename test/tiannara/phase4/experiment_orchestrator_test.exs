defmodule Tiannara.Phase4.ExperimentOrchestratorTest do
  use ExUnit.Case, async: true

  alias Tiannara.Phase4.ExperimentOrchestrator

  describe "ExecutiveService Behaviour" do
    test "returns the correct service id" do
      assert ExperimentOrchestrator.id() == :experiment_orchestrator
    end

    test "returns the correct version" do
      assert ExperimentOrchestrator.version() == "2.0.0"
    end

    test "defines capabilities" do
      caps = ExperimentOrchestrator.capabilities()
      assert :experiment_lifecycle_management in caps
      assert :result_aggregation in caps
      assert :experiment_cancellation in caps
    end

    test "defines dependencies" do
      deps = ExperimentOrchestrator.dependencies()
      assert :workflow_engine in deps
      assert :knowledge_coordinator in deps
    end

    test "has high priority" do
      assert ExperimentOrchestrator.priority() == :high
    end
  end
end
