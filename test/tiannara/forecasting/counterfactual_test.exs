defmodule Tiannara.Forecasting.CounterfactualTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.{Counterfactual, Decision}
  alias Tiannara.Forecasting.Contracts.{Alternative, CounterfactualRecord, InterventionSpec}

  defp observed_counterfactual do
    Counterfactual.new(%{
      intervention: %InterventionSpec{kind: :observe_only, target_variables: [],
                                      description: "observe X without setting it"},
      reference: %{baseline_state_ref: "blob_abc"},
      status: :observed
    })
  end

  test "status ontology is first-class and never collapsed to boolean" do
    assert :unknown in Counterfactual.statuses()
    assert :underdetermined in Counterfactual.statuses()
    assert :invalid in Counterfactual.statuses()
    refute Counterfactual.known?(:unknown)
    refute Counterfactual.known?(:underdetermined)
  end

  test "observed status is assignable only via D1 path; D4 cannot construct one" do
    boundary = Counterfactual.enforce_observability_boundary(observed_counterfactual())
    assert boundary.status != :observed
    assert Counterfactual.assignable_by_d4?(:observed) == false
    assert {:error, :observed_not_assignable_by_d4} = Counterfactual.validate(observed_counterfactual())
  end

  test "new/1 produces a HYPOTHETICAL record by default with a content-id" do
    cf = Counterfactual.new(%{
      intervention: %InterventionSpec{kind: :set, target_variables: [:x], value: 1}
    })
    assert cf.status == :hypothetical
    assert String.starts_with?(cf.counterfactual_id, "cf_")
    assert {:ok, _} = Counterfactual.validate(cf)
  end

  test "an observe-only spec is structurally incapable of claiming an intervention effect" do
    cf = Counterfactual.new(%{
      intervention: %InterventionSpec{kind: :observe_only, target_variables: [:x],
                                      description: "no causal claim"}
    })
    assert cf.intervention.kind == :observe_only
    assert {:ok, _} = Counterfactual.validate(cf)
  end

  test "branch/2 creates a child referencing its parent by content hash, never merged" do
    parent = Counterfactual.new(%{
      intervention: %InterventionSpec{kind: :set, target_variables: [:x], value: 1},
      reference: %{baseline_state_ref: "blob_abc"}
    })
    child = Counterfactual.branch(parent, %{intervention: %InterventionSpec{kind: :defer}})
    assert child.parent_ref == Counterfactual.content_ref(parent)
    refute child.counterfactual_id == parent.counterfactual_id
    assert child.status == :counterfactual
  end

  test "validate rejects a non-intervention record and invalid outcomes" do
    assert {:error, :missing_or_invalid_intervention} =
             Counterfactual.validate(%CounterfactualRecord{counterfactual_id: "x", status: :hypothetical})
  end
end