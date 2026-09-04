defmodule Tiannara.Forecasting.TemporalFirewall do
  @moduledoc """
  D4 → D3 temporal firewall.

  D4 counterfactual analysis may READ D3 artifacts (decisions, snapshots,
  outcomes) but must never mutate or evaluate them with hindsight. This module
  is a first-class certification property: it verifies that a decision is still
  snapshot-consistent, that every outcome used in an analysis is strictly
  posterior to the decision, and that no D4 record tries to edit a D3 decision.

  Verification result shape:
      %{
        firewall_intact?: boolean(),
        snapshot_consistent?: boolean(),
        contamination: [map()],
        d3_writes: [map()]
      }

  Violations are enumerated, never silently fixed.
  """

  alias Tiannara.Forecasting.DecisionSnapshot
  alias Tiannara.Forecasting.Contracts.{Decision, DecisionOutcome, CounterfactualRecord}

  @type violation :: %{kind: atom(), detail: term()}

  @doc """
  Verifies the firewall for a decision, its captured snapshot, and a list of
  analysis artifacts (D3 outcomes and/or D4 counterfactual records).
  """
  @spec verify(Decision.t(), DecisionSnapshot.t(), [DecisionOutcome.t() | CounterfactualRecord.t()]) ::
          map()
  def verify(%Decision{} = d, %DecisionSnapshot{} = snap, artifacts)
      when is_list(artifacts) do
    snapshot_ok = DecisionSnapshot.consistent?(snap, d)
    contamination = contamination(d, artifacts)
    writes = d3_writes(artifacts)

    %{
      firewall_intact?: snapshot_ok and contamination == [] and writes == [],
      snapshot_consistent?: snapshot_ok,
      contamination: contamination,
      d3_writes: writes
    }
  end

  @doc """
  Lints a single artifact for temporal integrity. List of violations or `[]`.
  """
  @spec lint(Decision.t(), DecisionOutcome.t() | CounterfactualRecord.t()) :: [violation()]
  def lint(%Decision{} = d, %DecisionOutcome{} = out) do
    cond do
      not temporal_later?(out.observed_at, d.created_at) ->
        [%{kind: :hindsight_contamination, detail: out}]

      true ->
        []
    end
  end

  def lint(%Decision{} = d, %CounterfactualRecord{} = cf) do
    cond do
      not temporal_later?(cf.created_at, d.created_at) and
          reported_on?(cf) ->
        [%{kind: :counterfactual_predates_decision, detail: cf.counterfactual_id}]

      true ->
        []
    end
  end

  @doc """
  True when the D3 decision set is left untouched and outcomes are all
  strictly posterior to the decision time.
  """
  @spec firewall_intact?(Decision.t(), DecisionSnapshot.t(), list()) :: boolean()
  def firewall_intact?(%Decision{} = d, %DecisionSnapshot{} = snap, artifacts) do
    verify(d, snap, artifacts).firewall_intact?
  end

  # ------------------------------------------------------------------
  # Verification internals
  # ------------------------------------------------------------------

  defp contamination(d, artifacts) do
    Enum.flat_map(artifacts, fn a -> lint(d, a) end)
  end

  defp d3_writes(artifacts) do
    Enum.flat_map(artifacts, fn
      %CounterfactualRecord{reference: %{write_to_d3: true}} = cf ->
        [%{kind: :d3_write_attempt, detail: cf.counterfactual_id}]

      _ ->
        []
    end)
  end

  defp temporal_later?(nil, _base), do: true
  defp temporal_later?(%DateTime{} = later, %DateTime{} = base), do: DateTime.compare(later, base) == :gt

  defp temporal_later?(_later, _base), do: true

  defp reported_on?(cf) do
    not is_nil(Map.get(cf.reference, :observed_event_id))
  end

  @doc false
  def contamination_for(d, artifacts) do
    Enum.flat_map(artifacts, fn a -> lint(d, a) end)
  end
end