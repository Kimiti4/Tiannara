defmodule Tiannara.Sentinel.Shadow.ShadowMetrics do
  @moduledoc """
  Tracks the accuracy of the shadow simulations for the Sentinel.shadow_accuracy_report() gateway.
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def record_simulation(shadow_result) do
    GenServer.cast(__MODULE__, {:record, shadow_result})
  end

  def get_accuracy_report() do
    GenServer.call(__MODULE__, :get_report)
  end

  @impl true
  def init(_opts) do
    {:ok, %{simulations_run: 0}}
  end

  @impl true
  def handle_cast({:record, _shadow_result}, state) do
    {:noreply, %{state | simulations_run: state.simulations_run + 1}}
  end

  @impl true
  def handle_call(:get_report, _from, state) do
    report = %{
      simulations_run: state.simulations_run,
      shadow_vs_reality_accuracy: 0.0, # Requires actual outcome loop to populate
      outcome_prediction_accuracy: 0.0,
      entropy_prediction_accuracy: 0.0,
      confidence_alignment: 0.0
    }
    {:reply, report, state}
  end
end
