defmodule TiannaraRuntime.WorldModel.Pipeline.PipelineOrchestratorTest do
  use ExUnit.Case, async: false

  alias TiannaraRuntime.WorldModel.Pipeline.PipelineOrchestrator
  alias TiannaraRuntime.WorldModel.ModelRegistry
  alias TiannaraRuntime.AutonomousResearch.Phase16_1.ObservationRegistry

  setup do
    ModelRegistry.reset_table()
    ObservationRegistry.init_table()
    :ets.delete_all_objects(:observation_registry)
    :ok
  end

  describe "run_pipeline/1" do
    test "runs full pipeline end-to-end" do
      ObservationRegistry.register_observation(
        %{"source" => "sensor_a", "domain" => "physics"},
        %{"temperature" => 25.0, "pressure" => 1013},
        "2026-06-01T12:00:00Z"
      )

      ObservationRegistry.register_observation(
        %{"source" => "sensor_b", "domain" => "physics"},
        %{"temperature" => 30.0, "pressure" => 1015},
        "2026-06-01T13:00:00Z"
      )

      {:ok, result} = PipelineOrchestrator.run_pipeline(
        domain: :physics,
        name: "Physics Test Model"
      )

      assert result.evidence_set.observation_count == 2
      assert length(result.variable_set.variables) == 2
      assert result.structure_output.causal_graph.nodes != []
      assert result.equation_output.equation_system.equations != []
      assert result.model.name == "Physics Test Model"
      assert result.model.status == :draft
      assert result.validation_metrics != []
      assert result.certificate.overall_status == :pass

      {:ok, stored} = ModelRegistry.get_latest_model(result.model.model_id)
      assert stored.status == :operational
    end

    test "handles empty observations" do
      {:ok, result} = PipelineOrchestrator.run_pipeline(
        domain: :physics,
        name: "Empty Model"
      )

      assert result.evidence_set.observation_count == 0
      assert result.variable_set.variables == []
      assert result.model.status == :draft
    end
  end
end
