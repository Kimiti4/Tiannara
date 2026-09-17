defmodule Tiannara.Sentinel.Shadow.ReplayFailureArchive do
  @moduledoc """
  Stores instances where the ReplayEngine failed to predict the known historical outcome.
  Phase C.0's primary purpose is discovering where ESG is wrong.
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def archive_failure(replay_case, prediction, accuracy) do
    GenServer.cast(__MODULE__, {:archive, replay_case, prediction, accuracy})
  end

  @impl true
  def init(_opts) do
    {:ok, %{failures: []}}
  end

  @impl true
  def handle_cast({:archive, replay_case, prediction, accuracy}, state) do
    record = %{
      replay_id: replay_case.id,
      anomaly: replay_case.anomaly,
      expected_outcome: replay_case.actual_outcome,
      predicted_outcome: prediction.predicted_success_score,
      mismatch_error: 1.0 - accuracy,
      timestamp: System.system_time(:second)
    }

    {:noreply, %{state | failures: [record | state.failures]}}
  end
end
