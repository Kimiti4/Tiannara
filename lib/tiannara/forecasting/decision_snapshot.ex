defmodule Tiannara.Forecasting.DecisionSnapshot do
  @moduledoc """
  D3 decision-time information snapshot.

  A `DecisionSnapshot` reifies exactly what was known when a decision was made:
  the alternatives with their decision-time probability distributions and
  utilities, the expected-value / risk evaluation, the forecast references,
  and any additional information sources. It is the fixed basis against which
  decision quality and review are evaluated — so a decision is never judged
  with hindsight.

  Constitutional rules:
    - a snapshot is taken at decision time and never mutated.
    - decision quality is a function of the snapshot, never of the outcome.
    - `consistent?/2` proves that a decision still matches its snapshot (has not
      been rewritten with hindsight information).
  """

  alias Tiannara.Forecasting.Contracts.Decision

  defstruct [
    :decision_id,
    :question,
    :alternatives,
    :forecast_refs,
    :unknowns,
    :captured_at
  ]

  @type t :: %__MODULE__{
          decision_id: String.t(),
          question: String.t() | nil,
          alternatives: [map()],
          forecast_refs: [term()],
          unknowns: [atom()],
          captured_at: DateTime.t()
        }

  @doc """
  Captures the decision-time information of a decision. The alternatives are
  frozen as plain maps (id, outcomes, probabilities, utilities, reversibility),
  and the list of `:unknown` probability positions is recorded so that
  information sufficiency is measurable later without hindsight.
  """
  @spec capture(Decision.t()) :: t()
  def capture(%Decision{} = d) do
    %__MODULE__{
      decision_id: d.id,
      question: d.question,
      alternatives:
        Enum.map(d.alternatives, fn a ->
          %{
            id: a.id,
            outcomes: a.outcomes,
            probabilities: a.probabilities,
            utilities: a.utilities,
            reversibility: a.reversibility
          }
        end),
      forecast_refs: d.forecast_refs || [],
      unknowns: unknown_positions(d.alternatives),
      captured_at: d.created_at
    }
  end

  @doc """
  True when the decision's decision-time data still matches the snapshot —
  i.e. the decision has not been rewritten with hindsight. Compares the
  decision-time probability distributions, utilities, and alternatives present
  at capture time.
  """
  @spec consistent?(t(), Decision.t()) :: boolean()
  def consistent?(%__MODULE__{} = snap, %Decision{} = d) do
    snap_alt_ids = snap.alternatives |> Enum.map(& &1.id) |> Enum.sort()
    d_alt_ids = d.alternatives |> Enum.map(& &1.id) |> Enum.sort()
    snap_alt_ids == d_alt_ids and Enum.all?(snap.alternatives, &alt_matches?(&1, d))
  end

  defp alt_matches?(snap_alt, %Decision{alternatives: alts}) do
    case Enum.find(alts, fn a -> a.id == snap_alt.id end) do
      nil ->
        false

      a ->
        a.probabilities == snap_alt.probabilities and a.utilities == snap_alt.utilities
    end
  end

  defp unknown_positions(alternatives) do
    Enum.flat_map(alternatives, fn a ->
      case a.probabilities do
        :unknown -> [{a.id, :unknown_distribution}]
        nil -> []
        p when is_list(p) ->
          p
          |> Enum.with_index()
          |> Enum.filter(fn {v, _i} -> not is_number(v) end)
          |> Enum.map(fn {_v, i} -> {a.id, i} end)
        _ -> []
      end
    end)
  end
end
