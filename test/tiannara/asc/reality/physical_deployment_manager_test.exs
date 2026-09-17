defmodule Tiannara.ASC.Reality.PhysicalDeploymentManagerTest do
  use ExUnit.Case, async: false

  alias Tiannara.ASC.Reality.Adapters.SimulatedAdapter
  alias Tiannara.ASC.Reality.PhysicalDeploymentManager, as: PDM
  alias Tiannara.ASC.Reality.SafetyVerificationEngine

  setup do
    for mod <- [PDM, SimulatedAdapter, SafetyVerificationEngine] do
      case mod.start_link([]) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
      end
    end

    SimulatedAdapter.clear_estop()

    %{
      design: %{
        name: "unit-test-rig",
        type: :physical,
        steps: [:calibrate, :initialize, :run_diagnostics, :deploy_firmware]
      }
    }
  end

  defp plan_and_gate(design) do
    {:ok, deployment} = PDM.plan(design)
    {:ok, %{stage: :safety_reviewed}} = PDM.advance(deployment.id)
    {:ok, %{stage: :pending_approval}} = PDM.advance(deployment.id)
    deployment
  end

  describe "plan/1" do
    test "creates a planned deployment with safety verification", %{design: design} do
      assert {:ok, deployment} = PDM.plan(design)

      assert deployment.stage == :planned
      assert deployment.safety_verification.passed == true
      assert deployment.plan.steps == design.steps
      assert deployment.summary.safety == length(deployment.safety_verification.checks)
      assert deployment.summary.steps == length(design.steps)
      assert deployment.approval == nil
      assert deployment.estop_active == false
      assert deployment.execution_log == []
      assert deployment.stage_times[:planned] != nil
      assert deployment.adapter == SimulatedAdapter
    end

    test "derives default steps when the design has none" do
      assert {:ok, deployment} = PDM.plan(%{name: "bare", type: :physical})
      assert is_list(deployment.plan.steps)
      assert length(deployment.plan.steps) > 0
    end

    test "rejects designs with an invalid step list" do
      assert {:error, :invalid_steps} = PDM.plan(%{name: "bad", steps: %{a: 1}})
    end

    test "rejects designs with empty step list" do
      assert {:error, :invalid_steps} = PDM.plan(%{name: "empty", steps: []})
    end
  end

  describe "staged lifecycle" do
    test "advances planned -> safety_reviewed -> pending_approval", %{design: design} do
      {:ok, deployment} = PDM.plan(design)

      assert {:ok, %{stage: :safety_reviewed}} = PDM.advance(deployment.id)
      assert {:ok, %{stage: :pending_approval}} = PDM.advance(deployment.id)

      final = PDM.get_deployment(deployment.id)
      assert final.stage_times[:safety_reviewed] != nil
      assert final.stage_times[:pending_approval] != nil
    end

    test "human approval gate blocks machine advance", %{design: design} do
      deployment = plan_and_gate(design)
      assert {:error, :requires_human_approval} = PDM.advance(deployment.id)
      assert PDM.get_deployment(deployment.id).stage == :pending_approval
    end

    test "approve -> simulated -> dry_run -> supervised -> autonomous -> completed", %{
      design: design
    } do
      deployment = plan_and_gate(design)

      assert {:ok, %{approval: %{decision: :approved}}} =
               PDM.approve(deployment.id, "tiannara-admin", "sim approved")

      {:ok, %{stage: :approved}} = PDM.advance(deployment.id)
      {:ok, %{stage: :simulated}} = PDM.advance(deployment.id)
      {:ok, %{stage: :dry_run}} = PDM.advance(deployment.id)
      {:ok, %{stage: :supervised}} = PDM.advance(deployment.id)

      assert {:error, :simulation_not_active} = PDM.advance(deployment.id)
      assert {:ok, _} = PDM.execute(deployment.id, %{action: :actuate})
      {:ok, %{stage: :autonomous}} = PDM.advance(deployment.id)
      {:ok, completed} = PDM.advance(deployment.id)

      assert completed.stage == :completed
      assert completed.stage_times[:completed] != nil
    end

    test "advance on an unknown deployment returns not_found" do
      assert {:error, :not_found} = PDM.advance("phys-missing")
    end
  end

  describe "approval controls" do
    test "approve is only allowed at pending_approval", %{design: design} do
      {:ok, deployment} = PDM.plan(design)
      assert {:error, :wrong_stage} = PDM.approve(deployment.id, "admin", "too early")
    end

    test "reject sends the deployment to the rejected terminal stage", %{design: design} do
      deployment = plan_and_gate(design)

      assert {:ok, rejected} =
               PDM.reject(deployment.id, "tiannara-admin", "insufficient evidence")

      assert rejected.stage == :rejected
      assert rejected.approval.decision == :rejected
      assert rejected.approval.approver == "tiannara-admin"

      assert {:error, :terminal_stage} = PDM.advance(deployment.id)
    end

    test "reject is only allowed at pending_approval", %{design: design} do
      {:ok, deployment} = PDM.plan(design)
      assert {:error, :wrong_stage} = PDM.reject(deployment.id, "admin", "nope")
    end
  end

  describe "execution" do
    test "execute forwards actions to the adapter and logs them", %{design: design} do
      deployment = plan_and_gate(design)
      PDM.approve(deployment.id, "admin", "ok")
      PDM.advance(deployment.id)
      PDM.advance(deployment.id)

      assert {:ok, updated} =
               PDM.execute(deployment.id, %{action: :calibrate, payload: %{axes: 3}})

      assert length(updated.execution_log) == 1

      assert updated.execution_log |> hd() |> Map.fetch!(:action) == %{
               action: :calibrate,
               payload: %{axes: 3}
             }

      adapter_status = SimulatedAdapter.status()
      assert adapter_status.executed_actions >= 1
      assert adapter_status.active == true
    end

    test "execute is not authorized in early stages", %{design: design} do
      {:ok, deployment} = PDM.plan(design)
      assert {:error, :not_authorized} = PDM.execute(deployment.id, %{action: :calibrate})

      {:ok, %{stage: :safety_reviewed}} = PDM.advance(deployment.id)
      assert {:error, :not_authorized} = PDM.execute(deployment.id, %{action: :calibrate})
    end

    test "execute on an unknown deployment returns not_found" do
      assert {:error, :not_found} = PDM.execute("phys-missing", %{action: :calibrate})
    end
  end

  describe "emergency controls" do
    test "emergency_stop engages the adapter estop and blocks execution", %{design: design} do
      deployment = plan_and_gate(design)
      PDM.approve(deployment.id, "admin", "ok")
      PDM.advance(deployment.id)
      PDM.advance(deployment.id)

      assert {:ok, stopped} = PDM.emergency_stop(deployment.id)
      assert stopped.estop_active == true
      assert SimulatedAdapter.status().mode == :estop

      assert {:error, :estop_active} = PDM.execute(deployment.id, %{action: :calibrate})
      assert {:error, :estop_active} = PDM.advance(deployment.id)

      on_exit(fn -> SimulatedAdapter.clear_estop() end)
    end

    test "resume clears the emergency stop", %{design: design} do
      deployment = plan_and_gate(design)
      PDM.approve(deployment.id, "admin", "ok")
      PDM.advance(deployment.id)
      PDM.advance(deployment.id)

      PDM.emergency_stop(deployment.id)
      assert {:ok, resumed} = PDM.resume(deployment.id)
      assert resumed.estop_active == false
      assert SimulatedAdapter.status().mode == :idle

      assert {:ok, _} = PDM.execute(deployment.id, %{action: :calibrate})
    end

    test "abort sends the deployment to the aborted terminal stage", %{design: design} do
      deployment = plan_and_gate(design)

      assert {:ok, aborted} = PDM.abort(deployment.id, "power failure")
      assert aborted.stage == :aborted
      assert aborted.abort_reason == "power failure"
      assert aborted.estop_active == true
      assert SimulatedAdapter.status().mode == :estop

      assert {:error, :terminal_stage} = PDM.advance(deployment.id)
      assert {:error, :estop_active} = PDM.execute(deployment.id, %{action: :calibrate})

      on_exit(fn -> SimulatedAdapter.clear_estop() end)
    end
  end

  describe "accessors" do
    test "get_deployment and list_deployments", %{design: design} do
      {:ok, deployment} = PDM.plan(design)

      assert PDM.get_deployment(deployment.id).id == deployment.id
      assert PDM.get_deployment("phys-missing") == nil
      assert Enum.any?(PDM.list_deployments(), fn d -> d.id == deployment.id end)
    end

    test "adapter_info returns capabilities and status", %{design: design} do
      {:ok, deployment} = PDM.plan(design)

      assert {:ok, info} = PDM.adapter_info(deployment.id)
      assert info.capabilities.hardware == :simulated
      assert info.capabilities.estop_supported == true
      assert is_integer(info.status.estop_count)
      assert is_boolean(info.status.active)

      assert {:error, :not_found} = PDM.adapter_info("phys-missing")
    end
  end

  describe "pure plan helpers" do
    test "build_plan returns an ok plan with steps and params" do
      design = %{name: "rig", steps: [:a, :b], params: %{location: :lab}}
      assert {:ok, plan} = PDM.build_plan(design)
      assert plan.steps == [:a, :b]
      assert plan.params == %{location: :lab}
    end

    test "derive_steps returns design steps when present, defaults otherwise" do
      assert PDM.derive_steps(%{steps: [:a, :b]}) == [:a, :b]
      assert PDM.derive_steps(%{}) |> is_list()
      assert PDM.derive_steps(%{steps: []}) |> length() > 0
    end
  end
end
