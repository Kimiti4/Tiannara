defmodule Tiannara.Sentinel.Activation.Engine do
  @moduledoc """
  The main GenServer orchestrating the Sentinel Activation Loop:

    Observe → Interpret → Prioritize → Recommend → Validate → Communicate → Learn

  Now connected to the Research Director pipeline:

    High-importance events → Hypothesis generation → Experiment → Sandbox → Result

  This is the central coordinator that ties together all activation components:
  Event system, Intelligence scoring, Causal analysis, Recommendation generation,
  CRAV triggering, Dialogue, Approval gateway, Memory integration, and Research.
  """
  use GenServer
  require Logger

  alias Tiannara.Sentinel.Activation.{
    Event, Intelligence, Causal, Recommendation,
    Dialogue, CRAVController, Approval, Memory
  }

  alias Tiannara.Research.Director, as: ResearchDirector

  # ── Public API ──

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Ingests a raw observation into the activation pipeline.
  The observation is converted to an Event, processed through
  the full activation loop, and the result is returned.
  """
  def observe(raw_observation) when is_map(raw_observation) do
    GenServer.cast(__MODULE__, {:observe, raw_observation})
  end

  @doc """
  Records the outcome of an intervention for learning.
  """
  def record_outcome(event_id, outcome_data, result) do
    GenServer.cast(__MODULE__, {:record_outcome, event_id, outcome_data, result})
  end

  @doc """
  Returns the current engine status.
  """
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @doc """
  Processes an observation synchronously and returns the full activation result.
  Useful for testing and direct invocation from other subsystems.
  """
  def process(raw_observation) when is_map(raw_observation) do
    event = Event.new(raw_observation)
    interpreted = Causal.interpret(event)
    %{event: scored, importance: importance, priority: priority} = Intelligence.evaluate(interpreted)

    if priority != :ignore do
      recommendations = Recommendation.generate(scored)
      triggered = CRAVController.maybe_trigger(scored)

      if scored.requires_human or priority == :high do
        Dialogue.initiate(scored, recommendations)
      end

      best_rec = Enum.max_by(recommendations, & &1.expected_gain, fn -> nil end)
      proposal = if best_rec, do: Approval.propose(scored, best_rec), else: nil

      # Trigger Research Director investigation for meaningful events
      if priority in [:high, :medium] and importance >= 0.3 do
        spawn(fn ->
          ResearchDirector.investigate_event(
            scored.id, scored.category, scored.observation,
            evidence: [scored.interpretation],
            confidence: scored.confidence
          )
        end)
      end

      # Trigger Cognitive Layer for high-priority events — full scientific reasoning
      if priority == :high and importance >= 0.5 do
        spawn(fn ->
          Tiannara.Sentinel.Cognition.Orchestrator.investigate(scored)
        end)
      end

      %{
        event: scored,
        importance: importance,
        priority: priority,
        recommendations: recommendations,
        crav_triggered: triggered,
        proposal: proposal
      }
    else
      %{
        event: scored,
        importance: 0.0,
        priority: :ignore,
        recommendations: [],
        crav_triggered: :ok,
        proposal: nil
      }
    end
  end

  # ── GenServer Callbacks ──

  @impl true
  def init(_opts) do
    Logger.info("[ACTIVATION] Sentinel Activation Engine started.")
    {:ok, %{events_processed: 0, events_ignored: 0, research_triggered: 0}}
  end

  @impl true
  def handle_cast({:observe, raw_obs}, state) do
    result = process(raw_obs)

    new_state = if result.priority == :ignore do
      %{state | events_ignored: state.events_ignored + 1}
    else
      %{state | events_processed: state.events_processed + 1,
               research_triggered: state.research_triggered + 1}
    end

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:record_outcome, event_id, outcome_data, result}, state) do
    # Construct a minimal event for memory recording
    event = %Event{
      id: event_id,
      timestamp: DateTime.utc_now(),
      source: outcome_data[:source] || :unknown,
      category: outcome_data[:category] || :scientific,
      severity: outcome_data[:severity] || :info,
      observation: outcome_data[:observation] || "",
      interpretation: outcome_data[:interpretation] || outcome_data[:action],
      confidence: outcome_data[:confidence] || 0.5
    }
    Memory.record_outcome(event, outcome_data, result)
    {:noreply, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, state, state}
  end
end
