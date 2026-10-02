defmodule Tiannara.Sentinel.CrossWorldEvidenceSynthesis do
  alias Tiannara.Sentinel.TheoryValidationGate
  alias Tiannara.Sentinel.ValidationEvidenceEnvelope
  @moduledoc """
  Synthesizes evidence for one theory across worlds/scenarios without
  collapsing conditional results into a universal truth claim.

  Supported and refuted results are retained with their assumptions and
  boundary conditions. Mixed or conflicting evidence remains explicit.
  The synthesis is never certification-eligible until independently audited
  by ACL and OAVL.
  """

  @spec synthesize(map(), [map()]) :: {:ok, map()} | {:error, term()}
  def synthesize(theory, results) when is_map(theory) and is_list(results) do
    with :ok <- validate_results(results),
         :ok <- validate_audits(results),
         {:ok, groups} <- group_results(results) do
      status = classify(groups)

      {:ok, %{
        theory: theory,
        status: status,
        supporting_evidence: groups.supported,
        refuting_evidence: groups.refuted,
        inconclusive_evidence: groups.inconclusive,
        assumptions: assumptions(results),
        boundary_conditions: boundary_conditions(results),
        contradictions_preserved: groups.supported != [] and groups.refuted != [],
        evidence_count: length(results),
        certification_eligible: false,
        audit_required: [:acl, :oavl],
        epistemic_rule: :conditional_results_are_not_universal_truth
      }}
    end
  end

  def synthesize(_, _), do: {:error, :invalid_cross_world_evidence}

  @doc """
  Audits the aggregate synthesis itself. Scenario-level ACL/OAVL results are
  necessary but are not sufficient: grouping, contradiction preservation,
  assumptions, and boundary conditions form a new evidence object and must be
  independently validated before any downstream promotion.
  """
  @spec audit_synthesis(map(), map(), (map() -> term()) | nil, (map() -> term()) | nil) ::
          {:ok, map()} | {:error, term()}
  def audit_synthesis(theory, synthesis, acl_validator, oavl_validator)
      when is_map(theory) and is_map(synthesis) do
    evidence = %{
      evidence_id: Map.get(synthesis, :evidence_id, "synthesis:" <> Integer.to_string(:erlang.phash2(synthesis))),
      theory_id: Map.get(theory, :id, Map.get(theory, :theory_id, :unknown)),
      outcome: synthesis_outcome(synthesis.status),
      observations: Map.get(synthesis, :supporting_evidence, []),
      counterevidence: Map.get(synthesis, :refuting_evidence, []),
      assumptions: Map.get(synthesis, :assumptions, []),
      provenance: %{
        source: :cross_world_evidence_synthesis,
        evidence_count: Map.get(synthesis, :evidence_count, 0),
        contradictions_preserved: Map.get(synthesis, :contradictions_preserved, false),
        boundary_conditions: Map.get(synthesis, :boundary_conditions, [])
      },
      execution_mode: :simulation,
      evidence_class: :simulated
    }

    with {:ok, envelope} <- ValidationEvidenceEnvelope.build(evidence),
         {:ok, audit} <- TheoryValidationGate.validate(envelope, acl_validator, oavl_validator) do
      {:ok, Map.merge(synthesis, %{
        validation_audit: audit,
        audit_required: [],
        certification_eligible: false
      })}
    end
  end

  defp validate_results([]), do: {:error, :cross_world_evidence_required}
  defp validate_results(results) do
    if Enum.all?(results, &valid_result?/1), do: :ok, else: {:error, :invalid_cross_world_result}
  end

  defp valid_result?(r) when is_map(r) do
    Map.get(r, :outcome) in [:supported, :refuted, :inconclusive, :mixed] and
      is_map(Map.get(r, :validation_audit, %{}))
  end
  defp valid_result?(_), do: false

  defp validate_audits(results) do
    if Enum.all?(results, fn r ->
         audit = Map.get(r, :validation_audit, %{})
         is_map(audit) and Map.get(audit, :audited) == true and
           is_map(Map.get(audit, :acl)) and is_map(Map.get(audit, :oavl))
       end), do: :ok, else: {:error, :acl_oavl_audit_required}
  end

  defp group_results(results) do
    {:ok, %{
      supported: Enum.filter(results, &(&1.outcome == :supported)),
      refuted: Enum.filter(results, &(&1.outcome == :refuted)),
      inconclusive: Enum.filter(results, &(&1.outcome in [:inconclusive, :mixed]))
    }}
  end

  defp classify(%{supported: s, refuted: r}) when s != [] and r != [], do: :conditional_or_conflicting
  defp classify(%{supported: s}) when s != [], do: :supported_under_tested_conditions
  defp classify(%{refuted: r}) when r != [], do: :refuted_under_tested_conditions
  defp classify(_), do: :inconclusive

  defp assumptions(results) do
    results
    |> Enum.flat_map(&(Map.get(&1, :assumptions_held, []) ++ Map.get(&1, :assumptions_changed, [])))
    |> Enum.uniq()
  end

  defp boundary_conditions(results) do
    results
    |> Enum.flat_map(fn r ->
      [
        Map.get(r, :controlled_variables, %{}),
        Map.get(r, :changed_variables, %{})
      ]
    end)
    |> Enum.reject(&(&1 == %{}))
    |> Enum.uniq()
  end
end

  defp synthesis_outcome(:supported_under_tested_conditions), do: :supported
  defp synthesis_outcome(:refuted_under_tested_conditions), do: :refuted
  defp synthesis_outcome(:conditional_or_conflicting), do: :mixed
end
