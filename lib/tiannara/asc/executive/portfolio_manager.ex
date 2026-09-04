defmodule Tiannara.ASC.Executive.PortfolioManager do
  @moduledoc """
  Phase 10: Manages competing missions across different civilizational categories.
  Prevents monomania by enforcing strategic budget allocation.
  """
  use GenServer
  require Logger

  @total_civilizational_budget 50_000
  
  # Strategic weights: How much of the civilization's effort goes to each category?
  @strategic_weights %{
    product_delivery: 0.50,
    internal_research: 0.30,
    infrastructure: 0.20
  }

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{missions: [], epoch: 0}}
  end

  def register_mission(%Tiannara.ASC.Executive.Mission{} = mission) do
    GenServer.call(__MODULE__, {:register, mission})
  end

  def allocate_epoch_budgets do
    GenServer.call(__MODULE__, :allocate)
  end

  def handle_call({:register, mission}, _from, state) do
    missions = [mission | state.missions]
    Logger.info("📂 [Portfolio] Registered Mission: #{mission.name} (Category: #{mission.category})")
    {:reply, :ok, %{state | missions: missions}}
  end

  def handle_call(:allocate, _from, state) do
    allocations = 
      Enum.group_by(state.missions, & &1.category)
      |> Enum.flat_map(fn {category, category_missions} ->
        category_budget = trunc(@total_civilizational_budget * Map.get(@strategic_weights, category, 0.0))
        active_missions = Enum.filter(category_missions, & &1.status == :active)
        
        if Enum.empty?(active_missions) do
          []
        else
          # Distribute category budget evenly among active missions in that category
          per_mission_budget = trunc(category_budget / length(active_missions))
          Enum.map(active_missions, fn m -> {m.id, per_mission_budget} end)
        end
      end)
      |> Map.new()

    Logger.info("💰 [Portfolio] Epoch #{state.epoch + 1} Budget Allocated across #{map_size(allocations)} active missions.")
    {:reply, allocations, %{state | epoch: state.epoch + 1}}
  end
end
