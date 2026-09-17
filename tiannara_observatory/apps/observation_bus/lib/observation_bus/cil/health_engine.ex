defmodule ObservationBus.CIL.HealthEngine do
  @moduledoc """
  Computes a single constitutional health state for Tiannara.

  Aggregates across 8 dimensions: runtime, knowledge, science, engineering,
  evolution, governance, certification, security.

  Produces overall health, per-subsystem health, confidence, drift,
  instability, and recovery potential.
  """

  use GenServer

  @dimensions ~w(runtime knowledge science engineering evolution governance certification security)a

  defstruct [:dimensions, :last_computed, :health_history]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    dims = Enum.into(@dimensions, %{}, fn d -> {d, default_dimension_health()} end)
    {:ok, %__MODULE__{
      dimensions: dims,
      last_computed: nil,
      health_history: :queue.new()
    }}
  end

  @doc "Update a dimension's health score."
  @spec update_dimension(atom(), number(), map()) :: :ok
  def update_dimension(dimension, score, metadata \\ %{}) when dimension in @dimensions do
    GenServer.cast(__MODULE__, {:update, dimension, score, metadata})
  end

  @doc "Compute and return current constitutional health."
  @spec current_health() :: map()
  def current_health do
    GenServer.call(__MODULE__, :current_health)
  end

  @doc "Get health history."
  @spec health_history(pos_integer()) :: [map()]
  def health_history(count \\ 10) do
    GenServer.call(__MODULE__, {:history, count})
  end

  @doc "Get engine stats."
  @spec stats() :: map()
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def handle_cast({:update, dimension, score, metadata}, state) do
    updated = %{score: score, last_updated: DateTime.utc_now(), metadata: metadata}
    dims = put_in(state.dimensions[dimension], updated)
    {:noreply, %{state | dimensions: dims}}
  end

  @impl true
  def handle_call(:current_health, _from, state) do
    now = DateTime.utc_now()
    dim_scores = Enum.map(state.dimensions, fn {d, h} -> {d, h.score} end)
    scores = Enum.map(dim_scores, &elem(&1, 1))
    overall = if length(scores) > 0, do: Enum.sum(scores) / length(scores), else: 0.0

    result = %{
      overall_health: normalize(overall),
      timestamp: now,
      subsystems: Enum.into(state.dimensions, %{}, fn {d, h} ->
        {d, %{score: h.score, last_updated: h.last_updated,
              drift: compute_drift(h), instability: compute_instability(h),
              recovery_potential: compute_recovery(h)}}
      end),
      confidence: compute_confidence(state),
      drift: compute_overall_drift(state),
      instability: compute_overall_instability(state),
      recovery_potential: compute_overall_recovery(state)
    }

    history = :queue.in(result, state.health_history)
    history = if :queue.len(history) > 100 do
      {:value, _} = :queue.out(history)
      history
    else
      history
    end

    {:reply, result, %{state | last_computed: now, health_history: history}}
  end

  def handle_call({:history, count}, _from, state) do
    all = :queue.to_list(state.health_history)
    {:reply, Enum.take(all, count), state}
  end

  def handle_call(:stats, _from, state) do
    {:reply, %{
      dimensions: Map.keys(state.dimensions),
      history_size: :queue.len(state.health_history),
      last_computed: state.last_computed
    }, state}
  end

  defp normalize(score), do: max(0.0, min(1.0, score / 100.0))

  defp compute_drift(%{score: score}) do
    cond do
      score > 80 -> :low
      score > 50 -> :moderate
      true -> :high
    end
  end

  defp compute_instability(%{score: score}) do
    cond do
      score > 70 -> :stable
      score > 40 -> :unstable
      true -> :critical
    end
  end

  defp compute_recovery(%{score: score}) do
    cond do
      score > 60 -> :strong
      score > 30 -> :moderate
      true -> :weak
    end
  end

  defp compute_confidence(state) do
    dims = Map.values(state.dimensions)
    scores = Enum.map(dims, & &1.score)
    if length(scores) == 0 do
      0.5
    else
      mean = Enum.sum(scores) / length(scores)
      variance = Enum.map(scores, &((&1 - mean) ** 2)) |> Enum.sum() |> then(&(&1 / length(scores)))
      1.0 - min(0.5, variance / 10000)
    end
  end

  defp compute_overall_drift(state) do
    drifts = Enum.map(Map.values(state.dimensions), &compute_drift/1)
    cond do
      :high in drifts -> :high
      :moderate in drifts -> :moderate
      true -> :low
    end
  end

  defp compute_overall_instability(state) do
    instabilities = Enum.map(Map.values(state.dimensions), &compute_instability/1)
    cond do
      :critical in instabilities -> :critical
      :unstable in instabilities -> :unstable
      true -> :stable
    end
  end

  defp compute_overall_recovery(state) do
    recoveries = Enum.map(Map.values(state.dimensions), &compute_recovery/1)
    cond do
      :weak in recoveries -> :weak
      :moderate in recoveries -> :moderate
      true -> :strong
    end
  end

  defp default_dimension_health do
    %{score: 75.0, last_updated: DateTime.utc_now(), metadata: %{}}
  end
end
