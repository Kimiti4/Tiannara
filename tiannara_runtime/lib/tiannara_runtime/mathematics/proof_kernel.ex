defmodule TiannaraRuntime.Mathematics.ProofKernel do
  @moduledoc """
  Evidence-bound composition of mathematical arguments.

  A proof object records assumptions, premises, derivation steps and conclusion.
  It is not accepted as proved merely because its shape is valid: each step
  must carry a supported rule or an independently verified sub-proof.
  """

  def new(theorem, assumptions \ []) do
    {:ok, %{theorem: theorem, assumptions: assumptions, premises: [],
            steps: [], conclusion: nil, status: :draft,
            proof_status: :unverified, certification_eligible: false}}
  end

  def add_premise(proof, premise, evidence) when is_map(proof) and is_map(evidence) do
    {:ok, Map.update!(proof, :premises, &(&1 ++ [%{
      statement: premise, evidence: evidence
    }]))}
  end

  def add_step(proof, rule, inputs, output, evidence)
      when is_map(proof) and is_list(inputs) and is_map(evidence) do
    {:ok, Map.update!(proof, :steps, &(&1 ++ [%{
      rule: rule, inputs: inputs, output: output, evidence: evidence
    }]))}
  end

  def conclude(proof, conclusion) when is_map(proof) do
    {:ok, %{proof | conclusion: conclusion, status: :assembled}}
  end

  def verify(proof) when is_map(proof) do
    cond do
      proof.conclusion == nil ->
        {:error, :proof_conclusion_missing}

      proof.steps == [] ->
        {:error, :proof_steps_missing}

      Enum.any?(proof.steps, &not supported_evidence?/1) ->
        {:error, :unsupported_proof_step_evidence}

      true ->
        {:ok, %{proof | status: :verified_structure,
                        proof_status: :independently_verifiable,
                        certification_eligible: false}}
    end
  end

  def verify(_), do: {:error, :proof_object_required}

  defp supported_evidence?(%{evidence: %{status: :proved}}), do: true
  defp supported_evidence?(%{evidence: %{verified: true}}), do: true
  defp supported_evidence?(_), do: false
end
