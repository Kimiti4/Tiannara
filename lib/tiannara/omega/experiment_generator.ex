defmodule Tiannara.Omega.ExperimentGenerator do
  @moduledoc """
  Turns a research proposal (from the evidence-driven Research Director) into a
  concrete, falsifiable experiment specification.

  The experiment generator DESIGNS experiments; it does not execute them, and
  it does not generate the final patch. It produces a specification that the
  PatchGenerator consumes.

  Constitutional basis: Scientific Method, "Evidence Before Confidence",
  Modularity (clear responsibility: design, not execution).
  """

  alias Tiannara.Omega.ExperimentSpec

  @callback design(proposal :: map(), context :: map()) ::
              {:ok, ExperimentSpec.t()} | {:error, term()}

  @doc """
  Reference implementation: designs an experiment from a proposal by extracting
  the hypothesis, prediction, and falsifier, and structuring them into a
  testable specification.
  """
  def design(proposal, _context \\ %{}) do
    hypothesis_id = Map.get(proposal, :hypothesis_id)
    statement = Map.get(proposal, :statement, "")
    falsifier = Map.get(proposal, :falsifier)

    if is_nil(hypothesis_id) do
      {:error, :missing_hypothesis}
    else
      {:ok,
       %ExperimentSpec{
         id: make_id(),
         proposal_id: Map.get(proposal, :id),
         hypothesis_id: hypothesis_id,
         statement: statement,
         prediction: derive_prediction(statement),
         falsifier: falsifier,
         method: derive_method(proposal),
         success_criteria: derive_success_criteria(proposal),
         lineage: [Map.get(proposal, :id), hypothesis_id]
       }}
    end
  end

  defp derive_prediction(statement) do
    # Reference: the prediction is the hypothesis's expected observable outcome.
    "If #{statement}, then the measured outcome matches the expected value."
  end

  defp derive_method(proposal) do
    # Reference: derive the experiment method from the proposal's type/subject.
    case Map.get(proposal, :type, :default) do
      :performance -> :benchmark_before_after
      :correctness -> :run_test_suite
      :memory -> :measure_memory_delta
      _ -> :controlled_comparison
    end
  end

  defp derive_success_criteria(proposal) do
    # Reference: success is defined by the falsifier NOT being observed.
    [%{criterion: "falsifier not observed", source: Map.get(proposal, :falsifier)}]
  end

  defp make_id, do: :"exp-#{System.unique_integer([:monotonic])}"
end