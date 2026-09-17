defmodule Tiannara.MetaSOPL.RateModulationSupervisor do
  @moduledoc """
  LAYER 3: META-SOPL (META-EVOLUTION CONTROL)
  Rate modulation ring. Bounded self-modifying parameters.
  Started by CIS. Adjusts mutation rates, selection pressures via telemetry.
  Cannot directly modify state space (agents, worlds, lineages).
  """
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Tiannara.MetaSOPL.Governor, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Tiannara.MetaSOPL.Governor do
  use GenServer
  use TiannaraRuntime.Layer, authority: :meta, can_call: [:constraint], can_receive: [:constraint]

  alias TiannaraRuntime.Contracts.MetaAdjustment

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_) do
    Process.send_after(self(), :modulate_rates, 5000)
    {:ok, %{mutation_rate: 0.05, selection_pressure: 0.5, entropy_target: 0.65, exploration_temperature: 0.2}}
  end

  @impl true
  def handle_info(:modulate_rates, state) do
    # Fetch telemetry ONLY (no direct state inspection)
    # E.g. get global entropy from stream processor
    # For now, apply bounded drift to mutation rate
    
    new_mutation = state.mutation_rate + ((:rand.uniform() - 0.5) * 0.01)
    new_mutation = max(0.01, min(0.2, new_mutation))
    
    adjustment = %MetaAdjustment{
      mutation_rate: new_mutation,
      selection_pressure: state.selection_pressure,
      entropy_target: state.entropy_target,
      exploration_temperature: state.exploration_temperature
    }

    # Meta remains parameter-space only: emit adjustment contract downward.
    TiannaraRuntime.Layer.assert_call!(:meta, :constraint)
    GenServer.cast(TiannaraRuntime.Cortex.SafetyCortex, {:meta_adjustment, adjustment})
    
    Process.send_after(self(), :modulate_rates, 5000)
    {:noreply, %{state | mutation_rate: new_mutation}}
  end
end
