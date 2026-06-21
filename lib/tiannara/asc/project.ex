defmodule Tiannara.ASC.Project do
  @moduledoc """
  The top-level data model for an ASC-managed software project.

  A project progresses through the 10-phase pipeline. All sub-civilization
  outputs are captured here and persisted to `data/asc_projects/<id>/`.

  The `world` field holds the `%ProjectWorld{}` — the shared typed substrate
  that all phase civilizations read from and write to. It starts `nil` and
  is first populated by the Requirements Civilization.
  """

  alias Tiannara.ASC.ProjectWorld

  @derive Jason.Encoder

  defstruct [
    :id,
    :goal,
    :world,               # %ProjectWorld{} — populated by Requirements, updated by each phase
    :requirements,
    :phase,
    :architectures,
    :selected_architecture,
    :artifacts,
    :crucible_status,
    :deployment,
    :health,
    :knowledge_refs,
    :meta_insights,
    :created_at,
    :updated_at,
    status: :active,
    opts: %{}
  ]

  @type phase ::
    :requirements
    | :research
    | :architecture
    | :implementation
    | :testing
    | :crucible
    | :api_evolution
    | :deployment
    | :operations
    | :repair
    | :completed
    | :failed

  @type t :: %__MODULE__{
    id: String.t(),
    goal: String.t(),
    world: ProjectWorld.t() | nil,
    requirements: map() | nil,
    phase: phase(),
    architectures: list(),
    selected_architecture: map() | nil,
    artifacts: map(),
    crucible_status: :pending | :running | :passed | :failed,
    deployment: map() | nil,
    health: map(),
    knowledge_refs: [String.t()],
    meta_insights: list(),
    created_at: DateTime.t(),
    updated_at: DateTime.t(),
    status: :active | :completed | :failed | :archived,
    opts: map()
  }

  @doc "Create a fresh project struct."
  @spec new(String.t(), String.t(), map()) :: t()
  def new(id, goal, opts \\ %{}) do
    now = DateTime.utc_now()
    %__MODULE__{
      id: id,
      goal: goal,
      world: nil,
      phase: :requirements,
      architectures: [],
      selected_architecture: nil,
      artifacts: %{source: [], tests: [], docs: [], infrastructure: []},
      crucible_status: :pending,
      deployment: nil,
      health: %{},
      knowledge_refs: [],
      meta_insights: [],
      created_at: now,
      updated_at: now,
      status: :active,
      opts: opts
    }
  end

  @doc "Advance the project to the next pipeline phase."
  @spec advance(t(), phase()) :: t()
  def advance(%__MODULE__{} = project, new_phase) do
    %{project | phase: new_phase, updated_at: DateTime.utc_now()}
  end
end
