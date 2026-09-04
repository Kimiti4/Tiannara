defmodule Tiannara.Agency.Orchestrator do
  @moduledoc """
  Agency Orchestrator -- the glue of Omega.A.

  Responsibilities:
    - Receive agency events from Sentinel Heartbeat
    - Evaluate urgency / confidence / impact
    - Decide: delegate to Research Director, notify human, or both
    - Maintain the cognition cycle state
    - Enforce constitutional constraints (no autonomous modification)

  This is what makes Tiannara alive rather than reactive.
  """
  use GenServer
  require Logger

  alias Tiannara.Agency.Models.{AgencyEvent, CognitionCycleState}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, name: Keyword.get(opts, :name, __MODULE__))
  end

  def receive_event(%AgencyEvent{} = event) do
    GenServer.cast(__MODULE__, {:event, event})
  end

  def get_cycle_state, do: GenServer.call(__MODULE__, :cycle_state)
  def get_pending_human_decisions, do: GenServer.call(__MODULE__, :pending_decisions)
  def acknowledge_human_decision(id, decision), do: GenServer.cast(__MODULE__, {:human_decision, id, decision})

  @impl true
  def init(_) do
    {:ok, %{
      cycle_state: %CognitionCycleState{
        cycle_id: UUID.uuid4(),
        started_at: DateTime.utc_now(),
        status: :idle
      },
      event_queue: :queue.new(),
      pending_decisions: %{},
      investigation_log: [],
      human_notifications: []
    }}
  end

  @impl true
  def handle_cast({:event, event}, state) do
    Logger.debug("[Orchestrator] Received event #{event.id} (#{event.category}, priority=#{Float.round(event.priority_score, 2)})")

    new_state = %{state | event_queue: :queue.in(event, state.event_queue)}
    new_state = process_queue(new_state)

    {:noreply, new_state}
  end

  @impl true
  def handle_call(:cycle_state, _from, state) do
    {:reply, state.cycle_state, state}
  end

  @impl true
  def handle_call(:pending_decisions, _from, state) do
    {:reply, Map.values(state.pending_decisions), state}
  end

  @impl true
  def handle_cast({:human_decision, id, decision}, state) do
    case Map.get(state.pending_decisions, id) do
      nil -> {:noreply, state}
      item ->
        Logger.info("[Orchestrator] Human decision on #{id}: #{decision}")
        new_pending = Map.delete(state.pending_decisions, id)
        new_state = handle_human_decision(item, decision, state)
        {:noreply, %{new_state | pending_decisions: new_pending}}
    end
  end

  defp process_queue(state) do
    case :queue.out(state.event_queue) do
      {{:value, event}, remaining} ->
        new_state = %{state | event_queue: remaining}
        new_state = handle_event(event, new_state)
        process_queue(new_state)
      {:empty, _} ->
        state
    end
  end

  defp handle_event(event, state) do
    state = update_cycle_state(state, :observing)

    state = if event.requires_human_notification do
      notify_human(event, state)
    else
      state
    end

    state = if event.requires_investigation and can_investigate?(event) do
      state = update_cycle_state(state, :investigating)
      investigate(event, state)
    else
      state
    end

    cs = %{state.cycle_state | last_completed_at: DateTime.utc_now(), events_emitted: state.cycle_state.events_emitted + 1}
    state = %{state | cycle_state: cs}
    update_cycle_state(state, :idle)
  end

  defp can_investigate?(event) do
    event.category != :risk or event.severity != :critical or
      Tiannara.Agency.Sandbox.available?()
  end

  defp investigate(event, state) do
    case Tiannara.Agency.ResearchDirector.investigate(Tiannara.Agency.ResearchDirector, event) do
      {:ok, result} ->
        state = if result[:experiment] && result.experiment.requires_human_approval do
          queue_for_human_approval(result, state)
        else
          state
        end

        log_entry = %{
          event_id: event.id,
          timestamp: DateTime.utc_now(),
          hypothesis_count: length(result.hypotheses),
          selected: result[:selected] && result.selected.statement,
          recommendation: result[:evaluation] && result[:evaluation].recommendation,
          knowledge_id: result[:knowledge] && result[:knowledge].id
        }

        %{state |
          investigation_log: [log_entry | state.investigation_log] |> Enum.take(1000),
          cycle_state: %{state.cycle_state |
            hypotheses_generated: state.cycle_state.hypotheses_generated + length(result.hypotheses),
            experiments_run: state.cycle_state.experiments_run + 1,
            knowledge_integrated: state.cycle_state.knowledge_integrated + 1
          }
        }

      {:error, reason} ->
        Logger.warn("[Orchestrator] Investigation failed: #{inspect(reason)}")
        state
    end
  end

  defp notify_human(event, state) do
    notification = %{
      id: UUID.uuid4(),
      event_id: event.id,
      timestamp: DateTime.utc_now(),
      category: event.category,
      severity: event.severity,
      summary: event.observation_summary,
      interpretation: event.interpretation,
      confidence: event.confidence,
      recommended_action: recommend_action(event),
      status: :delivered
    }

    Tiannara.Agency.HumanInterface.deliver(notification)

    %{state |
      human_notifications: [notification | state.human_notifications] |> Enum.take(500)
    }
  end

  defp recommend_action(event) do
    case event.category do
      :risk -> "Investigate root cause; consider mitigation"
      :discovery -> "Review findings; consider integration"
      :anomaly -> "Monitor; investigate if pattern persists"
      :opportunity -> "Evaluate for potential exploitation"
      _ -> "Review and decide"
    end
  end

  defp queue_for_human_approval(result, state) do
    decision_request = %{
      id: UUID.uuid4(),
      event_id: result.event.id,
      experiment_id: result.experiment.id,
      timestamp: DateTime.utc_now(),
      hypothesis: result.selected.statement,
      experiment_type: result.experiment.experiment_type,
      risk_level: result.experiment.risk_level,
      expected_benefit: result[:evaluation] && result[:evaluation].new_confidence,
      rollback_plan: result.experiment.rollback_plan,
      status: :pending
    }

    Tiannara.Agency.HumanInterface.request_approval(decision_request)

    put_in(state, [:pending_decisions, decision_request.id], decision_request)
  end

  defp handle_human_decision(item, :approve, state) do
    Logger.info("[Orchestrator] Human approved experiment #{item.experiment_id}")
    state
  end

  defp handle_human_decision(item, :reject, state) do
    Logger.info("[Orchestrator] Human rejected experiment #{item.experiment_id}")
    Tiannara.Memory.store(:rejected_experiments, item)
    state
  end

  defp update_cycle_state(state, new_status) do
    %{state | cycle_state: %{state.cycle_state | status: new_status}}
  end
end
