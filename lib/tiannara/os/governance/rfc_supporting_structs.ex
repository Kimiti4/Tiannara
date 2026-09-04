defmodule TiannaraOS.Governance.ReviewReport do
  @moduledoc """
  ReviewReport - Captures reviewer assessment of an RFC.

  Generated during the Review stage by assigned reviewers.

  ## Archaeology

  - **purpose**: Standardize review report structure across all RFC reviews
  - **introduced_in**: Phase 14.1
  - **depends_on**: None (pure data structure)
  - **constitution_reference**: PHASE14_1_RFC_SYSTEM_SPECIFICATION.md Section 2.2
  - **owner**: Governance Council
  """

  defstruct [
    :review_id,
    :rfc_id,
    :reviewer_id,
    :submitted_at,
    :technical_assessment,
    :security_assessment,
    :governance_impact,
    :recommendation,
    :concerns,
    :suggestions,
    :estimated_effort,
    :risk_level
  ]

  @type t :: %__MODULE__{
    review_id: String.t(),
    rfc_id: String.t(),
    reviewer_id: String.t(),
    submitted_at: DateTime.t(),
    technical_assessment: String.t(),
    security_assessment: String.t(),
    governance_impact: String.t(),
    recommendation: :approve | :reject | :revise,
    concerns: [String.t()],
    suggestions: [String.t()],
    estimated_effort: map(),
    risk_level: :low | :medium | :high | :critical
  }

  @doc """
  Create a new ReviewReport with default values.
  """
  @spec new(String.t(), String.t()) :: t()
  def new(rfc_id, reviewer_id) do
    %__MODULE__{
      review_id: "REVIEW-#{:erlang.unique_integer([:positive])}",
      rfc_id: rfc_id,
      reviewer_id: reviewer_id,
      submitted_at: DateTime.utc_now(),
      technical_assessment: "",
      security_assessment: "",
      governance_impact: "",
      recommendation: :approve,
      concerns: [],
      suggestions: [],
      estimated_effort: %{hours: 0, complexity: :unknown},
      risk_level: :medium
    }
  end
end

defmodule TiannaraOS.Governance.DiscussionSummary do
  @moduledoc """
  DiscussionSummary - Aggregated summary of community discussion.

  Generated at the end of the Discussion stage to capture key themes,
  consensus points, and outstanding concerns.

  ## Archaeology

  - **purpose**: Standardize discussion summary structure
  - **introduced_in**: Phase 14.1
  - **depends_on**: None (pure data structure)
  - **constitution_reference**: PHASE14_1_RFC_SYSTEM_SPECIFICATION.md Section 2.3
  - **owner**: Governance Council
  """

  defstruct [
    :summary_id,
    :rfc_id,
    :thread_id,
    :generated_at,
    :total_comments,
    :unique_participants,
    :discussion_duration_days,
    :key_themes,
    :consensus_points,
    :outstanding_concerns,
    :sentiment_analysis,
    :participation_rate,
    :recommendation
  ]

  @type t :: %__MODULE__{
    summary_id: String.t(),
    rfc_id: String.t(),
    thread_id: String.t(),
    generated_at: DateTime.t(),
    total_comments: integer(),
    unique_participants: integer(),
    discussion_duration_days: float(),
    key_themes: [map()],
    consensus_points: [String.t()],
    outstanding_concerns: [String.t()],
    sentiment_analysis: map(),
    participation_rate: float(),
    recommendation: :proceed | :revise | :abandon
  }

  @doc """
  Create a new DiscussionSummary with default values.
  """
  @spec new(String.t(), String.t()) :: t()
  def new(rfc_id, thread_id) do
    %__MODULE__{
      summary_id: "DISC-SUM-#{:erlang.unique_integer([:positive])}",
      rfc_id: rfc_id,
      thread_id: thread_id,
      generated_at: DateTime.utc_now(),
      total_comments: 0,
      unique_participants: 0,
      discussion_duration_days: 0.0,
      key_themes: [],
      consensus_points: [],
      outstanding_concerns: [],
      sentiment_analysis: %{positive: 0.0, neutral: 0.0, negative: 0.0},
      participation_rate: 0.0,
      recommendation: :proceed
    }
  end
end
