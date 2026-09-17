defmodule Tiannara.Sentinel.Immune.ConfidenceCalibrator do
  @moduledoc """
  Adjusts raw confidence scores based on the historical success rate of a given action/anomaly type.
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def update_priors(action_type, success_score) do
    GenServer.cast(__MODULE__, {:update_priors, action_type, success_score})
  end

  def get_calibration_factor(action_type) do
    GenServer.call(__MODULE__, {:get_factor, action_type})
  end

  @impl true
  def init(_opts) do
    # action -> {total_score, count}
    {:ok, %{priors: %{}}}
  end

  @impl true
  def handle_cast({:update_priors, action_type, success_score}, state) do
    {total_score, count} = Map.get(state.priors, action_type, {0.0, 0})
    new_priors = Map.put(state.priors, action_type, {total_score + success_score, count + 1})
    {:noreply, %{state | priors: new_priors}}
  end

  @impl true
  def handle_call({:get_factor, action_type}, _from, state) do
    factor = case Map.get(state.priors, action_type) do
      nil -> 1.0
      {total, count} -> total / count
    end
    {:reply, factor, state}
  end
end
