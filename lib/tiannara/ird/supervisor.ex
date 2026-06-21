defmodule Tiannara.IRD.Supervisor do
  use GenServer
  require Logger

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def init(_) do
    {:ok, %{
      intervention_log: [],
      interference_threshold: 0.75,
      budget_remaining: 100.0,
      quiescent: false,
      config: %{budget_max: 100.0, budget_refresh_ms: 1000, quiescence_duration_ms: 200}
    }}
  end

  def propose_intervention(module, action, intensity) do
    GenServer.cast(__MODULE__, {:propose, module, action, intensity})
  end

  def get_interference_matrix, do: GenServer.call(__MODULE__, :get_interference)
  def get_budget_remaining, do: GenServer.call(__MODULE__, :get_budget)

  def handle_cast({:propose, module, action, intensity}, state) do
    now = System.monotonic_time(:millisecond)
    if now < state.quiescent do
      Logger.info("IRD: System quiescent, deferring intervention")
      {:noreply, state}
    else
      new_log = [%{module: module, action: action, intensity: intensity} | Enum.take(state.intervention_log, 99)]
      interference_score = compute_interference(new_log)
      
      cond do
        interference_score > state.interference_threshold ->
          Logger.warning("IRD: Resonance cascade detected. Initiating quiescence.")
          {:noreply, %{state | quiescent: now + state.config.quiescence_duration_ms, intervention_log: []}}
        state.budget_remaining < intensity ->
          Logger.info("IRD: Budget exceeded. Deferring intervention.")
          {:noreply, %{state | intervention_log: new_log}}
        true ->
          {:noreply, %{state | intervention_log: new_log, budget_remaining: state.budget_remaining - intensity}}
      end
    end
  end

  def handle_call(:get_interference, _from, state) do
    score = compute_interference(state.intervention_log)
    {:reply, score, state}
  end

  def handle_call(:get_budget, _from, state), do: {:reply, state.budget_remaining, state}

  defp compute_interference(log) do
    if Enum.empty?(log) do
      0.0
    else
      modules = Enum.map(log, fn %{module: m} -> m end)
      module_freq = Enum.frequencies(modules)
      max_freq = Enum.max(Map.values(module_freq), fn -> 1 end)
      min(1.0, max_freq / max(1, length(log)))
    end
  end
end
