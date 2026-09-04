defmodule Tiannara.Forecasting.AlternativeHistory do
  @moduledoc """
  D4 alternative-history bundles: a bounded distribution of counterfactual
  branches for one decision.

  A bundle is generated from a D3 `Decision` (read-only; the decision's
  snapshot is captured for the `baseline_state_ref` content hash) and ALWAYS
  includes the no-action alternative, so a consequential decision is never
  reduced to a cherry-picked single counterfactual.

  Constitutional rules:
    - bundles are bounded (`max_alternatives`, default 8); excess alternatives
      are recorded in `excluded_alternatives` with deterministic reasons.
    - every element is a non-observed counterfactual record; the bundle never
      fabricates an observed status.
    - adding past the bound returns `{:error, :alternatives_exceeded}`.
  """

  alias Tiannara.Forecasting.{Counterfactual, DecisionSnapshot}
  alias Tiannara.Forecasting.Contracts.{AlternativeHistoryBundle, InterventionSpec, Decision, CounterfactualRecord}

  @default_max_alternatives 8

  @type t :: AlternativeHistoryBundle.t()

  @spec new(Decision.t(), map() | Keyword.t()) :: AlternativeHistoryBundle.t()
  def new(%Decision{} = d, opts \\ []) when is_map(opts) or is_list(opts) do
    o = Map.new(opts)
    max_alts = Map.get(o, :max_alternatives, @default_max_alternatives)
    snapshot = DecisionSnapshot.capture(d)
    baseline = baseline_ref(snapshot)

    {alts, excluded} = build_alternatives(d, max_alts)
    includes_do_nothing = includes_do_nothing?(alts, max_alts, d)

    %AlternativeHistoryBundle{
      bundle_id:
        "bundle_" <>
          (:crypto.hash(:sha256, :erlang.term_to_binary({d.id, baseline})) |> Base.encode16(case: :lower)),
      decision_id: d.id,
      baseline_state_ref: baseline,
      alternatives: alts,
      includes_do_nothing: includes_do_nothing,
      excluded_alternatives: excluded,
      max_alternatives: max_alts,
      created_at: DateTime.utc_now()
    }
  end

  @spec add_alternative(AlternativeHistoryBundle.t(), CounterfactualRecord.t()) ::
          {:ok, AlternativeHistoryBundle.t()} | {:error, term()}
  def add_alternative(%AlternativeHistoryBundle{} = b, %CounterfactualRecord{} = cf) do
    if length(b.alternatives) >= b.max_alternatives do
      {:error, :alternatives_exceeded}
    else
      {:ok,
       %AlternativeHistoryBundle{
         b
         | alternatives: b.alternatives ++ [Counterfactual.enforce_observability_boundary(cf)]
       }}
    end
  end

  @doc """
  Extracts the alternatives a decision would have produced, presenting each as
  an explicit non-observed counterfactual record.
  """
  @spec alternatives(Decision.t()) :: [CounterfactualRecord.t()]
  def alternatives(%Decision{} = d) do
    snap = DecisionSnapshot.capture(d)

    Enum.map(d.alternatives, fn a ->
      Counterfactual.new(%{
        intervention: intervention_for(a),
        expected_outcomes: %{distribution: a.probabilities, point_estimate: point_estimate(a)},
        reference: %{d3_decision_snapshot_id: snap.decision_id},
        affected_variables: [],
        provenance: %{derived_from: :decision_alternatives}
      })
    end)
  end

  # ------------------------------------------------------------------
  # Helpers
  # ------------------------------------------------------------------

  defp build_alternatives(%Decision{} = d, max_alts) do
    records = ensure_do_nothing(alternatives(d))

    taken = Enum.take(records, max_alts)
    excluded =
      records
      |> Enum.drop(max_alts)
      |> Enum.map(fn cf -> %{id: cf.intervention.kind, reason: :max_alternatives_exceeded} end)

    {taken, excluded}
  end

  defp ensure_do_nothing(records) do
    if Enum.any?(records, fn cf -> cf.intervention.kind == :do_nothing end) do
      records
    else
      records ++
        [
          Counterfactual.new(%{
            intervention: %InterventionSpec{kind: :do_nothing, target_variables: [],
                                            description: "no action"},
            reference: %{provided_by: :alternative_history},
            expected_outcomes: %{distribution: :unknown}
          })
        ]
    end
  end

  defp includes_do_nothing?(alts, _max_alts, _d) do
    Enum.any?(alts, fn cf -> cf.intervention.kind == :do_nothing end)
  end

  defp baseline_ref(snapshot) do
    "baseline_" <>
      (:crypto.hash(:sha256, :erlang.term_to_binary(snapshot)) |> Base.encode16(case: :lower))
  end

  defp intervention_for(%{id: :do_nothing}) do
    %InterventionSpec{kind: :do_nothing, target_variables: [], description: "no action"}
  end

  defp intervention_for(a) do
    %InterventionSpec{
      kind: :policy,
      target_variables: [],
      description: "alternative #{a.label || a.id}"
    }
  end

  defp point_estimate(%{probabilities: :unknown}), do: :unknown
  defp point_estimate(%{probabilities: nil}), do: :unknown

  defp point_estimate(%{probabilities: p, utilities: u}) when is_list(p) and is_list(u) do
    expected = p |> Enum.zip(u) |> Enum.reduce(0.0, fn {pi, ui}, acc -> acc + pi * ui end)
    expected
  end

  defp point_estimate(_), do: :unknown
end