defmodule Tiannara.ASC.Laws.Law do
  @moduledoc """
  A discovered software engineering law.

  Laws are the highest-value output of the ASC civilization — statistically
  robust patterns extracted by `Laws.Discoverer` from the Observatory corpus
  across many projects.

  ## 4-Tier Promotion Ladder

  Laws climb from raw signal to canonical principle as evidence accumulates:

      :candidate_pattern   → 1–2 projects     — first raw signal
           ↓
      :candidate_law       → 3+ projects       — enters the law registry
           ↓
      :established_law     → 10+, conf ≥ 0.85  — high-trust, actionable
           ↓
      :canonical_principle → 20+, conf ≥ 0.95  — architectural axiom

  Laws can also be `:refuted` (confidence collapses) or `:under_review`
  (confidence oscillating in the 0.40–0.60 band).

  ## Examples of Laws That Should Eventually Emerge

  - "Modular monoliths achieve higher long_term_stability than microservices
    when team_size_proxy < 5"
  - "Property tests produce 3.2x the bug_discovery_rate of unit tests alone"
  - "Event-driven architectures require avg 7.4 crucible iterations vs 4.1
    for actor-based"
  - "APIs with high business_value achieve 2.1x the adoption rate within 30 days"

  ## Connection to the Scientific Discovery Stack

  Each promotion transition is logged as a `LawDiscoveryEvent` so the
  Knowledge Archive can record the epistemological history of each law —
  matching the 5-level validation ladder in TiannaraOS.Discovery.
  """

  @derive Jason.Encoder

  defstruct [
    :id,
    :statement,
    :variables,
    :supporting_project_ids,
    :disconfirming_project_ids,
    :confidence,
    :status,
    :domain_tags,
    :discovered_at,
    :last_updated_at,
    :promoted_at,           # DateTime when last promoted to a higher tier
    :canonical_statement,   # reformulated statement at :canonical_principle tier
    evidence_count: 0,
    support_count: 0,
    contradiction_count: 0,
    kg_node_id: nil,
    utility_profile: nil,
    utility_score: 0.0,
    campaigns_tested: 0,
    campaigns_survived: 0
  ]

  @type status ::
    :candidate_pattern    # 1–2 projects — raw signal, not yet in registry
    | :candidate_law      # 3+ projects — confirmed enough to track
    | :established_law    # 10+, conf ≥ 0.85 — high trust, actionable
    | :canonical_principle # 20+, conf ≥ 0.95 — architectural axiom
    | :refuted            # evidence collapsed below 0.20
    | :under_review       # confidence oscillating 0.40–0.60

  @type t :: %__MODULE__{
    id: String.t(),
    statement: String.t(),
    variables: map(),
    supporting_project_ids: [String.t()],
    disconfirming_project_ids: [String.t()],
    confidence: float(),
    status: status(),
    domain_tags: [String.t()],
    discovered_at: DateTime.t(),
    last_updated_at: DateTime.t(),
    promoted_at: DateTime.t() | nil,
    canonical_statement: String.t() | nil,
    evidence_count: non_neg_integer(),
    support_count: non_neg_integer(),
    contradiction_count: non_neg_integer(),
    kg_node_id: String.t() | nil,
    utility_profile: map() | nil,
    utility_score: float(),
    campaigns_tested: non_neg_integer(),
    campaigns_survived: non_neg_integer()
  }

  @spec new(String.t(), map()) :: t()
  def new(statement, variables \\ %{}) do
    now = DateTime.utc_now()
    %__MODULE__{
      id: "law_#{:erlang.unique_integer([:positive, :monotonic])}",
      statement: statement,
      variables: variables,
      supporting_project_ids: [],
      disconfirming_project_ids: [],
      confidence: 0.30,
      status: :candidate_pattern,
      domain_tags: ["software_engineering"],
      discovered_at: now,
      last_updated_at: now,
      promoted_at: nil,
      canonical_statement: nil,
      support_count: 0,
      contradiction_count: 0,
      utility_profile: %{fitness_gain: 0.0, compute_savings: 0.0, success_gain: 0.0, confidence: 0.0},
      utility_score: 0.0,
      campaigns_tested: 0,
      campaigns_survived: 0
    }
  end

  @doc "Update confidence based on new evidence from a project."
  @spec update_confidence(t(), :confirms | :disconfirms, String.t()) :: t()
  def update_confidence(%__MODULE__{} = law, :confirms, project_id) do
    new_supporting = Enum.uniq([project_id | law.supporting_project_ids])
    n              = length(new_supporting) + length(law.disconfirming_project_ids)
    new_confidence = Float.round(length(new_supporting) / max(n, 1), 4)
    old_status     = law.status
    new_status     = derive_status(new_confidence, n)

    %{law |
      supporting_project_ids: new_supporting,
      confidence:             new_confidence,
      evidence_count:         law.evidence_count + 1,
      support_count:          law.support_count + 1,
      status:                 new_status,
      promoted_at:            promotion_timestamp(old_status, new_status, law.promoted_at),
      last_updated_at:        DateTime.utc_now()
    }
  end

  def update_confidence(%__MODULE__{} = law, :disconfirms, project_id) do
    new_disconfirming = Enum.uniq([project_id | law.disconfirming_project_ids])
    n                 = length(law.supporting_project_ids) + length(new_disconfirming)
    new_confidence    = Float.round(length(law.supporting_project_ids) / max(n, 1), 4)
    old_status        = law.status
    new_status        = derive_status(new_confidence, n)

    %{law |
      disconfirming_project_ids: new_disconfirming,
      confidence:                new_confidence,
      evidence_count:            law.evidence_count + 1,
      contradiction_count:       law.contradiction_count + 1,
      status:                    new_status,
      promoted_at:               promotion_timestamp(old_status, new_status, law.promoted_at),
      last_updated_at:           DateTime.utc_now()
    }
  end

  @doc "Set a canonical reformulation of the law (for :canonical_principle tier)."
  @spec set_canonical(t(), String.t()) :: t()
  def set_canonical(%__MODULE__{} = law, canonical_statement) do
    %{law | canonical_statement: canonical_statement, last_updated_at: DateTime.utc_now()}
  end

  @doc "True if this law has been promoted since last check."
  @spec promoted?(t(), status()) :: boolean()
  def promoted?(%__MODULE__{status: current}, previous_status) do
    tier(current) > tier(previous_status)
  end

  # ---------------------------------------------------------------------------
  # Private — tier mapping and status derivation
  # ---------------------------------------------------------------------------

  defp derive_status(confidence, n) do
    cond do
      confidence < 0.20                          -> :refuted
      confidence >= 0.40 and confidence <= 0.60
        and n >= 5                               -> :under_review
      confidence >= 0.95 and n >= 20             -> :canonical_principle
      confidence >= 0.85 and n >= 10             -> :established_law
      n >= 3                                     -> :candidate_law
      true                                       -> :candidate_pattern
    end
  end

  defp tier(:candidate_pattern),   do: 0
  defp tier(:candidate_law),       do: 1
  defp tier(:established_law),     do: 2
  defp tier(:canonical_principle), do: 3
  defp tier(:under_review),        do: 1   # same as candidate_law
  defp tier(:refuted),             do: -1

  # Only update promoted_at when the tier actually increases
  defp promotion_timestamp(old, new, existing_at) do
    if tier(new) > tier(old), do: DateTime.utc_now(), else: existing_at
  end
end
