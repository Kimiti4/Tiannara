defmodule Tiannara.Cis.ImmuneMemory do
  @moduledoc """
  CIS immune system memory module for tracking interventions and their effectiveness.
  """

  @telemetry_prefix "tiannara.cis.immune_memory"

  use GenServer

  @type intervention_id :: String.t()
  @type intervention_record :: %{
          id: intervention_id(),
          before_state: map(),
          after_state: map(),
          success: boolean(),
          timestamp: DateTime.t(),
          effectiveness_score: float()
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec record_intervention(intervention_record()) :: {:ok, intervention_id()} | {:error, term()}
  def record_intervention(intervention) do
    GenServer.call(__MODULE__, {:record_intervention, intervention})
  end

  @spec get_intervention(intervention_id()) :: {:ok, intervention_record()} | {:error, :not_found}
  def get_intervention(intervention_id) do
    GenServer.call(__MODULE__, {:get_intervention, intervention_id})
  end

  @spec get_successful_interventions() :: {:ok, [intervention_record()]}
  def get_successful_interventions() do
    GenServer.call(__MODULE__, :get_successful_interventions)
  end

  @impl true
  def init(_opts) do
    {:ok, %{interventions: %{}}}
  end

  @impl true
  def handle_call({:record_intervention, intervention}, _from, state) do
    intervention_id = intervention.id
    new_state = Map.put(state.interventions, intervention_id, intervention)
    {:reply, {:ok, intervention_id}, %{state | interventions: new_state}}
  end

  @impl true
  def handle_call({:get_intervention, intervention_id}, _from, state) do
    case Map.get(state.interventions, intervention_id) do
      nil -> {:reply, {:error, :not_found}, state}
      intervention -> {:reply, {:ok, intervention}, state}
    end
  end

  @impl true
  def handle_call(:get_successful_interventions, _from, state) do
    successful = 
      state.interventions
      |> Map.values()
      |> Enum.filter(fn i -> i.success end)
    {:reply, {:ok, successful}, state}
  end
end