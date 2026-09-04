defmodule Tiannara.Executive.Cognitive.ContextManager do
  @moduledoc """
  Context Manager — interprets raw observations into structured executive context.

  Transforms low-level signals into meaningful situational awareness that
  the AttentionScheduler and ExecutiveCycle can act upon.
  """

  use GenServer

  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec interpret([map()]) :: map()
  def interpret(observations) when is_list(observations) do
    GenServer.call(__MODULE__, {:interpret, observations})
  end

  @spec current_context() :: map()
  def current_context do
    GenServer.call(__MODULE__, :current_context)
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @impl true
  def init(_opts) do
    {:ok, %{context: %{}, interpretations_count: 0, last_interpretation_at: nil}}
  end

  @impl true
  def handle_call({:interpret, observations}, _from, state) do
    context = build_context(observations)
    {:reply, context, %{state | context: context, interpretations_count: state.interpretations_count + 1, last_interpretation_at: DateTime.utc_now()}}
  end

  @impl true
  def handle_call(:current_context, _from, state) do
    {:reply, state.context, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{interpretations_count: state.interpretations_count, last_interpretation_at: state.last_interpretation_at, context_keys: Map.keys(state.context)}, state}
  end

  defp build_context(observations) do
    classified = Enum.group_by(observations, fn obs -> obs[:type] || :unknown end)
    urgency = Map.new(classified, fn {type, obs_list} ->
      score = compute_urgency(type, obs_list)
      {type, %{count: length(obs_list), urgency: score}}
    end)

    %{
      observations_count: length(observations),
      classified: classified,
      urgency: urgency,
      overall_urgency: compute_overall_urgency(urgency),
      confidence: 0.85,
      interpreted_at: DateTime.utc_now(),
      assumptions: ["Mock interpretation; production will use pattern detection"],
      unknowns: ["True causal relationships not yet established"]
    }
  end

  defp compute_urgency(:anomaly, _obs), do: 0.9
  defp compute_urgency(:degradation, _obs), do: 0.8
  defp compute_urgency(:discovery, _obs), do: 0.6
  defp compute_urgency(:system_health, _obs), do: 0.2
  defp compute_urgency(_type, _obs), do: 0.5

  defp compute_overall_urgency(urgency_map) do
    case Map.values(urgency_map) do
      [] -> 0.0
      entries -> Enum.max_by(entries, & &1.urgency).urgency
    end
  end
end
