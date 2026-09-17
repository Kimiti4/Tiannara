defmodule ObservationBus.CIL.RecommendationEngine do
  @moduledoc """
  Generates constitutional recommendations based on detected patterns,
  anomalies, and health state.

  Recommendations remain advisory — they inform Mission Control operators
  but do not trigger automatic actions.
  """

  use GenServer

  defstruct [:recommendations, :total_generated, :last_updated]

  @recommendation_templates %{
    discovery_burst: "Increase experiment diversity to capitalize on discovery momentum",
    knowledge_stagnation: "Expand ontology coverage and invest in knowledge synthesis",
    experiment_bottleneck: "Reduce replay frequency and rebalance experiment portfolio",
    engineering_acceleration: "Channel engineering velocity toward certification readiness",
    certification_regression: "Re-certify subsystem and investigate regression root cause",
    resource_starvation: "Increase simulation budget and investigate resource contention",
    runtime: "Monitor runtime health and scale resources if needed",
    scientific: "Review scientific discovery pipeline for bottlenecks",
    knowledge: "Investigate anomaly in knowledge domain and update ontology",
    security: "Escalate security anomaly for immediate review",
  }

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %__MODULE__{
      recommendations: [],
      total_generated: 0,
      last_updated: nil
    }}
  end

  @doc "Generate a recommendation from a detected pattern."
  @spec from_pattern(atom(), map()) :: {:ok, map()}
  def from_pattern(pattern_type, metadata \\ %{}) do
    GenServer.call(__MODULE__, {:from_pattern, pattern_type, metadata})
  end

  @doc "Generate a recommendation from an anomaly."
  @spec from_anomaly(map()) :: {:ok, map()}
  def from_anomaly(anomaly) do
    GenServer.call(__MODULE__, {:from_anomaly, anomaly})
  end

  @doc "Generate recommendations from health state."
  @spec from_health(map()) :: [{:ok, map()}]
  def from_health(health_state) do
    GenServer.call(__MODULE__, {:from_health, health_state})
  end

  @doc "Return all active recommendations."
  @spec list_recommendations(keyword()) :: [map()]
  def list_recommendations(filters \\ []) do
    GenServer.call(__MODULE__, {:list, filters})
  end

  @doc "Acknowledge/dismiss a recommendation."
  @spec acknowledge(String.t()) :: :ok
  def acknowledge(id) do
    GenServer.cast(__MODULE__, {:acknowledge, id})
  end

  @doc "Return engine stats."
  @spec stats() :: map()
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def handle_call({:from_pattern, pattern_type, metadata}, _from, state) do
    template = Map.get(@recommendation_templates, pattern_type, "Review pattern and take appropriate action")
    rec = build_recommendation(:pattern, pattern_type, template, metadata, state)
    {:reply, {:ok, rec}, %{state | recommendations: [rec | state.recommendations],
                            total_generated: state.total_generated + 1}}
  end

  def handle_call({:from_anomaly, anomaly}, _from, state) do
    category = Map.get(anomaly, :category)
    text = Map.get(@recommendation_templates, category,
                   Map.get(anomaly, :recommended_action, "Investigate anomaly"))
    rec = build_recommendation(:anomaly, category, text, anomaly, state)
    {:reply, {:ok, rec}, %{state | recommendations: [rec | state.recommendations],
                            total_generated: state.total_generated + 1}}
  end

  def handle_call({:from_health, health_state}, _from, state) do
    recs = Enum.flat_map(Map.get(health_state, :subsystems, %{}), fn {dim, info} ->
      if info.drift in [:high, :moderate] or info.instability in [:critical] do
        text = Map.get(@recommendation_templates, dim, "Review #{dim} health")
        [build_recommendation(:health, dim, text, info, state)]
      else
        []
      end
    end)
    {:reply, Enum.map(recs, &{:ok, &1}),
     %{state | recommendations: recs ++ state.recommendations,
               total_generated: state.total_generated + length(recs)}}
  end

  def handle_call({:list, filters}, _from, state) do
    type = Keyword.get(filters, :type)
    acknowledged = Keyword.get(filters, :acknowledged)

    filtered = Enum.filter(state.recommendations, fn r ->
      (is_nil(type) or r.type == type) and
      (is_nil(acknowledged) or r.acknowledged == acknowledged)
    end)
    {:reply, filtered, state}
  end

  def handle_call(:stats, _from, state) do
    {:reply, %{
      total_generated: state.total_generated,
      active: length(Enum.reject(state.recommendations, & &1.acknowledged)),
      total_stored: length(state.recommendations),
      last_updated: state.last_updated
    }, state}
  end

  @impl true
  def handle_cast({:acknowledge, id}, state) do
    updated = Enum.map(state.recommendations, fn r ->
      if r.id == id, do: %{r | acknowledged: true}, else: r
    end)
    {:noreply, %{state | recommendations: updated}}
  end

  defp build_recommendation(source_type, category, text, metadata, _state) do
    %{
      id: uuid_v4(),
      source: source_type,
      category: category,
      text: text,
      metadata: metadata,
      generated_at: DateTime.utc_now(),
      acknowledged: false,
      priority: compute_priority(category)
    }
  end

  defp compute_priority(:security), do: 90
  defp compute_priority(:resource_starvation), do: 85
  defp compute_priority(:runtime), do: 80
  defp compute_priority(:certification_regression), do: 75
  defp compute_priority(_), do: 50

  defp uuid_v4 do
    <<a::64, b::64>> = :crypto.strong_rand_bytes(16)
    <<u1::48, _::4, u2::12, _::2, u3::62>> = <<a::64, b::64>>
    <<u1::48, 4::4, u2::12, 2::2, u3::62>>
    |> Base.encode16(case: :lower)
    |> then(fn s ->
      "#{String.slice(s, 0, 8)}-#{String.slice(s, 8, 4)}-#{String.slice(s, 12, 4)}-#{String.slice(s, 16, 4)}-#{String.slice(s, 20, 12)}"
    end)
  end
end
