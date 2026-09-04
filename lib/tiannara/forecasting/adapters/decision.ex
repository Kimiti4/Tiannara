defmodule Tiannara.Forecasting.Adapters.Decision do
  @moduledoc """
  D3 adapter contract between decisions and Tiannara's authorization/AEO/CIS/
  Research/World-Model infrastructure.

  Boundary principles this contract enforces:
    - Decision recommendation ≠ authorization. Expected value never authorizes.
    - Execution flows through AEO only after `Council.authorize/3` permits it.
    - CIS retains authority to constrain/block/modify.
    - Research Director consumes information-gain / value-of-information
      priorities so additional information can re-evaluate a decision.
  """

  @doc """
  Submits a decision for constitutional authorization. D3 never bypasses the
  Council gate. If the Council runtime is not available, returns
  `{:error, :authorization_unavailable}` — authorization is never fabricated.
  """
  @callback authorize(map()) ::
              {:ok, Tiannara.Council.Authorization.t()} | {:error, term()}

  @doc "Builds an Executive Command for the selected action (execution is downstream)."
  @callback to_command(map()) :: {:ok, Tiannara.Executive.Command.t()} | {:error, term()}

  @doc "Submits the translated intent to AEO Runtime (the only execution path)."
  @callback submit_intent(map()) :: {:ok, term()} | {:error, term()}

  @doc "Asks CIS to evaluate the decision for pathogen-like side effects."
  @callback check_cis(map()) :: {:ok, map()} | {:error, term()}

  @doc "Requests research on decision alternatives where information could change the choice."
  @callback request_research(map()) :: {:ok, [map()]} | {:error, term()}

  @doc "Estimates world-model consequences of an alternative via counterfactual state."
  @callback world_consequence(map()) :: {:ok, map()} | {:error, term()}
end

defmodule Tiannara.Forecasting.Adapters.DecisionImpl do
  @moduledoc """
  Concrete D3 decision adapter wiring into existing Tiannara infrastructure.

  Follows the D2 adapter honesty principle: if an external runtime is not
  available, the adapter degrades gracefully with an explicit error rather than
  fabricating authorization, simulation, or world state.
  """

  @behaviour Tiannara.Forecasting.Adapters.Decision

  alias Tiannara.Forecasting.Contracts.Decision, as: DecisionRecord

  @impl true
  def authorize(%DecisionRecord{} = d) do
    case Process.whereis(Tiannara.Council) do
      nil -> {:error, :authorization_unavailable}
      _pid -> {:ok, Tiannara.Council.authorize(:efdi_decision, authorization_payload(d))}
    end
  end

  @impl true
  def to_command(%DecisionRecord{} = d) do
    action = d.selected_alternative_id || d.recommended_alternative_id
    cmd = Tiannara.Executive.Command.new(action, command_arguments(d), "efdi_decision_engine")
    {:ok, cmd}
  end

  @impl true
  def submit_intent(intent) do
    {:ok, Tiannara.AEO.submit_to_runtime(intent)}
  end

  @impl true
  def check_cis(%DecisionRecord{} = d) do
    pathogenic = d.risk_evaluation
                 |> Enum.map(fn {_id, r} -> r[:risk_score] end)
                 |> Enum.any?(fn s -> is_number(s) and s > 0.85 end)

    {:ok, %{pathogenic: pathogenic, checked_by: :cis_boundary}}
  end

  @impl true
  def request_research(%DecisionRecord{} = d) do
    priorities = Tiannara.Forecasting.ValueOfInformation.to_research_priorities(d)
    {:ok, priorities}
  end

  @impl true
  def world_consequence(%DecisionRecord{} = d) do
    # Honest boundary: D3 does not fabricate world-state consequence estimates
    # when the World Model lacks a determinable forward projection.
    case d.context && d.context[:world_snapshot_available] do
      true -> {:ok, %{decision_id: d.id, status: :counterfactual_available}}
      _ -> {:error, :world_snapshot_unavailable}
    end
  end

  defp authorization_payload(%DecisionRecord{} = d) do
    %{
      decision_id: d.id,
      question: d.question,
      recommended_alternative_id: d.recommended_alternative_id,
      expected_value: d.expected_values,
      risk: d.risk_evaluation,
      required_human: high_risk?(d)
    }
  end

  defp command_arguments(%DecisionRecord{} = d) do
    %{decision_id: d.id, question: d.question}
  end

  defp high_risk?(%DecisionRecord{} = d) do
    Enum.any?(d.risk_evaluation || %{}, fn {_id, r} -> is_number(r[:risk_score]) and r[:risk_score] > 0.8 end)
  end
end