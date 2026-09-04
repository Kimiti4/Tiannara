defmodule Tiannara.ToolForge.Domain do
  defmodule ToolNeed do
    defstruct [
      :id,
      :source,
      :description,
      :capability_gap,
      required_interfaces: [],
      constraints: %{},
      priority: :medium,
      estimated_impact: 0.5,
      created_at: nil
    ]

    @type t :: %__MODULE__{}

    def new(attrs) do
      %__MODULE__{
        id: "need_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        required_interfaces: [],
        constraints: %{},
        priority: :medium,
        estimated_impact: 0.5,
        created_at: DateTime.utc_now()
      }
      |> struct(attrs)
    end
  end

  defmodule ToolSpecification do
    defstruct [
      :id,
      :need_id,
      :name,
      :description,
      :language,
      :architecture,
      :verification_plan,
      :evolution_strategy,
      interfaces: [],
      dependencies: [],
      resource_requirements: %{},
      security_requirements: %{},
      status: :specified,
      created_at: nil
    ]

    @type t :: %__MODULE__{}

    @languages [:elixir, :python, :rust, :typescript, :generic]
    @statuses [:specified, :building, :validating, :deployed, :evolving, :retired]

    def languages, do: @languages
    def statuses, do: @statuses

    def new(attrs) do
      %__MODULE__{
        id: "spec_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        interfaces: [],
        dependencies: [],
        resource_requirements: %{},
        security_requirements: %{},
        status: :specified,
        created_at: DateTime.utc_now()
      }
      |> struct(attrs)
    end
  end

  defmodule GeneratedTool do
    defstruct [
      :id,
      :spec_id,
      :name,
      :language,
      :entry_point,
      :build_instructions,
      :fitness_score,
      :parent_tool_id,
      source_files: %{},
      test_files: %{},
      generation_metadata: %{},
      generation: 1,
      created_at: nil
    ]

    @type t :: %__MODULE__{}

    def new(attrs) do
      %__MODULE__{
        id: "tool_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        source_files: %{},
        test_files: %{},
        generation: 1,
        created_at: DateTime.utc_now()
      }
      |> struct(attrs)
    end
  end

  defmodule ToolDeployment do
    defstruct [
      :id,
      :tool_id,
      :spec_id,
      :pid,
      :port,
      :last_health_check,
      status: :running,
      health: 1.0,
      metrics: %{},
      deployed_at: nil
    ]

    @type t :: %__MODULE__{}

    def new(attrs) do
      %__MODULE__{
        id: "deploy_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        status: :running,
        health: 1.0,
        metrics: %{},
        deployed_at: DateTime.utc_now()
      }
      |> struct(attrs)
    end
  end
end
