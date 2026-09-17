defmodule Tiannara.ASC.Reality.PhysicalDeploymentPropertyTest do
  use ExUnit.Case, async: false
  use ExUnitProperties

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
    :ok
  end

  property "no deployment advances past the human approval gate without a decision" do
    check all(design <- design_generator(), max_runs: 20) do
      {:ok, deployment} = PDM.plan(design)

      assert {:ok, %{stage: :safety_reviewed}} = PDM.advance(deployment.id)
      assert {:ok, %{stage: :pending_approval}} = PDM.advance(deployment.id)

      assert {:error, :requires_human_approval} = PDM.advance(deployment.id)
      assert PDM.get_deployment(deployment.id).stage == :pending_approval
    end
  end

  property "execution stages are unreachable without an approved decision" do
    check all(design <- design_generator(), max_runs: 20) do
      {:ok, deployment} = PDM.plan(design)

      # machine attempts to push through without any human decision
      for _ <- 1..8 do
        PDM.advance(deployment.id)
      end

      final = PDM.get_deployment(deployment.id)
      assert final.stage == :pending_approval
      refute final.stage in [:dry_run, :supervised, :autonomous, :completed]
    end
  end

  property "an approved deployment completes the lifecycle in order" do
    check all(design <- design_generator(), max_runs: 20) do
      {:ok, deployment} = PDM.plan(design)
      PDM.advance(deployment.id)
      PDM.advance(deployment.id)

      assert {:ok, %{approval: %{decision: :approved}}} =
               PDM.approve(deployment.id, "property-approver", "property test")

      assert {:ok, %{stage: :approved}} = PDM.advance(deployment.id)
      assert {:ok, %{stage: :simulated}} = PDM.advance(deployment.id)
      assert {:ok, _} = PDM.execute(deployment.id, %{action: :calibrate})

      for expected <- [:dry_run, :supervised, :autonomous, :completed] do
        assert {:ok, %{stage: ^expected}} = PDM.advance(deployment.id)
      end

      assert {:error, :invalid_transition} = PDM.advance(deployment.id)
    end
  end

  property "abort and reject are terminal for any design" do
    check all(design <- design_generator(), max_runs: 20) do
      {:ok, deployment} = PDM.plan(design)

      assert {:ok, %{stage: :aborted}} = PDM.abort(deployment.id, "property abort")
      assert {:error, :terminal_stage} = PDM.advance(deployment.id)

      {:ok, rejected_design} = PDM.plan(design)
      PDM.advance(rejected_design.id)
      PDM.advance(rejected_design.id)
      assert {:ok, %{stage: :rejected}} = PDM.reject(rejected_design.id, "prop", "no")
      assert {:error, :terminal_stage} = PDM.advance(rejected_design.id)

      SimulatedAdapter.clear_estop()
    end
  end

  defp design_generator do
    gen all(
          name <- string(:alphanumeric, min_length: 1, max_length: 12),
          steps <- list_of(atom(:alphanumeric), min_length: 1, max_length: 6)
        ) do
      %{name: name, type: :physical, steps: steps}
    end
  end
end
