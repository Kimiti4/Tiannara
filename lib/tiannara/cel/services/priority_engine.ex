defmodule Tiannara.CEL.Services.PriorityEngine do
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.CEL.Models.CivilizationalEvent
  alias Tiannara.CEL.Services.Priority.{OutcomeSignal, LearningModel}
  alias Tiannara.CEL.Services.{EventBus, ExecutiveMemory}
  alias Tiannara.CEL.Services.PriorityReport
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  @learning_interval 10
  @calibration_window 50
  @drift_threshold 0.6
  @update_interval_ms 60_000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def calculate_priority(%CivilizationalEvent{} = event) do
    GenServer.call(__MODULE__, {:calculate_priority, event})
  end

  def compare(a, b), do: calculate_priority(a) >= calculate_priority(b)

  def sort(events), do: Enum.sort_by(events, &calculate_priority/1, :desc)

  def feed_signal(%OutcomeSignal{} = signal) do
    GenServer.cast(__MODULE__, {:feed_signal, signal})
  end

  def get_report do
    GenServer.call(__MODULE__, :get_report)
  end

  def get_weights do
    GenServer.call(__MODULE__, :get_weights)
  end

  def record_outcome(workflow, outcome) do
    signal = OutcomeSignal.from_workflow_telemetry(workflow, outcome)
    feed_signal(signal)
  end

  @impl true
  def id, do: :priority_engine

  @impl true
  def version, do: "2.1.0"

  @impl true
  def capabilities do
    [:adaptive_prioritization, :evidence_driven_learning, :calibration,
     :drift_detection, :explainable_priority, :global_prioritization,
     :evidence_weighting, :mission_alignment, :adaptive_learning,
     :uncertainty_quantification]
  end

  @impl true
  def health do
    if Process.whereis(__MODULE__), do: :healthy, else: :unhealthy
  end

  @impl true
  def constitutional_score do
    report =
      if Process.whereis(__MODULE__),
        do: GenServer.call(__MODULE__, :get_report),
        else: nil

    calibration = (report && report.calibration) || 0.5
    evidence_n = (report && report.evidence_count) || 0
    drift = (report && report.drift_detected) || false

    %ConstitutionalScore{
      service_id: id(),
      health: if(drift, do: 0.6, else: 1.0),
      constitutional_alignment: calibration,
      transparency: 1.0,
      explainability: 0.9,
      evidence_quality: min(1.0, evidence_n / 100),
      human_oversight: 0.6,
      computed_at: DateTime.utc_now()
    }
  end

  @impl true
  def init(_opts) do
    send(self(), :subscribe_to_events)
    send(self(), :schedule_update)
    Process.send_after(self(), :update_model, @update_interval_ms)

    {:ok, %{
      weights: LearningModel.init_weights(),
      signal_buffer: [],
      calibration_buffer: [],
      total_signals: 0,
      drift_detected: false,
      last_update: DateTime.utc_now(),
      last_report: nil,
      healthy: true
    }}
  end

  @impl true
  def handle_call({:calculate_priority, %CivilizationalEvent{} = event}, _from, state) do
    prio = score_with_model(state.weights, event)
    {:reply, prio, state}
  end

  @impl true
  def handle_call(:get_report, _from, state) do
    report = build_report(state)
    {:reply, report, state}
  end

  @impl true
  def handle_call(:get_weights, _from, state) do
    {:reply, state.weights, state}
  end

  @impl true
  def handle_cast({:feed_signal, signal}, state) do
    buffer = [signal | state.signal_buffer]
    total = state.total_signals + 1
    state = %{state | signal_buffer: buffer, total_signals: total}

    if rem(total, @learning_interval) == 0 do
      {:noreply, do_learn(state)}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info(:schedule_update, state) do
    Process.send_after(self(), :update_model, @update_interval_ms)
    {:noreply, state}
  end

  @impl true
  def handle_info(:update_model, state) do
    {:noreply, do_learn(state)}
  end

  @impl true
  def handle_info(:subscribe_to_events, state) do
    case Process.whereis(Tiannara.CEL.Services.EventBus) do
      nil ->
        Logger.debug("PriorityEngine: EventBus not available, retrying subscription in 500ms")
        Process.send_after(self(), :subscribe_to_events, 500)
        {:noreply, state}

      _pid ->
        try do
          EventBus.subscribe("workflow.completed", self())
          EventBus.subscribe("workflow.step.completed", self())
          EventBus.subscribe("workflow.failed", self())
          Logger.info("PriorityEngine: subscribed to EventBus workflow topics")
          {:noreply, state}
        rescue
          e ->
            Logger.warning("PriorityEngine: subscription failed (#{inspect(e)}), retrying in 2s")
            Process.send_after(self(), :subscribe_to_events, 2_000)
            {:noreply, state}
        end
    end
  end

  @impl true
  def handle_info({:event, event}, state) do
    payload = Map.get(event, :raw_payload, %{})
    outcome = if event.type == "workflow.failed", do: :failure, else: :success

    signal = %OutcomeSignal{
      workflow_id: payload[:workflow_id],
      outcome: outcome,
      completed_at: DateTime.utc_now(),
      feature_vector: [0.5, 0.5, 0.5, if(outcome == :success, do: 1.0, else: 0.0), 0.5],
      target_score: if(outcome == :success, do: 0.8, else: 0.2)
    }

    buffer = [signal | state.signal_buffer]
    total = state.total_signals + 1
    {:noreply, %{state | signal_buffer: buffer, total_signals: total}}
  end

  defp do_learn(state) do
    case state.signal_buffer do
      [] -> state
      signals ->
        weights =
          Enum.reduce(signals, state.weights, fn signal, w ->
            fv = LearningModel.extract_features(signal)
            LearningModel.update_weights(w, fv, signal.target_score)
          end)

        calib =
          (state.calibration_buffer ++
             Enum.map(signals, fn s ->
               {LearningModel.extract_features(s), s.target_score}
             end))
          |> Enum.take(-@calibration_window)

        drift = LearningModel.calibration_score(weights, calib) < @drift_threshold

        if drift and not state.drift_detected do
          Logger.warning("PriorityEngine: Drift detected! Calibration below #{@drift_threshold}")
          emit_constitutional_event(:priority_engine_drift,
            %{calibration: LearningModel.calibration_score(weights, calib)})
        end

        record_learning_event(weights, length(signals))

        %{state |
          weights: weights,
          signal_buffer: [],
          calibration_buffer: calib,
          drift_detected: drift,
          last_update: DateTime.utc_now()
        }
    end
  end

  defp score_with_model(weights, %CivilizationalEvent{} = event) do
    fv = event_to_features(event)
    {pred, _lo, _hi} = LearningModel.predict_with_uncertainty(weights, fv)
    max(0.0, min(1.0, pred))
  rescue
    _ -> legacy_heuristic(event)
  end

  defp event_to_features(event) do
    c = Map.get(event, :confidence, 0.5)
    ev = Map.get(event, :evidence, 0.5)
    impact = Map.get(event, :impact, 0.5)
    urgency = urgency_multiplier(Map.get(event, :urgency, :medium))
    aligned = 1.0

    [c, ev, impact, urgency / 2.0, aligned / 1.2]
  end

  defp legacy_heuristic(event) do
    impact = Map.get(event, :impact, 0.5)
    evidence = Map.get(event, :evidence, 0.5)
    confidence = Map.get(event, :confidence, 0.5)
    urgency = urgency_multiplier(event.urgency)
    alignment = mission_alignment(event.mission_id)
    risk_penalty = Map.get(event, :risk, 0.0) * 0.5
    cost_penalty = Map.get(event, :resource_cost, 0.0) * 0.001
    raw = (impact * evidence * confidence * urgency * alignment) - risk_penalty - cost_penalty
    max(0.0, min(1.0, raw))
  end

  defp build_report(state) do
    cal = LearningModel.calibration_score(state.weights, state.calibration_buffer)
    {prio, lo, hi} = LearningModel.predict_with_uncertainty(state.weights, [0.5, 0.5, 0.5, 0.5, 0.5])

    %PriorityReport{
      service_id: :priority_engine,
      prio: prio,
      confidence_interval: {lo, hi},
      feature_breakdown: %{
        confidence: 0.5,
        evidence: 0.5,
        efficiency: 0.5,
        outcome_history: 0.5,
        diversity: 0.5
      },
      prediction_interval: {lo, hi},
      evidence_count: length(state.calibration_buffer),
      signals_in_window: state.total_signals,
      calibration: cal,
      drift_detected: state.drift_detected,
      recommendation: if(state.drift_detected, do: :recalibrate, else: :continue),
      computed_at: DateTime.utc_now()
    }
  end

  defp record_learning_event(weights, batch_size) do
    try do
      ExecutiveMemory.record_event(:priority_engine, :model_update, %{
        n: weights.n, batch_size: batch_size,
        mean_weights: weights.mean
      })
    rescue
      _ -> :ok
    end
  end

  defp urgency_multiplier(:critical), do: 2.0
  defp urgency_multiplier(:high), do: 1.5
  defp urgency_multiplier(:medium), do: 1.0
  defp urgency_multiplier(:low), do: 0.5
  defp urgency_multiplier(_), do: 0.8

  defp mission_alignment(nil), do: 1.0
  defp mission_alignment(_mission_id), do: 1.2
end
