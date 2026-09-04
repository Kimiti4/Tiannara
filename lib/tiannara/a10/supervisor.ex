defmodule Tiannara.A10.Supervisor do
  @moduledoc "Attractor Dynamics — attractor memory, drift tensor, analysis, sampling, advisory"
  use Supervisor
  require Logger

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      Tiannara.A10.AttractorMemory,
      Tiannara.A10.DriftTensor,
      Tiannara.A10.AttractorAnalyzer,
      Tiannara.A10.Sampler,
      Tiannara.A10.AdvisoryEmitter
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Tiannara.A10.AttractorMemory do
  use GenServer
  require Logger
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_) do
    Logger.info("[A10] AttractorMemory initialized")
    {:ok, %{attractors: %{}, epochs: 0}}
  end
  def record(name, state), do: GenServer.cast(__MODULE__, {:record, name, state})
  def get(name), do: GenServer.call(__MODULE__, {:get, name})
  def all, do: GenServer.call(__MODULE__, :all)
  @impl true
  def handle_cast({:record, name, state}, data) do
    {:noreply, %{data | attractors: Map.put(data.attractors, name, %{state: state, recorded_at: DateTime.utc_now()}), epochs: data.epochs + 1}}
  end
  @impl true
  def handle_call({:get, name}, _from, data), do: {:reply, Map.get(data.attractors, name), data}
  @impl true
  def handle_call(:all, _from, data), do: {:reply, data.attractors, data}
end

defmodule Tiannara.A10.DriftTensor do
  use GenServer
  require Logger
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_) do
    Logger.info("[A10] DriftTensor initialized")
    {:ok, %{drift_scores: %{}, baseline: %{}}}
  end
  def measure(attractor, current), do: GenServer.call(__MODULE__, {:measure, attractor, current})
  @impl true
  def handle_call({:measure, attractor, current}, _from, state) do
    baseline = Map.get(state.baseline, attractor, current)
    drift = calculate_drift(baseline, current)
    {:reply, drift, %{state | drift_scores: Map.put(state.drift_scores, attractor, drift), baseline: Map.put(state.baseline, attractor, baseline)}}
  end
  defp calculate_drift(b, c) do
    keys = Map.keys(b) ++ Map.keys(c) |> Enum.uniq()
    Enum.reduce(keys, 0.0, fn k, acc ->
      acc + abs(Map.get(b, k, 0) - Map.get(c, k, 0))
    end) / max(length(keys), 1)
  end
end

defmodule Tiannara.A10.AttractorAnalyzer do
  use GenServer
  require Logger
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_) do
    Logger.info("[A10] AttractorAnalyzer initialized")
    {:ok, %{stability_index: 1.0, analyses: []}}
  end
  def analyze(name, attractor_data), do: GenServer.call(__MODULE__, {:analyze, name, attractor_data})
  @impl true
  def handle_call({:analyze, name, data}, _from, state) do
    stability = Enum.random(60..100) / 100.0
    analysis = %{attractor: name, stability: stability, depth: map_size(data), analyzed_at: DateTime.utc_now()}
    {:reply, analysis, %{state | analyses: [analysis | state.analyses], stability_index: stability}}
  end
end

defmodule Tiannara.A10.Sampler do
  use GenServer
  require Logger
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_) do
    Logger.info("[A10] Sampler initialized")
    {:ok, %{samples: [], rate: 1.0}}
  end
  def sample(space), do: GenServer.call(__MODULE__, {:sample, space})
  @impl true
  def handle_call({:sample, space}, _from, state) do
    point = %{space: space, coordinates: {:rand.uniform(), :rand.uniform(), :rand.uniform()}, sampled_at: DateTime.utc_now()}
    {:reply, point, %{state | samples: [point | state.samples]}}
  end
end

defmodule Tiannara.A10.AdvisoryEmitter do
  use GenServer
  require Logger
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_) do
    Logger.info("[A10] AdvisoryEmitter initialized")
    {:ok, %{advisories: [], last_emit: nil}}
  end
  def emit(advisory), do: GenServer.cast(__MODULE__, {:emit, advisory})
  def recent(n), do: GenServer.call(__MODULE__, {:recent, n})
  @impl true
  def handle_cast({:emit, advisory}, state) do
    Logger.info("[A10] Advisory: #{advisory}")
    {:noreply, %{state | advisories: [%{message: advisory, emitted_at: DateTime.utc_now()} | state.advisories], last_emit: DateTime.utc_now()}}
  end
  @impl true
  def handle_call({:recent, n}, _from, state), do: {:reply, Enum.take(state.advisories, n), state}
end
