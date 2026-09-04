defmodule Tiannara.Forecasting.Counterfactual do
  @moduledoc """
  D4 counterfactual status ontology: a labeled analytical record, never a fact.

  A counterfactual is built against an immutable baseline (`baseline_state_ref`,
  a content hash) and branches from it; baselines are never mutated and no merge
  operation exists. The status ontology is first-class and never collapsed to a
  boolean: `UNKNOWN`, `UNDERDETERMINED`, and `INVALID` are distinct from `0.0`
  or `false`.

  Constitutional rules:
    - `:observed` is assignable ONLY via the D1 ingestion path. D4 analysis can
      never construct or promote a record to `:observed`.
    - an `InterventionSpec` must be explicit; OBSERVE_ONLY records are
      structurally incapable of claiming an intervention effect.
    - `branch/2` appends a child that references its parent by content hash;
      history is never rewritten.
  """

  alias Tiannara.Forecasting.Contracts.{CounterfactualRecord, InterventionSpec}

  @schema_version 1

  @statuses [
    :observed,
    :hypothetical,
    :counterfactual,
    :supported,
    :weakly_supported,
    :underdetermined,
    :invalid,
    :unknown
  ]

  @analysis_statuses [
    :hypothetical,
    :counterfactual,
    :supported,
    :weakly_supported,
    :underdetermined,
    :unknown
  ]

  @type t :: CounterfactualRecord.t()

  # ------------------------------------------------------------------
  # Construction
  # ------------------------------------------------------------------

  @spec new(map() | CounterfactualRecord.t()) :: CounterfactualRecord.t()
  def new(attrs) when is_map(attrs) or is_list(attrs) do
    m = normalize_map(attrs)
    intervention = Map.get(m, :intervention)
    now = Map.get(m, :created_at) || DateTime.utc_now()

    st =
      case Map.get(m, :status, :hypothetical) do
        nil -> :hypothetical
        s -> s
      end

    %CounterfactualRecord{
      counterfactual_id:
        Map.get(m, :counterfactual_id) ||
          "cf_" <> (:crypto.hash(:sha256, :erlang.term_to_binary(m)) |> Base.encode16(case: :lower)),
      schema_version: Map.get(m, :schema_version, @schema_version),
      status: st,
      intervention: intervention,
      parent_ref: Map.get(m, :parent_ref),
      assumptions: Map.get(m, :assumptions, %{}),
      affected_variables: Map.get(m, :affected_variables, []),
      expected_outcomes: Map.get(m, :expected_outcomes, %{}),
      uncertainty: Map.get(m, :uncertainty, %{}),
      provenance: Map.get(m, :provenance, %{}),
      reference: Map.get(m, :reference, %{}),
      created_at: now
    }
  end

  @spec validate(CounterfactualRecord.t()) :: {:ok, CounterfactualRecord.t()} | {:error, term()}
  def validate(%CounterfactualRecord{} = r) do
    cond do
      r.status not in @statuses ->
        {:error, :invalid_status}

      r.status == :observed ->
        {:error, :observed_not_assignable_by_d4}

      not valid_intervention?(r.intervention) ->
        {:error, :missing_or_invalid_intervention}

      not has_baseline?(r.reference) and is_nil(r.counterfactual_id) ->
        {:error, :missing_baseline}

      not valid_outcomes?(r.expected_outcomes) ->
        {:error, :invalid_expected_outcomes}

      true ->
        {:ok, normalize_validated(r)}
    end
  end

  @doc """
  Branches a child counterfactual from an immutable baseline. The child carries
  `parent_ref` = content hash of the parent and a fresh id. No merge, no
  promotion to `:observed`.
  """
  @spec branch(CounterfactualRecord.t(), map() | Keyword.t()) :: CounterfactualRecord.t()
  def branch(%CounterfactualRecord{} = parent, attrs) when is_map(attrs) or is_list(attrs) do
    u = Map.new(attrs)

    new(Map.merge(Map.from_struct(parent) |> Map.take(branchable_fields()), u)
        |> Map.put(:parent_ref, content_ref(parent))
        |> Map.put(:status, Map.get(u, :status, counterfactual_status(parent))))
  end

  @doc """
  Content hash of a record (parent ref / baseline identity).
  """
  @spec content_ref(CounterfactualRecord.t()) :: String.t()
  def content_ref(%CounterfactualRecord{} = r) do
    canonical =
      r
      |> Map.from_struct()
      |> Map.drop([:counterfactual_id])
      |> Enum.sort()

    :crypto.hash(:sha256, :erlang.term_to_binary(canonical)) |> Base.encode16(case: :lower)
  end

  # ------------------------------------------------------------------
  # Status ontology queries
  # ------------------------------------------------------------------

  @spec statuses() :: [atom()]
  def statuses, do: @statuses

  @spec analysis_statuses() :: [atom()]
  def analysis_statuses, do: @analysis_statuses

  @spec assignable_by_d4?(atom()) :: boolean()
  def assignable_by_d4?(status), do: status in @analysis_statuses

  @spec observed?(atom() | CounterfactualRecord.t()) :: boolean()
  def observed?(%CounterfactualRecord{} = r), do: r.status == :observed
  def observed?(status) when is_atom(status), do: status == :observed

  @doc """
  True only for genuine knowledge states; `:unknown` and `:underdetermined`
  return `false` without being collapsed into a plain false — callers checking
  `known?` must also inspect `status` to learn *which* not-known state holds.
  """
  @spec known?(atom()) :: boolean()
  def known?(s), do: s in [:observed, :supported, :weakly_supported]

  @doc """
  A D4 analysis record may only be constructed with a status D4 can assign.
  `:observed` preserved on input is downgraded to `:hypothetical` when the
  record is built through the analysis constructor.
  """
  @spec enforce_observability_boundary(CounterfactualRecord.t()) :: CounterfactualRecord.t()
  def enforce_observability_boundary(%CounterfactualRecord{status: s} = r) do
    if assignable_by_d4?(s), do: r, else: %{r | status: :hypothetical}
  end

  # ------------------------------------------------------------------
  # Helpers
  # ------------------------------------------------------------------

  defp branchable_fields do
    [
      :schema_version,
      :intervention,
      :assumptions,
      :affected_variables,
      :expected_outcomes,
      :uncertainty,
      :provenance,
      :reference
    ]
  end

  defp counterfactual_status(%CounterfactualRecord{status: :observed}), do: :counterfactual
  defp counterfactual_status(%CounterfactualRecord{}), do: :counterfactual

  defp normalize_map(attrs) do
    if is_struct(attrs) do
      Map.from_struct(attrs)
    else
      Map.new(attrs)
    end
  end

  defp valid_intervention?(%InterventionSpec{} = i) do
    i.kind in [
      :set,
      :observe_only,
      :policy,
      :information,
      :timing,
      :do_nothing,
      :defer
    ]
  end

  defp valid_intervention?(_), do: false

  defp has_baseline?(ref) when is_map(ref) do
    is_binary(Map.get(ref, :baseline_state_ref)) or
      is_binary(Map.get(ref, :d3_decision_snapshot_id))
  end

  defp has_baseline?(_), do: false

  defp valid_outcomes?(%{} = o) do
    case Map.get(o, :distribution) do
      nil -> true
      :unknown -> true
      p when is_list(p) -> Enum.all?(p, &is_number/1)
      _ -> false
    end
  end

  defp valid_outcomes?(_), do: false

  defp normalize_validated(r) do
    if r.status == :observed, do: %{r | status: :hypothetical}, else: r
  end
end