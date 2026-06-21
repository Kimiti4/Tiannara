defmodule Tiannara.ASC.Research.Supervisor do
  use Supervisor
  def start_link(opts \\ []), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_), do: Supervisor.init([Tiannara.ASC.Research.Civilization], strategy: :one_for_one)
end

defmodule Tiannara.ASC.Research.Civilization do
  @moduledoc """
  Research Civilization.

  Before any architecture is chosen, this civilization researches the
  solution space: frameworks, libraries, protocols, patterns, security models,
  scalability models, and deployment strategies.

  Consumes hints from `ASC.DomainObserver` (domain discoveries) and
  `ASC.ResearchBridge` (portfolio vectors) to bias research toward
  approaches that are already validated in related Tiannara domains.

  Output: candidate solutions map with tradeoffs, expected risks, and
  confidence scores — stored in `data/asc_projects/<id>/docs/research.json`.

  ## Current Status: Phase C stub
  """

  use GenServer
  require Logger

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @spec run(Tiannara.ASC.Project.t()) :: {:ok, :stub}
  def run(_project), do: {:ok, :stub}

  @impl true
  def init(_opts) do
    Phoenix.PubSub.subscribe(Tiannara.PubSub, "asc:research:hint")
    Phoenix.PubSub.subscribe(Tiannara.PubSub, "asc:research:domain_vectors")
    Logger.info("[ASC.Research] Civilization initialized (Phase C stub)")
    {:ok, %{hints: []}}
  end

  @impl true
  def handle_info(%{source: :domain_observer, discovery: discovery}, state) do
    {:noreply, %{state | hints: [discovery | state.hints]}}
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}
end
