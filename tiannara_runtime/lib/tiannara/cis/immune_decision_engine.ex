defmodule Tiannara.CIS.ImmuneDecisionEngine do
  @moduledoc """
  Evaluates systemic risks and makes ecological immune decisions.
  Subscribes to immune.response events.
  """
  use GenServer
  alias Tiannara.EventBus

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    try do
      EventBus.subscribe("immune.response")
      EventBus.subscribe("drift.advisory")
    rescue
      _ -> :ok
    end
    {:ok, %{decisions: [], last_regulation_time: 0}}
  end

  def handle_info({:collapse_risk, _}, state) do
    decision = :tighten_constraints
    EventBus.broadcast("cis.regulation", :execute_regulation, %{decision: decision})
    {:noreply, %{state | decisions: [decision | state.decisions]}}
  end
  
  def handle_info({:entropy_spike, _}, state) do
    decision = :diffuse
    EventBus.broadcast("cis.regulation", :execute_regulation, %{decision: decision})
    {:noreply, %{state | decisions: [decision | state.decisions]}}
  end
  
  def handle_info({:advisory_issued, %{phase: phase, structural_drift: drift}}, state) do
    # Only regulate if cooldown has passed (e.g., 200ms in simulation time)
    now = System.os_time(:millisecond)
    if now - state.last_regulation_time > 200 do
      # Enforce strict maximum 2% delta
      delta = min(drift * 0.01, 0.02)
      
      # Single-domain modification rule: Only touching pressure bounds based on Phase
      decision = if phase in [:phase_d, :phase_e], do: {:tighten_pressure, delta}, else: :noop
      
      if decision != :noop do
        EventBus.broadcast("cis.regulation", :execute_regulation, %{decision: decision})
      end
      
      {:noreply, %{state | decisions: [decision | state.decisions], last_regulation_time: now}}
    else
      # Cooldown active, ignore advisory
      {:noreply, state}
    end
  end
  
  def handle_info(_, state), do: {:noreply, state}

  def handle_call({:evaluate, signal}, _from, state) do
    decision = case signal do
      :collapse_risk -> :tighten_constraints
      :entropy_spike -> :diffuse
      _ -> :noop
    end

    {:reply, decision, %{state | decisions: [decision | state.decisions]}}
  end
end
