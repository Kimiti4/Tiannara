defmodule Tiannara.Sentinel.CrossWorldTheoryExperimentTest do
  use ExUnit.Case, async: false

  alias Tiannara.Sentinel.CrossWorldTheoryExperiment
  alias Tiannara.Sentinel.MathematicalEvidence

  setup do
    start_supervised!(MathematicalEvidence)
    :ok
  end

  test "fails closed when no real scenario executor is supplied" do
    {:ok, source} =
      MathematicalEvidence.store(%{
        kind: :scientific_reasoning,
        statement: "candidate theory",
        artifact: %{reasoning_steps: [:a]},
        evidence: %{},
        status: :refuted
      })

    {:ok, transfer} =
      Tiannara.Sentinel.CrossWorldTheoryTransfer.prepare(source, %{world_id: "world-b"})

    scenario = %{
      scenario_id: "scenario-1",
      world_id: "world-b",
      controlled_variables: %{temperature: :held},
      changed_variables: %{energy: 2}
    }

    assert {:error, :cross_world_executor_unavailable} =
             CrossWorldTheoryExperiment.run(transfer, [scenario], nil)
  end

  test "persists each simulated scenario as child evidence without certifying it" do
    {:ok, source} =
      MathematicalEvidence.store(%{
        kind: :scientific_reasoning,
        statement: "candidate theory",
        artifact: %{reasoning_steps: [:a]},
        evidence: %{},
        status: :refuted
      })

    {:ok, transfer} =
      Tiannara.Sentinel.CrossWorldTheoryTransfer.prepare(source, %{
        world_id: "world-b",
        civilization_id: "civ-2"
      })

    scenario = %{
      scenario_id: "scenario-1",
      world_id: "world-b",
      controlled_variables: %{temperature: :held, population: :held},
      changed_variables: %{energy: 2},
      seed: 42
    }

    executor = fn received ->
      assert received.source_evidence_id == source.id
      assert received.execution_mode == :simulation
      assert received.target_world_id == "world-b"

      {:ok, %{
        outcome: :refuted,
        observations: [%{metric: :growth, value: 0.1}],
        counterevidence: [%{metric: :stability, value: 0.0}],
        assumptions_changed: [:energy]
      }}
    end

    assert {:ok, result} = CrossWorldTheoryExperiment.run(transfer, [scenario], executor)
    [scenario_result] = result.scenarios

    assert scenario_result.outcome == :refuted
    assert scenario_result.evidence_id
    assert scenario_result.certification_eligible == false
    assert scenario_result.execution_mode == :simulation
    assert scenario_result.evidence_class == :simulated

    assert {:ok, evidence} = MathematicalEvidence.get(scenario_result.evidence_id)
    assert evidence.parent_ids == [source.id]
    assert evidence.status == :refuted
    assert evidence.evidence.evidence_class == :simulated
    assert evidence.evidence.certification_eligible == false
  end

  test "does not silently continue after a scenario executor failure" do
    {:ok, source} =
      MathematicalEvidence.store(%{
        kind: :scientific_reasoning,
        statement: "candidate theory",
        artifact: %{reasoning_steps: [:a]},
        evidence: %{},
        status: :refuted
      })

    {:ok, transfer} =
      Tiannara.Sentinel.CrossWorldTheoryTransfer.prepare(source, %{world_id: "world-b"})

    scenario = %{
      scenario_id: "scenario-fail",
      world_id: "world-b",
      controlled_variables: %{}
    }

    assert {:error, {:scenario_execution_failed, "scenario-fail", :backend_down}} =
             CrossWorldTheoryExperiment.run(transfer, [scenario], fn _ -> {:error, :backend_down} end)

    assert MathematicalEvidence.list() |> Enum.map(& &1.id) == [source.id]
  end
end
