defmodule Tiannara.CEL.Mission.MissionModel do
  defmodule Mission do
    defstruct [
      :id,
      :name,
      :description,
      :strategic_objective_id,
      :status,
      :programs,
      :created_at,
      :started_at,
      :completed_at,
      :impact_assessment,
      :metadata
    ]

    @type t :: %__MODULE__{
            id: String.t(),
            name: String.t(),
            description: String.t(),
            strategic_objective_id: String.t() | nil,
            status: atom(),
            programs: [Program.t()],
            created_at: DateTime.t(),
            started_at: DateTime.t() | nil,
            completed_at: DateTime.t() | nil,
            impact_assessment: ImpactAssessment.t() | nil,
            metadata: map()
          }
  end

  defmodule Program do
    defstruct [
      :id,
      :mission_id,
      :name,
      :description,
      :status,
      :objectives,
      :created_at
    ]

    @type t :: %__MODULE__{
            id: String.t(),
            mission_id: String.t(),
            name: String.t(),
            description: String.t(),
            status: atom(),
            objectives: [Objective.t()],
            created_at: DateTime.t()
          }
  end

  defmodule Objective do
    defstruct [
      :id,
      :program_id,
      :description,
      :status,
      :active_workflows,
      :generated_assets,
      :validation_evidence
    ]

    @type t :: %__MODULE__{
            id: String.t(),
            program_id: String.t(),
            description: String.t(),
            status: atom(),
            active_workflows: [String.t()],
            generated_assets: [Asset.t()],
            validation_evidence: [map()]
          }
  end

  defmodule Asset do
    defstruct [
      :id,
      :type,
      :reference_id,
      :confidence,
      :created_at
    ]

    @type t :: %__MODULE__{
            id: String.t(),
            type: atom(),
            reference_id: String.t(),
            confidence: float(),
            created_at: DateTime.t()
          }
  end

  defmodule ImpactAssessment do
    defstruct [
      :mission_id,
      :research_acceleration_delta,
      :engineering_productivity_delta,
      :knowledge_retained,
      :novel_discoveries_count,
      :human_collaboration_value,
      :assessed_at,
      :assessor
    ]

    @type t :: %__MODULE__{
            mission_id: String.t(),
            research_acceleration_delta: float(),
            engineering_productivity_delta: float(),
            knowledge_retained: float(),
            novel_discoveries_count: non_neg_integer(),
            human_collaboration_value: float(),
            assessed_at: DateTime.t(),
            assessor: atom() | String.t()
          }
  end
end
