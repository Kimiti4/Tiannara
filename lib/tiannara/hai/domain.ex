defmodule Tiannara.HAI.Domain do
  defmodule ReviewRequest do
    defstruct [:id, :source_subsystem, :decision_type, :summary, :impact_level,
      :confidence, :uncertainty, :evidence_summary, :alternatives, :recommendation,
      :deadline, :status, :human_decision, :human_rationale, :created_at, :resolved_at]

    @type t :: %__MODULE__{}

    @impact_levels [:low, :medium, :high, :critical, :civilizational]
    @statuses [:pending, :approved, :rejected, :modified, :deferred, :expired]

    def impact_levels, do: @impact_levels
    def statuses, do: @statuses

    def new(attrs) do
      %__MODULE__{
        id: "review_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        alternatives: [], status: :pending, created_at: DateTime.utc_now(), resolved_at: nil
      } |> struct(attrs)
    end

    def mandatory_review?(%__MODULE__{impact_level: level}) do
      level in [:high, :critical, :civilizational]
    end
  end

  defmodule Explanation do
    defstruct [:id, :subject_id, :subject_type, :summary, :reasoning_chain, :evidence,
      :confidence, :uncertainty, :assumptions, :alternatives_considered, :limitations,
      :generated_at]

    @type t :: %__MODULE__{}

    def new(attrs) do
      %__MODULE__{
        id: "explain_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        reasoning_chain: [], evidence: [], assumptions: [], alternatives_considered: [],
        limitations: [], generated_at: DateTime.utc_now()
      } |> struct(attrs)
    end
  end

  defmodule DecisionTrace do
    defstruct [:id, :decision_id, :subsystem, :trigger, :inputs, :steps, :outputs,
      :confidence_at_each_step, :total_duration_ms, :replayable, :created_at]

    @type t :: %__MODULE__{}

    def new(attrs) do
      %__MODULE__{
        id: "trace_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        steps: [], confidence_at_each_step: [], replayable: true, created_at: DateTime.utc_now()
      } |> struct(attrs)
    end
  end

  defmodule ProvenanceGraph do
    defstruct [:id, :root_entity_id, :nodes, :edges, :depth, :total_evidence,
      :confidence_path, :generated_at]

    @type t :: %__MODULE__{}

    def new(attrs) do
      %__MODULE__{
        id: "prov_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        nodes: [], edges: [], confidence_path: [], generated_at: DateTime.utc_now()
      } |> struct(attrs)
    end
  end

  defmodule DiscoveryPresentation do
    defstruct [:id, :discovery_id, :title, :abstract, :question, :hypotheses,
      :evidence_summary, :conclusion, :confidence, :uncertainty, :limitations,
      :future_work, :lineage_summary, :review_status, :generated_at]

    @type t :: %__MODULE__{}

    def new(attrs) do
      %__MODULE__{
        id: "pres_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        hypotheses: [], limitations: [], future_work: [],
        generated_at: DateTime.utc_now()
      } |> struct(attrs)
    end
  end
end
