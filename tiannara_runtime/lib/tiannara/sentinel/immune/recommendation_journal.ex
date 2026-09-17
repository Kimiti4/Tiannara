defmodule Tiannara.Sentinel.Immune.RecommendationJournal do
  @moduledoc """
  Working memory for the Sentinel. Tracks the living state of recommendations
  as they move from :proposed to :evaluated (:successful/:failed).
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def add_recommendation(intervention) do
    GenServer.cast(__MODULE__, {:add, intervention})
  end

  def update_status(id, new_status, updates \\ %{}) do
    GenServer.cast(__MODULE__, {:update, id, new_status, updates})
  end

  def get_pending_evaluation() do
    GenServer.call(__MODULE__, :get_pending_evaluation)
  end

  @impl true
  def init(_opts) do
    {:ok, %{records: %{}}}
  end

  @impl true
  def handle_cast({:add, intervention}, state) do
    new_records = Map.put(state.records, intervention.id, intervention)
    {:noreply, %{state | records: new_records}}
  end

  @impl true
  def handle_cast({:update, id, new_status, updates}, state) do
    case Map.fetch(state.records, id) do
      {:ok, intervention} ->
        updated = 
          intervention
          |> Map.put(:status, new_status)
          |> Map.merge(updates)
        
        {:noreply, %{state | records: Map.put(state.records, id, updated)}}
      :error ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_call(:get_pending_evaluation, _from, state) do
    pending = 
      state.records
      |> Map.values()
      |> Enum.filter(&(&1.status in [:proposed, :observed]))
    {:reply, pending, state}
  end
end
