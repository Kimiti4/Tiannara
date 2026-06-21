defmodule Tiannara.ASC.MetaLearning.Supervisor do
  use Supervisor
  def start_link(opts \\ []), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_), do: Supervisor.init([Tiannara.ASC.MetaLearning.Civilization], strategy: :one_for_one)
end

defmodule Tiannara.ASC.MetaLearning.Civilization do
  @moduledoc """
  Meta-Learning Civilization (Phase I).

  The oracle that learns across projects and injects knowledge back into
  future projects. Reads `Laws.Registry` and `KnowledgeArchive` to produce
  `Insight` structs broadcast on `"asc:meta:insight"`.

  Learns:
    - Which architectures succeed (feeds Architecture.Civilization genome seeds)
    - Which APIs survive (feeds APIEvolution natural selection pressure)
    - Which tests find the most bugs (feeds Testing.Civilization strategy weights)
    - Which deployments fail (feeds Deployment.Civilization checklist)
    - Which repair strategies work (feeds Repair pipeline strategy selection)

  Also runs `Laws.Discoverer` as a sub-task to keep law discovery continuous.

  ## Current Status: Phase I stub — Laws.Discoverer sub-task active.
  """

  use GenServer
  require Logger

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    # Start the Laws Discoverer background loop
    {:ok, _} = Tiannara.ASC.Laws.Discoverer.start_link([])

    Logger.info("[ASC.MetaLearning] Civilization initialized — Laws.Discoverer started")
    {:ok, %{insights: []}}
  end
end
