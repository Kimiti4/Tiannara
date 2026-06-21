defmodule Tiannara.ASC.Deployment.Supervisor do
  use Supervisor
  def start_link(opts \\ []), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_), do: Supervisor.init([Tiannara.ASC.Deployment.Civilization], strategy: :one_for_one)
end

defmodule Tiannara.ASC.Deployment.Civilization do
  @moduledoc """
  Deployment Civilization (Phase H).

  Generates deployment artifacts only — the REA-1 posture approved in Q3.
  Artifacts written to `data/asc_projects/<id>/infrastructure/`:
    - Dockerfile
    - docker-compose.yml
    - helm/values.yaml (Kubernetes)
    - terraform/main.tf
    - .github/workflows/ci.yml

  Deployment mode transitions (analogous to REA approval levels):
    REA-1: Artifact generation  ← current approved posture
    REA-2: Local Docker execution
    REA-3: External deployment (requires explicit approval)

  Records `deployment_readiness` to Observatory.
  """

  use GenServer
  require Logger

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @spec run(Tiannara.ASC.Project.t()) :: {:ok, :stub}
  def run(_project), do: {:ok, :stub}

  @impl true
  def init(_opts) do
    Logger.info("[ASC.Deployment] Civilization initialized — REA-1 posture (artifact generation only)")
    {:ok, %{mode: :artifact_only}}
  end
end
