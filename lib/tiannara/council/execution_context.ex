defmodule Tiannara.Council.ExecutionContext do
  defstruct [
    :correlation_id,
    :mission_id,
    :actor,
    :intent,
    :evidence,
    :risk_assessment,
    :affected_principles,
    :resources,
    :priority,
    :constitution_version,
    :parent_context,
    :created_at,
    metadata: %{}
  ]

  @type t :: %__MODULE__{
          correlation_id: String.t(),
          mission_id: String.t() | nil,
          actor: atom() | String.t(),
          intent: atom(),
          evidence: [map()],
          risk_assessment: float(),
          affected_principles: [atom()],
          resources: map(),
          priority: float(),
          constitution_version: String.t(),
          parent_context: t() | nil,
          created_at: DateTime.t(),
          metadata: map()
        }

  @spec new(keyword()) :: t()
  def new(opts) do
    %__MODULE__{
      correlation_id: generate_correlation_id(),
      mission_id: Keyword.get(opts, :mission_id),
      actor: Keyword.fetch!(opts, :actor),
      intent: Keyword.fetch!(opts, :intent),
      evidence: Keyword.get(opts, :evidence, []),
      risk_assessment: Keyword.get(opts, :risk_assessment, 0.0),
      affected_principles: Keyword.get(opts, :affected_principles, []),
      resources: Keyword.get(opts, :resources, %{}),
      priority: Keyword.get(opts, :priority, 0.5),
      constitution_version: Keyword.get(opts, :constitution_version, "1.0.0"),
      parent_context: nil,
      created_at: DateTime.utc_now(),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  @spec child(t(), keyword()) :: t()
  def child(%__MODULE__{} = parent, opts) do
    %__MODULE__{
      correlation_id: parent.correlation_id,
      mission_id: Keyword.get(opts, :mission_id, parent.mission_id),
      actor: Keyword.get(opts, :actor, parent.actor),
      intent: Keyword.fetch!(opts, :intent),
      evidence: Keyword.get(opts, :evidence, []),
      risk_assessment: Keyword.get(opts, :risk_assessment, parent.risk_assessment),
      affected_principles: Keyword.get(opts, :affected_principles, parent.affected_principles),
      resources: Keyword.get(opts, :resources, parent.resources),
      priority: Keyword.get(opts, :priority, parent.priority),
      constitution_version: parent.constitution_version,
      parent_context: parent,
      created_at: DateTime.utc_now(),
      metadata: Map.merge(parent.metadata, Keyword.get(opts, :metadata, %{}))
    }
  end

  defp generate_correlation_id do
    "ctx_#{:crypto.strong_rand_bytes(12) |> Base.encode16(case: :lower)}"
  end
end
