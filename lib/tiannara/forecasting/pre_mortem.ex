defmodule Tiannara.Forecasting.PreMortem do
  @moduledoc """
  D3 pre-mortem analysis: imagine the decision's action fails catastrophically
  and identify why. A pre-mortem is BEFORE the decision locks in irreversible
  commitment.

  The output is a list of failure modes, their likelihood, and any mitigations
  that should be required before the decision becomes recommended.

  For D3, the pre-mortem is OPTIONAL but when performed, its results feed into
  `DecisionQuality` (risk_registered component) and can block a recommendation
  (via the Council authorization boundary, if required).

  Output schema:
    %{
      alternative_id: term(),
      failure_modes: [%{description: String.t(), likelihood: 0.0..1.0, mitigation: String.t() | nil}],
      blocked?: boolean(),
      reason: String.t() | nil
    }
  """

  alias Tiannara.Forecasting.Contracts.Alternative

  @doc """
  Runs a pre-mortem on a single alternative. Returns failure scenarios and
  recommends whether the action should be blocked due to high-risk failure modes.

  The analysis iterates over:
    1. Assumption violation scenarios
    2. Unknown outcome scenarios (probabilities were :unknown)
    3. Irreversibility consequences
    4. Assets-at-risk exposure
  """
  @spec run(Alternative.t(), opts :: Keyword.t()) :: map()
  def run(%Alternative{} = a, opts \\ []) do
    threshold = Keyword.get(opts, :risk_threshold, 0.7)

    modes = failure_modes(a)
    high_risk = Enum.any?(modes, fn m -> mLikelihood(m) > threshold end)
    reason = if high_risk, do: "High-risk failure mode identified (risk_threshold=#{threshold})", else: nil

    %{
      alternative_id: a.id,
      failure_modes: modes,
      blocked?: high_risk,
      reason: reason,
      analysis_version: "D3-pre-mortem-1.0"
    }
  end

  @doc """
  Runs pre-mortems across all alternatives in a decision. Returns a list of
  results. An alternative may be flagged `:blocked` for any pre-mortem that raises
  the risk score above the threshold.
  """
  @spec run_all([Alternative.t()], opts :: Keyword.t()) :: [map()]
  def run_all(alternatives, opts \\ []) do
    Enum.map(alternatives, &run(&1, opts))
  end

  @doc """
  Suggests mitigations or requires additional information gathering before a
  blocked decision can be reconsidered. Returns `{:proceed, :require_info, :block}`.
  """
  @spec posture([map()], threshold :: number()) ::
          :proceed | {:require_info, [{:additional_evidence, String.t()}]} | :block
  def posture(premortems, threshold \\ 0.8) do
    failures = Enum.filter(premortems, &(&1.blocked?))

    cond do
      failures == [] ->
        :proceed

      Enum.any?(failures, fn f -> fLikelihood(f) > threshold end) ->
        :block

      true ->
        {:require_info, gather_required(failures)}
    end
  end

  defp failure_modes(%Alternative{probabilities: :unknown, outcomes: _outcomes}) do
    [
      %{
        description: "Outcome distribution was unknown at decision time",
        likelihood: 0.9,
        mitigation: "Gather higher-quality probabilistic evidence before deciding"
      }
    ]
  end

  defp failure_modes(%Alternative{reversibility: :irreversible, assets_at_risk: risk_desc}) do
    %{
      description: "Irreversible commitment with #{inspect(risk_desc)} at risk",
      likelihood: 0.9,
      mitigation: "Re-evaluate for reversible alternatives or gather additional evidence"
    }
    |> List.wrap()
    |> then(fn modes ->
      if is_binary(risk_desc) do
        [%{
           description: "Assets at risk: #{risk_desc}",
           likelihood: 0.5,
           mitigation: "Assess rollback feasibility"
         } | modes]
      else
        modes
      end
    end)
  end

  defp failure_modes(%Alternative{utilities: us}) do
    us
    |> Enum.with_index()
    |> Enum.filter(fn {u, _i} -> is_number(u) and u < 0 end)
    |> Enum.map(fn {_u, i} ->
      %{
        description: "Negative utility outcome at index #{i}",
        likelihood: 0.5,
        mitigation: "Consider whether this outcome can be mitigated in execution"
      }
    end)
    |> Enum.take(2)
  end

  defp failure_modes(_), do: []

  defp mLikelihood(mode), do: mode.likelihood || 0.0
  defp fLikelihood(pre), do: Enum.max_by(pre.failure_modes, &(&1.likelihood)).likelihood

  defp gather_required(failures) do
    failures
    |> Enum.flat_map(fn f -> f.failure_modes || [] end)
    |> Enum.filter(fn m -> mLikelihood(m) > 0.3 end)
    |> Enum.map(fn m -> {:additional_evidence, m.description} end)
  end
end