defmodule Tiannara.Council.Authorization do
  defstruct [
    :decision,
    :confidence,
    :constitutional_score,
    :violated_principles,
    :required_human_review,
    :explanation,
    :evidence,
    :risks,
    :simulation_results,
    :recommendation,
    :context,
    :decided_at,
    :policy_applied,
    metadata: %{},
    conditions: []
  ]

  @typedoc """
  A per-concern mitigation requirement attached to a decision (G-9).

  `concern` names the constitutional concern the condition exists for;
  `evidence_check` names the evidence entry that satisfies it. A condition is
  satisfied when the decision's evidence carries an entry whose `:principle`
  or `:check` equals the condition value and that entry is not explicitly
  `passed: false`. Any unsatisfied condition fails the conditions check
  fail-closed.
  """
  @type condition :: %{concern: atom(), evidence_check: atom()}

  @type decision :: :approved | :rejected | :deferred | :requires_human | :conditional
  @type t :: %__MODULE__{
          decision: decision(),
          confidence: float(),
          constitutional_score: float(),
          violated_principles: [atom()],
          required_human_review: boolean(),
          explanation: String.t(),
          evidence: [map()],
          risks: [map()],
          simulation_results: [map()],
          recommendation: String.t() | nil,
          context: Tiannara.Council.ExecutionContext.t() | nil,
          decided_at: DateTime.t(),
          policy_applied: atom() | nil,
          metadata: map(),
          conditions: [condition()]
        }

  def approved(opts) do
    %__MODULE__{
      decision: :approved,
      confidence: Keyword.get(opts, :confidence, 1.0),
      constitutional_score: Keyword.get(opts, :constitutional_score, 1.0),
      violated_principles: [],
      required_human_review: false,
      explanation:
        Keyword.get(opts, :explanation, "Action complies with all constitutional principles."),
      evidence: Keyword.get(opts, :evidence, []),
      risks: Keyword.get(opts, :risks, []),
      simulation_results: Keyword.get(opts, :simulation_results, []),
      recommendation: Keyword.get(opts, :recommendation),
      context: Keyword.get(opts, :context),
      decided_at: DateTime.utc_now(),
      policy_applied: Keyword.get(opts, :policy_applied),
      metadata: Keyword.get(opts, :metadata, %{}),
      conditions: Keyword.get(opts, :conditions, [])
    }
  end

  def rejected(opts) do
    %__MODULE__{
      decision: :rejected,
      confidence: Keyword.get(opts, :confidence, 1.0),
      constitutional_score: Keyword.get(opts, :constitutional_score, 0.0),
      violated_principles: Keyword.get(opts, :violated_principles, []),
      required_human_review: false,
      explanation: Keyword.fetch!(opts, :explanation),
      evidence: Keyword.get(opts, :evidence, []),
      risks: Keyword.get(opts, :risks, []),
      simulation_results: [],
      recommendation: Keyword.get(opts, :recommendation),
      context: Keyword.get(opts, :context),
      decided_at: DateTime.utc_now(),
      policy_applied: Keyword.get(opts, :policy_applied),
      metadata: Keyword.get(opts, :metadata, %{}),
      conditions: Keyword.get(opts, :conditions, [])
    }
  end

  def requires_human(opts) do
    %__MODULE__{
      decision: :requires_human,
      confidence: Keyword.get(opts, :confidence, 0.5),
      constitutional_score: Keyword.get(opts, :constitutional_score, 0.5),
      violated_principles: Keyword.get(opts, :violated_principles, []),
      required_human_review: true,
      explanation: Keyword.fetch!(opts, :explanation),
      evidence: Keyword.get(opts, :evidence, []),
      risks: Keyword.get(opts, :risks, []),
      simulation_results: Keyword.get(opts, :simulation_results, []),
      recommendation: Keyword.get(opts, :recommendation),
      context: Keyword.get(opts, :context),
      decided_at: DateTime.utc_now(),
      policy_applied: Keyword.get(opts, :policy_applied),
      metadata: Keyword.get(opts, :metadata, %{}),
      conditions: Keyword.get(opts, :conditions, [])
    }
  end

  @doc """
  True only for a full approval.

  A `:conditional` decision is **not** a machine grant. `permitted?/1` is the
  strict predicate: it must never be used as a "not explicitly rejected"
  test. The audited path for a conditional decision is
  `conditional_grant?/1`, which requires the decision's conditions to be
  satisfied.
  """
  def permitted?(%__MODULE__{decision: :approved}), do: true
  def permitted?(_), do: false

  @doc """
  The explicitly designed conditional-grant mechanism.

  True for a `:conditional` decision whose attached conditions are all
  satisfied by its evidence and whose structural preconditions hold. This is
  the only way a `:conditional` decision may authorise an effect; every other
  consumer must use `permitted?/1`.
  """
  def conditional_grant?(%__MODULE__{decision: :conditional} = auth) do
    conditions_met?(auth)
  end

  def conditional_grant?(_), do: false

  @doc """
  True when the decision carries no unmet condition and satisfies the
  structural preconditions: evidence is present, no principle was violated,
  the constitutional score is at least 0.6, and no human review is required.
  """
  def conditions_met?(%__MODULE__{} = auth) do
    structural_conditions_met?(auth) and unmet_conditions(auth) == []
  end

  def conditions_met?(_), do: false

  @doc "The conditions of a decision that its evidence does not satisfy."
  def unmet_conditions(%__MODULE__{conditions: conditions} = auth)
      when is_list(conditions) and conditions != [] do
    evidence = List.wrap(auth.evidence)

    Enum.reject(conditions, &condition_satisfied?(&1, evidence))
  end

  def unmet_conditions(%__MODULE__{}), do: []

  defp structural_conditions_met?(%__MODULE__{} = auth) do
    auth.evidence not in [nil, []] and
      auth.violated_principles in [nil, []] and
      is_number(auth.constitutional_score) and auth.constitutional_score >= 0.6 and
      auth.required_human_review != true
  end

  defp condition_satisfied?(%{concern: concern, evidence_check: check}, evidence)
       when is_atom(concern) and is_atom(check) do
    Enum.any?(evidence, fn entry ->
      is_map(entry) and
        (Map.get(entry, :principle) == concern or
           Map.get(entry, :principle_id) == concern or
           Map.get(entry, :check) == check) and
        Map.get(entry, :passed, true) != false
    end)
  end

  defp condition_satisfied?(_condition, _evidence), do: false
end
