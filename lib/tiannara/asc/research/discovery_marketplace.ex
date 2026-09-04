defmodule Tiannara.ASC.Research.DiscoveryMarketplace do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def list_discovery(discovery) do
    GenServer.cast(__MODULE__, {:list, discovery})
  end

  def top(n \\ 10), do: GenServer.call(__MODULE__, {:top, n})

  def stats, do: GenServer.call(__MODULE__, :stats)

  @impl true
  def init(_opts) do
    {:ok, %{listings: [], total_listed: 0, started_at: DateTime.utc_now()}}
  end

  @impl true
  def handle_cast({:list, discovery}, state) do
    scored = score_discovery(discovery)
    {:noreply, %{state |
      listings: [scored | state.listings] |> Enum.sort_by(& &1.score, :desc) |> Enum.take(500),
      total_listed: state.total_listed + 1
    }}
  end

  @impl true
  def handle_call({:top, n}, _from, state) do
    {:reply, Enum.take(state.listings, n), state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{
      total_listed: state.total_listed,
      active_listings: length(state.listings),
      top_score: case state.listings do
        [top | _] -> top.score
        [] -> 0.0
      end
    }, state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp score_discovery(discovery) do
    confidence = Map.get(discovery, :confidence, 0.5)
    impact = Map.get(discovery, :impact, 0.5)
    novelty = Map.get(discovery, :novelty, 0.5)
    urgency = Map.get(discovery, :urgency, 0.5)

    score = confidence * impact * (0.5 + 0.5 * novelty) * (0.5 + 0.5 * urgency)

    Map.put(discovery, :score, score)
  end
end
