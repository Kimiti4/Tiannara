defmodule Tiannara.Autonomy.DeploymentPipelineTest do
  use ExUnit.Case, async: false

  alias Tiannara.Autonomy.DeploymentPipeline

  defp sample_simulation(opts \\ []) do
    %{
      id: "sim_#{System.unique_integer([:positive])}",
      proposal_id: "prop_#{System.unique_integer([:positive])}",
      proposal: %{
        human_approval_required: opts[:human_required] || false,
        id: "prop_#{System.unique_integer([:positive])}"
      },
      improvement_ratio: 1.2,
      verdict: :pass
    }
  end

  describe "deploy" do
    test "deploys without human approval and proceeds to monitoring" do
      assert {:ok, id} = DeploymentPipeline.deploy(sample_simulation(human_required: false))
      assert is_binary(id)
    end

    test "deploys with human approval and stays in pending_approval" do
      sim = sample_simulation(human_required: true)
      assert {:ok, _id} = DeploymentPipeline.deploy(sim)
    end
  end

  describe "approve" do
    test "approves a pending deployment and proceeds" do
      sim = sample_simulation(human_required: true)
      assert {:ok, id} = DeploymentPipeline.deploy(sim)
      assert :ok = DeploymentPipeline.approve(id, :test_operator)
    end

    test "returns error for unknown id" do
      assert {:error, :not_found} = DeploymentPipeline.approve("invalid", :test)
    end

    test "returns error for wrong stage" do
      sim = sample_simulation(human_required: false)
      assert {:ok, id} = DeploymentPipeline.deploy(sim)
      assert {:error, {:invalid_stage, _}} = DeploymentPipeline.approve(id, :test)
    end
  end

  describe "reject" do
    test "rejects a deployment" do
      sim = sample_simulation(human_required: false)
      assert {:ok, id} = DeploymentPipeline.deploy(sim)
      assert :ok = DeploymentPipeline.reject(id, :operator, "Not ready")
    end

    test "returns error for unknown id" do
      assert {:error, :not_found} = DeploymentPipeline.reject("invalid", :operator, "reason")
    end
  end

  describe "metrics" do
    test "active_count returns correct count" do
      before = DeploymentPipeline.active_count()
      DeploymentPipeline.deploy(sample_simulation(human_required: false))
      assert DeploymentPipeline.active_count() == before + 1
    end

    test "total_deployed returns count" do
      before = DeploymentPipeline.total_deployed()
      DeploymentPipeline.deploy(sample_simulation())
      assert DeploymentPipeline.total_deployed() == before + 1
    end
  end

  describe "status" do
    test "returns metrics" do
      status = DeploymentPipeline.status()
      assert is_integer(status.total_deployed)
      assert is_integer(status.total_promoted)
      assert is_integer(status.total_rolled_back)
      assert is_integer(status.total_rejected)
    end
  end
end
