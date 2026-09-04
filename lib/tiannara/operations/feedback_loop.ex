defmodule Tiannara.Operations.FeedbackLoop do
  use GenServer
  require Logger

  @feedback_interval :timer.minutes(30)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def state, do: GenServer.call(__MODULE__, :state)
  def trigger_feedback, do: GenServer.cast(__MODULE__, :feedback)

  @impl true
  def init(_opts) do
    schedule_feedback()
    {:ok, %{
      cycles: 0,
      last_feedback_at: nil,
      observations_fed: 0,
      improvements_identified: 0,
      loop_health: :healthy
    }}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast(:feedback, state) do
    new_state = run_feedback_cycle(state)
    {:noreply, new_state}
  end

  @impl true
  def handle_info(:scheduled_feedback, state) do
    new_state = run_feedback_cycle(state)
    schedule_feedback()
    {:noreply, new_state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp run_feedback_cycle(state) do
    observations = gather_observations()
    evaluation = evaluate_outputs(observations)
    improvements = identify_improvements(evaluation)
    apply_feedback(improvements)

    Logger.info("FeedbackLoop: Cycle #{state.cycles + 1} — #{length(observations)} observations, #{length(improvements)} improvements")

    %{state |
      cycles: state.cycles + 1,
      last_feedback_at: DateTime.utc_now(),
      observations_fed: state.observations_fed + length(observations),
      improvements_identified: state.improvements_identified + length(improvements)
    }
  end

  defp gather_observations do
    observations = []

    observations =
      try do
        stats = Tiannara.Discovery.DiscoveryScheduler.stats()
        [%{type: :discovery_throughput, value: stats.completed_cycles, at: DateTime.utc_now()} | observations]
      rescue
        _ -> observations
      end

    observations =
      try do
        case Tiannara.World.UnifiedWorldModel.stats() do
          %{total_entities: n} -> [%{type: :world_model_size, value: n, at: DateTime.utc_now()} | observations]
          _ -> observations
        end
      rescue
        _ -> observations
      end

    observations =
      try do
        status = Tiannara.ControlCenter.status()
        [%{type: :system_health, value: status.healthy / max(1, status.total), at: DateTime.utc_now()} | observations]
      rescue
        _ -> observations
      end

    observations
  end

  defp evaluate_outputs(observations) do
    %{
      observations: observations,
      meets_discovery_objective: meets_threshold?(observations, :discovery_throughput, 1),
      meets_health_objective: meets_threshold?(observations, :system_health, 0.9),
      meets_knowledge_objective: meets_threshold?(observations, :world_model_size, 10),
      evaluated_at: DateTime.utc_now()
    }
  end

  defp identify_improvements(evaluation) do
    improvements = []

    improvements =
      if not evaluation.meets_discovery_objective do
        [%{type: :increase_discovery_rate, priority: :high, action: "Trigger additional discovery cycles"} | improvements]
      else
        improvements
      end

    improvements =
      if not evaluation.meets_health_objective do
        [%{type: :improve_system_health, priority: :critical, action: "Investigate unhealthy subsystems"} | improvements]
      else
        improvements
      end

    improvements =
      if not evaluation.meets_knowledge_objective do
        [%{type: :increase_knowledge_production, priority: :medium, action: "Seed world model with initial knowledge"} | improvements]
      else
        improvements
      end

    improvements
  end

  defp apply_feedback(improvements) do
    Enum.each(improvements, fn improvement ->
      case improvement.type do
        :increase_discovery_rate ->
          try do
            Tiannara.Discovery.DiscoveryScheduler.trigger_cycle()
          rescue
            _ -> :ok
          end
        :improve_system_health ->
          try do
            Tiannara.ControlCenter.check_health()
          rescue
            _ -> :ok
          end
        _ -> :ok
      end
    end)
  end

  defp meets_threshold?(observations, type, threshold) do
    case Enum.find(observations, &(&1.type == type)) do
      nil -> false
      obs -> obs.value >= threshold
    end
  end

  defp schedule_feedback do
    Process.send_after(self(), :scheduled_feedback, @feedback_interval)
  end
end
