defmodule Tiannara.Sentinel.Immune.ReasoningArchive do
  @moduledoc """
  Stores full context (anomaly, baseline, recommendation, eventual outcome)
  to serve as historical playback cases for future ESG simulations.
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def archive_case(intervention, success_score) do
    GenServer.cast(__MODULE__, {:archive, intervention, success_score})
  end

  @impl true
  def init(_opts) do
    {:ok, %{cases: []}}
  end

  @impl true
  def handle_cast({:archive, intervention, success_score}, state) do
    case_record = %{
      anomaly_snapshot: intervention.source_anomaly,
      recommendation: intervention,
      confidence: intervention.confidence,
      eventual_outcome: success_score,
      archived_at: System.system_time(:second)
    }
    
    {:noreply, %{state | cases: [case_record | state.cases]}}
  end
end
