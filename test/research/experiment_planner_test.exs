defmodule Tiannara.Research.ExperimentPlannerTest do
  use ExUnit.Case, async: false

  alias Tiannara.Research.ExperimentPlanner

  describe "ExperimentPlanner" do
    test "plan generates experiment from hypothesis" do
      hypothesis = %{id: "h1", domain: :memory, signal: :total_memory, statement: "Memory growth is due to X.", falsification_criteria: "Varying X shows no effect.", confidence: 0.5, rationale: ""}
      experiment = ExperimentPlanner.plan(hypothesis)
      assert experiment.id
      assert experiment.hypothesis.id == "h1"
      assert experiment.status == :planned
      assert experiment.objective != ""
      assert experiment.methodology != ""
    end

    test "plan for performance domain" do
      hypothesis = %{id: "h2", domain: :performance, signal: :latency, statement: "Latency due to scheduler.", falsification_criteria: "Varying scheduler shows no effect.", confidence: 0.7, rationale: ""}
      experiment = ExperimentPlanner.plan(hypothesis)
      assert experiment.id
      assert String.contains?(experiment.methodology, "Benchmark")
    end

    test "plan for process domain" do
      hypothesis = %{id: "h3", domain: :process, signal: :process_count, statement: "Process leak.", falsification_criteria: "Tracking shows no leak.", confidence: 0.6, rationale: ""}
      experiment = ExperimentPlanner.plan(hypothesis)
      assert experiment.id
      assert experiment.variables.independent != []
    end

    test "status returns planner info" do
      status = ExperimentPlanner.status()
      assert Map.has_key?(status, :total_planned)
      assert Map.has_key?(status, :last_plan_at)
    end
  end
end
