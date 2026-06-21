defmodule Tiannara.ASC.APIEvolution.Supervisor do
  use Supervisor
  def start_link(opts \\ []), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_) do
    children = [
      Tiannara.ASC.APIEvolution.Civilization,
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Tiannara.ASC.APIEvolution.Genome do
  @moduledoc "API Genome — the evolvable representation of an API endpoint."

  @derive Jason.Encoder

  @type mutation_op ::
    :endpoint_split | :endpoint_merge | :schema_evolution
    | :protocol_upgrade | :query_optimization | :caching_injection
    | :streaming_upgrade | :eventification

  @mutation_ops [
    :endpoint_split, :endpoint_merge, :schema_evolution,
    :protocol_upgrade, :query_optimization, :caching_injection,
    :streaming_upgrade, :eventification
  ]

  defstruct [
    :id, :endpoint, :method, :inputs, :outputs,
    :capabilities, :dependencies, :version,
    :fitness, :composite_fitness,
    :mutation_history, :status, :created_at
  ]

  @type t :: %__MODULE__{
    id: String.t() | nil,
    endpoint: String.t() | nil,
    method: String.t() | nil,
    inputs: list(),
    outputs: list(),
    capabilities: list(),
    dependencies: list(),
    version: String.t() | nil,
    fitness: map() | nil,
    composite_fitness: float() | nil,
    mutation_history: [mutation_op()],
    status: :active | :deprecated | :archived | nil,
    created_at: DateTime.t() | nil
  }

  @spec new(String.t(), String.t()) :: t()
  def new(endpoint, method \\ "GET") do
    %__MODULE__{
      id: "api_#{:erlang.unique_integer([:positive, :monotonic])}",
      endpoint: endpoint,
      method: method,
      inputs: [],
      outputs: [],
      capabilities: [],
      dependencies: [],
      version: "1.0.0",
      fitness: neutral_fitness(),
      composite_fitness: 0.5,
      mutation_history: [],
      status: :active,
      created_at: DateTime.utc_now()
    }
  end

  @spec mutate(t()) :: t()
  def mutate(%__MODULE__{} = genome) do
    op = Enum.random(@mutation_ops)
    %{genome |
      mutation_history: [op | genome.mutation_history],
      version: bump_version(genome.version)
    }
  end

  @spec compute_composite_fitness(t()) :: float()
  def compute_composite_fitness(%__MODULE__{fitness: f}) do
    # Weights sum to 1.0
    # business_value and knowledge_value added; existing weights reduced proportionally.
    weights = %{
      latency_ms:         -0.175,  # was -0.20
      throughput_rps:      0.175,  # was +0.20
      error_rate:         -0.175,  # was -0.20
      adoption:            0.175,  # was +0.20
      maintainability:     0.10,
      coupling:           -0.05,
      developer_friction: -0.05,
      business_value:      0.15,   # NEW — strategic leverage
      knowledge_value:     0.10    # NEW — feeds REA evidence loop
    }
    raw = Enum.reduce(weights, 0.0, fn {k, w}, acc ->
      acc + Map.get(f, k, 0.5) * w
    end)
    ((raw + 1.0) / 2.0) |> Float.round(4)
  end

  defp neutral_fitness do
    %{
      latency_ms:         0.5,
      throughput_rps:     0.5,
      error_rate:         0.0,
      adoption:           0.5,
      maintainability:    0.5,
      coupling:           0.3,
      developer_friction: 0.3,
      business_value:     0.5,   # NEW
      knowledge_value:    0.5    # NEW
    }
  end

  defp bump_version(v) do
    case String.split(v, ".") do
      [major, minor, patch] ->
        "#{major}.#{minor}.#{String.to_integer(patch) + 1}"
      _ -> "#{v}.1"
    end
  end
end

defmodule Tiannara.ASC.APIEvolution.Civilization do
  @moduledoc """
  API Evolution Civilization (Phase G).

  Manages the lifecycle of API genomes across a project:
  Discover → Generate → Version → Validate → Deprecate → Evolve.

  Natural selection criteria (from the approved plan):
    - Archive if composite_fitness < 0.20 for 3 consecutive cycles
    - Archive if error_rate > 0.05 sustained > 10 min
    - Replicate if composite_fitness > 0.85

  Records `api_fitness` to Observatory after each evolution cycle.

  ## Current Status: Phase G stub with Genome struct active.
  """

  use GenServer
  require Logger

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @spec run(Tiannara.ASC.Project.t()) :: {:ok, :stub}
  def run(_project), do: {:ok, :stub}

  @impl true
  def init(_opts) do
    Logger.info("[ASC.APIEvolution] Civilization initialized (Phase G stub — Genome struct active)")
    {:ok, %{genomes: %{}}}
  end
end
