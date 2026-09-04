defmodule Tiannara.Engineering.Domain do
  defmodule EngineeringInsight do
    defstruct [:id, :source_discovery_id, :principle_statement, :domain,
      :confidence, :evidence_count, :applicable_contexts, :constraints, :created_at]

    @type t :: %__MODULE__{}

    def new(attrs) do
      %__MODULE__{
        id: "insight_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        applicable_contexts: [], constraints: [], created_at: DateTime.utc_now()
      } |> struct(attrs)
    end
  end

  defmodule EngineeringDesign do
    defstruct [:id, :insight_id, :name, :description, :domain, :components,
      :architecture, :resource_requirements, :feasibility, :risk, :safety_score,
      :estimated_effort, :verification_plan, :status, :lineage, :created_at, :updated_at]

    @type t :: %__MODULE__{}

    @statuses [:proposed, :evaluated, :approved, :in_progress, :verified, :deployed, :rejected]

    def statuses, do: @statuses

    def new(attrs) do
      %__MODULE__{
        id: "design_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        components: [], architecture: %{}, resource_requirements: %{},
        feasibility: 0.5, risk: 0.5, safety_score: 1.0, estimated_effort: %{},
        verification_plan: nil, status: :proposed, lineage: [],
        created_at: DateTime.utc_now(), updated_at: DateTime.utc_now()
      } |> struct(attrs)
    end
  end

  defmodule DesignComponent do
    defstruct [:id, :name, :type, :description, :interfaces, :dependencies,
      :resource_cost, :complexity, :reusability]

    @type t :: %__MODULE__{}

    def new(attrs) do
      %__MODULE__{
        id: "comp_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        interfaces: [], dependencies: [], resource_cost: %{},
        complexity: 0.5, reusability: 0.5
      } |> struct(attrs)
    end
  end

  defmodule VerificationPlan do
    defstruct [:id, :design_id, :unit_tests, :integration_tests, :property_tests,
      :chaos_tests, :performance_tests, :safety_checks, :acceptance_criteria,
      :estimated_duration_hours, :created_at]

    @type t :: %__MODULE__{}

    def new(attrs) do
      %__MODULE__{
        id: "vplan_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        unit_tests: [], integration_tests: [], property_tests: [],
        chaos_tests: [], performance_tests: [], safety_checks: [],
        acceptance_criteria: [], estimated_duration_hours: 0,
        created_at: DateTime.utc_now()
      } |> struct(attrs)
    end
  end

  defmodule DesignEvaluation do
    defstruct [:design_id, :feasibility, :safety, :resource_efficiency, :complexity,
      :reusability, :verifiability, :alignment_with_principle, :composite_score,
      :weakest_dimension, :recommendations, :evaluated_at]

    @type t :: %__MODULE__{}

    def new(attrs) do
      %__MODULE__{recommendations: [], evaluated_at: DateTime.utc_now()} |> struct(attrs)
    end
  end
end
