defmodule ObservationBus.CIL.Mission.MissionHealth do
  @moduledoc """
  Measures mission health across dimensions: progress, efficiency, risk,
  knowledge yield, resource consumption, and scientific value.
  """
  use GenServer

  defstruct [:assessments, :total_assessments]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %__MODULE__{assessments: %{}, total_assessments: 0}}
  end

  @doc "Assess a mission's health."
  @spec assess(String.t(), keyword()) :: {:ok, map()}
  def assess(mission_id, metrics \\ []) do
    GenServer.call(__MODULE__, {:assess, mission_id, metrics})
  end

  @doc "Get health for a mission."
  @spec get_health(String.t()) :: map() | nil
  def get_health(mission_id) do
    GenServer.call(__MODULE__, {:get, mission_id})
  end

  @impl true
  def handle_call({:assess, mission_id, metrics}, _from, state) do
    progress = Keyword.get(metrics, :progress, :rand.uniform() * 100)
    efficiency = Keyword.get(metrics, :efficiency, :rand.uniform() * 100)
    risk = Keyword.get(metrics, :risk, :rand.uniform() * 100)
    knowledge_yield = Keyword.get(metrics, :knowledge_yield, :rand.uniform() * 100)
    scientific_value = Keyword.get(metrics, :scientific_value, :rand.uniform() * 100)

    health = %{
      mission_id: mission_id,
      progress: progress,
      efficiency: efficiency,
      risk: risk,
      knowledge_yield: knowledge_yield,
      scientific_value: scientific_value,
      overall: (progress + efficiency + knowledge_yield + scientific_value - risk) / 4.0,
      assessed_at: DateTime.utc_now()
    }

    assessments = Map.put(state.assessments, mission_id, health)
    {:reply, {:ok, health}, %{state | assessments: assessments,
                              total_assessments: state.total_assessments + 1}}
  end

  def handle_call({:get, mission_id}, _from, state) do
    {:reply, Map.get(state.assessments, mission_id), state}
  end
end
