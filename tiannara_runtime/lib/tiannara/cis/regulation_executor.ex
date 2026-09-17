defmodule Tiannara.CIS.RegulationExecutor do
  @moduledoc """
  Executes CIS regulation decisions by interacting with MSCL via PubSub/Casts.
  """
  use GenServer
  alias Tiannara.EventBus

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    EventBus.subscribe("cis.regulation")
    {:ok, %{}}
  end

  def handle_info({:execute_regulation, %{decision: :tighten_constraints}}, state) do
    # Instruct MSCL via cast or event bus
    GenServer.cast(Tiannara.MSCL.ConstraintEngine, {:update_constraint, :pressure, 1.5})
    {:noreply, state}
  end
  
  def handle_info({:execute_regulation, %{decision: :diffuse}}, state) do
    # Instruct OLEF
    GenServer.cast(Tiannara.OLEF.PressureSolver, {:pressure_update, -0.5})
    :telemetry.execute([:tiannara, :cis, :immune_action], %{intensity: 1}, %{decision: :diffuse})
    {:noreply, state}
  end

  def handle_info({:execute_regulation, %{decision: {:tighten_pressure, delta}}}, state) do
    # Gently tune MSCL constraints
    GenServer.cast(Tiannara.MSCL.ConstraintEngine, {:update_constraint, :pressure, 1.0 + delta})
    :telemetry.execute([:tiannara, :cis, :immune_action], %{intensity: delta}, %{decision: :tighten_pressure})
    {:noreply, state}
  end

  def handle_info(_, state), do: {:noreply, state}
end
