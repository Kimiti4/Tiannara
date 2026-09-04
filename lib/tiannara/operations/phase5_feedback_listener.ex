defmodule Tiannara.Operations.Phase5FeedbackListener do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def trigger_discovery, do: GenServer.cast(__MODULE__, :trigger_discovery)
  def state, do: GenServer.call(__MODULE__, :state)

  @impl true
  def init(_opts) do
    subscribe_to_inputs()
    {:ok, %{
      cycles: 0,
      last_feedback_at: nil,
      discoveries_triggered: 0,
      feedbacks_received: 0
    }}
  end

  @impl true
  def handle_cast(:trigger_discovery, state) do
    trigger_phase5_discovery()
    {:noreply, %{state | discoveries_triggered: state.discoveries_triggered + 1}}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info({:executive_bus_message, %{type: "campaign.phase5.input", payload: _payload}}, state) do
    Logger.info("Phase5FeedbackListener: Received Phase 10 campaign output — closing the loop")
    trigger_phase5_discovery()
    {:noreply, %{state |
      cycles: state.cycles + 1,
      last_feedback_at: DateTime.utc_now(),
      feedbacks_received: state.feedbacks_received + 1
    }}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp trigger_phase5_discovery do
    try do
      Tiannara.Discovery.DiscoveryScheduler.trigger_cycle()
      Logger.info("Phase5FeedbackListener: Triggered Phase 5 discovery cycle")
    rescue
      e -> Logger.warning("Phase5FeedbackListener: Discovery trigger failed: #{inspect(e)}")
    end

    try do
      Tiannara.Operations.FeedbackLoop.trigger_feedback()
      Logger.info("Phase5FeedbackListener: Triggered FeedbackLoop")
    rescue
      _ -> :ok
    end
  end

  defp subscribe_to_inputs do
    try do
      Tiannara.CEL.Services.EventBus.subscribe("campaign.phase5.input")
    rescue
      _ -> :ok
    end
  end
end
