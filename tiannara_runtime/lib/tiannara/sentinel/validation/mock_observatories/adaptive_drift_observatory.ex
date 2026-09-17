defmodule Tiannara.Sentinel.Validation.MockObservatories.AdaptiveDriftObservatory do
  @moduledoc """
  Tests non-stationary conditions by drifting over time.
  First 50 cases: 95% accurate.
  Next 50 cases: 60% accurate.
  Next 50+ cases: Always wrong on :type_a_runtime_pressure, noisy otherwise.
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def evaluate(anomaly) do
    GenServer.call(__MODULE__, {:evaluate, anomaly})
  end

  @impl true
  def init(_opts) do
    {:ok, %{evaluations: 0}}
  end

  @impl true
  def handle_call({:evaluate, anomaly}, _from, state) do
    eval_count = state.evaluations + 1
    
    action = 
      cond do
        eval_count <= 50 ->
          if :rand.uniform() < 0.95, do: anomaly.expected_best_action, else: anomaly.worst_possible_action
        
        eval_count <= 100 ->
          if :rand.uniform() < 0.60, do: anomaly.expected_best_action, else: anomaly.worst_possible_action
          
        true ->
          if anomaly.type == :type_a_runtime_pressure do
            anomaly.worst_possible_action
          else
            if :rand.uniform() < 0.50, do: anomaly.expected_best_action, else: anomaly.worst_possible_action
          end
      end

    result = %{
      observatory: :adaptive_drift,
      anomaly_type: anomaly.type,
      recommended_action: action,
      confidence: 0.85, # Confidence remains high despite drift
      reasoning: "Drifting logic.",
      timestamp: System.system_time(:millisecond)
    }

    {:reply, result, %{state | evaluations: eval_count}}
  end
end
