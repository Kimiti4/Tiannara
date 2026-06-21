defmodule Tiannara.ASC.Requirements.Supervisor do
  use Supervisor
  def start_link(opts \\ []), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_), do: Supervisor.init([Tiannara.ASC.Requirements.Civilization], strategy: :one_for_one)
end

defmodule Tiannara.ASC.Requirements.Civilization do
  @moduledoc """
  Requirements Civilization (Phase C — active).

  Transforms a raw project goal string into a fully populated `%ProjectWorld{}`
  using the `Requirements.Extractor` heuristic pipeline.

  ## Outputs

  - `project.world` — populated with invariants, capabilities, constraints, risks
  - `project.requirements` — summary map for quick access
  - `data/asc_projects/<id>/docs/requirements.json` — persisted specification
  - Observatory: `requirements_completeness` metric

  ## Phase Positioning

  This is the first active phase. When `run/1` returns `{:ok, updated_project}`,
  the Pipeline.Worker stores the updated project and advances to `:research`.

  ## Phase E.1 Approach

  Rule-based heuristic extraction — no LLM required. The Extractor uses
  linguistic pattern matching. MetaLearning (Phase I) will refine patterns
  from cross-project evidence as the corpus grows.
  """

  use GenServer
  require Logger

  alias Tiannara.ASC.{Project, ProjectWorld}
  alias Tiannara.ASC.Requirements.Extractor
  alias Tiannara.ASC.Observatory.ProjectObservatory

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc """
  Execute requirements elicitation for a project.

  Returns `{:ok, updated_project}` with `project.world` populated,
  or `{:error, reason}` on failure.
  """
  @spec run(Project.t()) :: {:ok, Project.t()} | {:error, term()}
  def run(%Project{} = project) do
    Logger.info("[ASC.Requirements] Extracting requirements for project #{project.id}")

    world   = Extractor.extract(project.goal)
    surface = ProjectWorld.requirements_surface(world)

    Logger.info(
      "[ASC.Requirements] Extracted: #{surface.invariants} invariants, " <>
      "#{surface.capabilities} capabilities, #{surface.constraints} constraints, " <>
      "#{surface.risks} risks"
    )

    updated = %{project |
      world:        world,
      requirements: build_requirements_map(world),
      updated_at:   DateTime.utc_now()
    }

    persist_requirements(project.id, world)

    ProjectObservatory.record(project.id, %{
      requirements_completeness: requirements_completeness(surface),
      invariant_count: surface.invariants,
      capability_count: surface.capabilities,
      constraint_count: surface.constraints
    })

    {:ok, updated}
  rescue
    e ->
      Logger.error("[ASC.Requirements] Extraction failed for #{project.id}: #{Exception.message(e)}")
      {:error, e}
  end

  @impl true
  def init(_opts) do
    Logger.info("[ASC.Requirements] Civilization initialized")
    {:ok, %{}}
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp build_requirements_map(%ProjectWorld{} = world) do
    %{
      invariants:          Enum.map(world.invariants,   &Map.from_struct/1),
      capabilities:        Enum.map(world.capabilities, &Map.from_struct/1),
      constraints:         Enum.map(world.constraints,  &Map.from_struct/1),
      risks:               Enum.map(world.risks,         &Map.from_struct/1),
      acceptance_criteria: world.acceptance_criteria,
      extracted_at:        DateTime.utc_now()
    }
  end

  # 0.25 per dimension that is non-empty
  defp requirements_completeness(surface) do
    [surface.invariants, surface.capabilities, surface.constraints, surface.risks]
    |> Enum.count(&(&1 > 0))
    |> Kernel./(4.0)
  end

  defp persist_requirements(project_id, world) do
    dir  = Path.join(["data", "asc_projects", project_id, "docs"])
    File.mkdir_p!(dir)
    path = Path.join(dir, "requirements.json")

    File.write!(path, Jason.encode!(%{
      invariants:          world.invariants,
      capabilities:        world.capabilities,
      constraints:         world.constraints,
      risks:               world.risks,
      acceptance_criteria: world.acceptance_criteria,
      extracted_at:        DateTime.utc_now()
    }, pretty: true))

    Logger.debug("[ASC.Requirements] Persisted requirements to #{path}")
  rescue
    e -> Logger.warning("[ASC.Requirements] Could not persist: #{Exception.message(e)}")
  end
end
