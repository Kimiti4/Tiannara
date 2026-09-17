defmodule ObservationBus.CIL.Futures.FitnessEvaluator do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def evaluate(future_id), do: GenServer.call(__MODULE__, {:evaluate, future_id})
  def compare(future_a, future_b), do: GenServer.call(__MODULE__, {:compare, future_a, future_b})
  def rankings, do: GenServer.call(__MODULE__, :rankings)

  @impl true
  def init(_opts) do
    scores = %{
      future_1: %{scientific: 0.72, engineering: 0.65, safety: 0.58, sustainability: 0.61, human_benefit: 0.68, knowledge_growth: 0.70, constitution: 0.66, overall: 0.66},
      future_2: %{scientific: 0.85, engineering: 0.80, safety: 0.45, sustainability: 0.50, human_benefit: 0.75, knowledge_growth: 0.82, constitution: 0.60, overall: 0.68},
      future_3: %{scientific: 0.40, engineering: 0.35, safety: 0.90, sustainability: 0.85, human_benefit: 0.50, knowledge_growth: 0.30, constitution: 0.80, overall: 0.59},
      future_4: %{scientific: 0.60, engineering: 0.55, safety: 0.70, sustainability: 0.80, human_benefit: 0.65, knowledge_growth: 0.55, constitution: 0.75, overall: 0.66},
    }
    {:ok, %{scores: scores}}
  end

  @impl true
  def handle_call({:evaluate, id}, _from, state) do
    {:reply, Map.get(state.scores, String.to_atom(id)) || Map.get(state.scores, id), state}
  end
  def handle_call({:compare, a, b}, _from, state) do
    sa = Map.get(state.scores, String.to_atom(a)) || Map.get(state.scores, a)
    sb = Map.get(state.scores, String.to_atom(b)) || Map.get(state.scores, b)
    comparison = if sa && sb do
      dimensions = Map.keys(sa)
      diff = Enum.map(dimensions, fn d -> {d, Map.get(sa, d, 0) - Map.get(sb, d, 0)} end) |> Enum.into(%{})
      %{future_a: a, future_b: b, scores_a: sa, scores_b: sb, differences: diff, winner: if(sa.overall >= sb.overall, do: a, else: b)}
    else
      %{error: :not_found}
    end
    {:reply, comparison, state}
  end
  def handle_call(:rankings, _from, state) do
    ranked = Enum.sort_by(state.scores, fn {_k, v} -> v.overall end, :desc)
    {:reply, ranked, state}
  end
end
