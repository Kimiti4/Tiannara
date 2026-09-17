defmodule Tiannara.Discovery.Steps.ValidationStepTest do
  use ExUnit.Case, async: false

  alias Tiannara.Discovery.Steps.{ExperimentStep, ValidationStep}
  alias Tiannara.World.UnifiedWorldModel

  setup do
    for mod <- [UnifiedWorldModel] do
      case mod.start_link([]) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
      end
    end

    now = DateTime.utc_now()

    for {id, value} <- [{"exp_a", 42.5}, {"exp_b", 39.1}] do
      {:ok, _} =
        UnifiedWorldModel.create_entity(%{
          id: id,
          type: :fact,
          subtype: :observation,
          domain: :test,
          attributes: %{value: value},
          confidence: 0.6,
          provenance: %{origin: :epistemic_seed, produced_by: :test, produced_at: now}
        })
    end

    :ok
  end

  test "required_capability matches the seeded provider key" do
    assert ValidationStep.required_capability() == :evidence_validation
  end

  test "validates ExperimentStep output and preserves lineage" do
    # Compose the two steps the way the engine will: feed the experiment's
    # evidence into the validator. This proves composition WITHOUT depending
    # on engine chaining.
    {:ok, exp_out} =
      ExperimentStep.execute(%{id: "e1", entity_a: "exp_a", entity_b: "exp_b", tolerance: 1.0}, %{})

    [exp_ev] = exp_out.evidence

    {:ok, val_out} =
      ValidationStep.execute(%{id: "v1", evidence: exp_ev, promotion_threshold: 0.5}, %{})

    [val_ev] = val_out.evidence

    # A decisive, confident measurement validates as promotable.
    assert val_ev.outcome == :confirmed
    assert val_ev.validation.promotable == true

    # LINEAGE: the validation evidence traces back to the experiment evidence.
    assert val_ev.provenance.origin == :validation_step
    assert val_ev.provenance.derived_from.origin == :experiment_step
    assert val_ev.provenance.source_entities == ["exp_a", "exp_b"]
  end

  test "no evidence supplied => inconclusive (degrade, never crash)" do
    {:ok, out} = ValidationStep.execute(%{id: "v2"}, %{})
    [ev] = out.evidence
    assert ev.outcome == :inconclusive
    assert ev.validation.promotable == false
  end

  test "engine-threaded evidence via context is accepted" do
    {:ok, exp_out} =
      ExperimentStep.execute(%{id: "e2", entity_a: "exp_a", entity_b: "exp_b", tolerance: 1.0}, %{})

    [exp_ev] = exp_out.evidence

    {:ok, out} = ValidationStep.execute(%{id: "v3"}, %{last_evidence: exp_ev})
    [ev] = out.evidence
    assert ev.outcome == :confirmed
  end

  test "a decisive but low-confidence measurement is refuted, not promoted" do
    {:ok, out} =
      ValidationStep.execute(
        %{id: "v4", evidence: %{outcome: :confirmed, confidence: 0.2}, promotion_threshold: 0.5},
        %{}
      )

    [ev] = out.evidence
    assert ev.outcome == :refuted
    assert ev.validation.promotable == false
  end
end
