defmodule Tiannara.Sentinel.Observatories.Core.AlignmentTracker do
  @moduledoc """
  Tracks the alignment between the live Observatory Mesh consensus and the ESG Shadow Simulation.
  Record only occurs when both systems form a recommendation for the same anomaly.
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def record_alignment(anomaly_id, consensus_action, shadow_action) do
    GenServer.cast(__MODULE__, {:record, anomaly_id, consensus_action, shadow_action})
  end

  def get_alignment_metrics do
    GenServer.call(__MODULE__, :get_metrics)
  end

  @impl true
  def init(_opts) do
    {:ok, %{agreement_cases: 0, divergence_cases: 0}}
  end

  @impl true
  def handle_cast({:record, _anomaly_id, consensus, shadow}, state) do
    if consensus == shadow do
      {:noreply, %{state | agreement_cases: state.agreement_cases + 1}}
    else
      {:noreply, %{state | divergence_cases: state.divergence_cases + 1}}
    end
  end

  @impl true
  def handle_call(:get_metrics, _from, state) do
    total = state.agreement_cases + state.divergence_cases
    alignment = if total == 0, do: 1.0, else: state.agreement_cases / total
    
    {:reply, %{
      alignment: Float.round(alignment, 3),
      agreement_cases: state.agreement_cases,
      divergence_cases: state.divergence_cases
    }, state}
  end
end
