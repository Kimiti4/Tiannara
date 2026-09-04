defmodule Tiannara.Metrics.CivilizationalMetricsEngine do
  use GenServer
  require Logger

  @collect_interval :timer.minutes(10)
  @window_size 1000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def snapshot, do: GenServer.call(__MODULE__, :snapshot)

  def kpi(name), do: GenServer.call(__MODULE__, {:kpi, name})

  def trend(name, window \\ 100), do: GenServer.call(__MODULE__, {:trend, name, window})

  def record(name, value, metadata \\ %{}), do: GenServer.cast(__MODULE__, {:record, name, value, metadata})

  def health_score, do: GenServer.call(__MODULE__, :health_score)

  @impl true
  def init(_opts) do
    schedule_collection()

    {:ok, %{
      kpis: initial_kpis(),
      history: [],
      started_at: DateTime.utc_now(),
      last_collection: nil
    }}
  end

  @impl true
  def handle_call(:snapshot, _from, state) do
    {:reply, build_snapshot(state), state}
  end

  @impl true
  def handle_call({:kpi, name}, _from, state) do
    case Map.fetch(state.kpis, name) do
      {:ok, kpi} -> {:reply, {:ok, kpi}, state}
      :error -> {:reply, {:error, :unknown_kpi}, state}
    end
  end

  @impl true
  def handle_call({:trend, name, window}, _from, state) do
    history =
      state.history
      |> Enum.filter(&(Map.get(&1, :kpi) == name))
      |> Enum.take(window)
      |> Enum.reverse()

    {:reply, history, state}
  end

  @impl true
  def handle_call(:health_score, _from, state) do
    {:reply, compute_health_score(state), state}
  end

  @impl true
  def handle_cast({:record, name, value, metadata}, state) do
    entry = %{
      kpi: name,
      value: value,
      metadata: metadata,
      at: DateTime.utc_now()
    }

    kpis = Map.update(state.kpis, name, %{current: value, history: [value]}, fn kpi ->
      %{kpi |
        current: value,
        history: [value | Map.get(kpi, :history, [])] |> Enum.take(@window_size)
      }
    end)

    {:noreply, %{state |
      kpis: kpis,
      history: [entry | state.history] |> Enum.take(@window_size * 12)
    }}
  end

  @impl true
  def handle_info(:collect, state) do
    snapshot = build_snapshot(state)

    :telemetry.execute([:tiannara, :civilizational, :metrics], %{
      health_score: compute_health_score(state),
      research_acceleration: get_in(snapshot, [:kpis, :research_acceleration, :current]) || 0.0,
      knowledge_production: get_in(snapshot, [:kpis, :knowledge_production, :current]) || 0.0,
      discovery_efficiency: get_in(snapshot, [:kpis, :discovery_efficiency, :current]) || 0.0
    }, %{})

    schedule_collection()
    {:noreply, %{state | last_collection: DateTime.utc_now()}}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp initial_kpis do
    %{
      research_acceleration: %{current: 0.0, history: [], unit: :ratio, description: "Rate of research output vs. baseline"},
      knowledge_production: %{current: 0.0, history: [], unit: :count_per_day, description: "New knowledge items produced per day"},
      engineering_throughput: %{current: 0.0, history: [], unit: :designs_per_day, description: "Engineering designs produced per day"},
      discovery_efficiency: %{current: 0.0, history: [], unit: :ratio, description: "Discoveries completed / discoveries started"},
      scientific_reproducibility: %{current: 0.0, history: [], unit: :ratio, description: "Replication success rate"},
      resource_efficiency: %{current: 0.0, history: [], unit: :ratio, description: "Value produced per resource unit"},
      system_reliability: %{current: 1.0, history: [], unit: :ratio, description: "Uptime and error-free operation rate"},
      human_collaboration: %{current: 0.0, history: [], unit: :ratio, description: "Human review effectiveness"},
      novel_discovery_rate: %{current: 0.0, history: [], unit: :count_per_month, description: "Novel discoveries per month"},
      sustainability_index: %{current: 0.0, history: [], unit: :ratio, description: "Long-term sustainability score"},
      automation_capability: %{current: 0.0, history: [], unit: :ratio, description: "Fraction of tasks fully automated"},
      civilizational_impact: %{current: 0.0, history: [], unit: :score, description: "Forecasted civilizational impact"}
    }
  end

  defp build_snapshot(state) do
    %{
      kpis: state.kpis,
      health_score: compute_health_score(state),
      started_at: state.started_at,
      last_collection: state.last_collection,
      history_depth: length(state.history)
    }
  end

  defp compute_health_score(state) do
    weights = %{
      research_acceleration: 0.15,
      knowledge_production: 0.15,
      discovery_efficiency: 0.15,
      scientific_reproducibility: 0.10,
      system_reliability: 0.15,
      human_collaboration: 0.10,
      sustainability_index: 0.10,
      resource_efficiency: 0.10
    }

    total_weight = Enum.reduce(weights, 0.0, fn {_k, w}, acc -> acc + w end)

    weighted_sum =
      Enum.reduce(weights, 0.0, fn {kpi_name, weight}, acc ->
        value = get_in(state.kpis, [kpi_name, :current]) || 0.0
        acc + value * weight
      end)

    if total_weight > 0, do: weighted_sum / total_weight, else: 0.0
  end

  defp schedule_collection do
    Process.send_after(self(), :collect, @collect_interval)
  end
end
