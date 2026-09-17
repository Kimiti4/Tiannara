defmodule Tiannara.Discovery.Steps.ExperimentStepTest do
  use ExUnit.Case, async: false

  alias Tiannara.Discovery.Steps.ExperimentStep
  alias Tiannara.World.UnifiedWorldModel

  setup do
    for mod <- [UnifiedWorldModel] do
      case mod.start_link([]) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
      end
    end

    seed_entity("exp_a", %{value: 42.5})
    seed_entity("exp_b", %{value: 39.1})
    :ok
  end

  defp seed_entity(id, attrs) do
    now = DateTime.utc_now()

    {:ok, _} =
      UnifiedWorldModel.create_entity(%{
        id: id,
        type: :fact,
        subtype: :observation,
        domain: :test,
        attributes: attrs,
        confidence: 0.6,
        provenance: %{origin: :epistemic_seed, produced_by: :test, produced_at: now}
      })
  end

  test "required_capability matches the seeded provider key" do
    assert ExperimentStep.required_capability() == :observation_comparison
  end

  test "produces REAL evidence derived from the seeded values (not canned)" do
    {:ok, output} =
      ExperimentStep.execute(%{id: "s1", entity_a: "exp_a", entity_b: "exp_b", tolerance: 1.0}, %{})

    [ev] = output.evidence

    # Earned-ness: provenance names the producer and the consumed entities.
    assert ev.provenance.origin == :experiment_step
    assert ev.provenance.produced_by == ExperimentStep
    assert ev.source_entities == ["exp_a", "exp_b"]

    # Real-ness: the divergence is the ACTUAL |42.5 - 39.1|, computed, not fixed.
    assert_in_delta ev.measurement.divergence, 3.4, 1.0e-9
    assert ev.measurement.a == 42.5
    assert ev.measurement.b == 39.1

    # The seeded contradiction is real (3.4 > 1.0) => confirmed, confidence >= 0.5.
    assert ev.outcome == :confirmed
    assert ev.confidence >= 0.5
    assert_in_delta ev.uncertainty, 1.0 - ev.confidence, 1.0e-9
    assert output.confidence == ev.confidence
  end

  test "categorical values diverge honestly (equal => refuted, different => confirmed)" do
    seed_entity("cat_a", %{value: "signal"})
    seed_entity("cat_b", %{value: "noise"})

    {:ok, out_a} =
      ExperimentStep.execute(
        %{id: "s2", entity_a: "cat_a", entity_b: "cat_a", tolerance: 0.5},
        %{}
      )

    assert [ev_same] = out_a.evidence
    assert ev_same.outcome == :refuted
    assert ev_same.measurement.divergence == 0.0

    {:ok, out_b} =
      ExperimentStep.execute(
        %{id: "s3", entity_a: "cat_a", entity_b: "cat_b", tolerance: 0.5},
        %{}
      )

    assert [ev_diff] = out_b.evidence
    assert ev_diff.outcome == :confirmed
    assert ev_diff.measurement.divergence == 1.0
  end

  test "missing entity => inconclusive (degrade, no crash)" do
    {:ok, output} =
      ExperimentStep.execute(
        %{id: "s4", entity_a: "exp_a", entity_b: "no_such_entity", tolerance: 1.0},
        %{}
      )

    [ev] = output.evidence
    assert ev.outcome == :inconclusive
    assert ev.measurement.divergence == nil
    assert ev.confidence == 0.0
  end

  test "inputs-list fallback matches the scheduler's experiment spec shape" do
    {:ok, output} =
      ExperimentStep.execute(%{id: "s5", inputs: ["exp_a", "exp_b"], tolerance: 1.0}, %{})

    [ev] = output.evidence
    assert ev.source_entities == ["exp_a", "exp_b"]
    assert_in_delta ev.measurement.divergence, 3.4, 1.0e-9
  end
end
