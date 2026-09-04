defmodule Tiannara.Sentinel.AnomalyClassifier do
  @moduledoc """
  Anomaly Classifier — detects and classifies anomalous observations.

  Classifies anomalies by:
    - Severity: :info | :warning | :critical | :emergency
    - Type: :threshold | :trend | :sudden_change | :correlation_break
    - Domain: :memory | :process | :performance | :integrity | :security

  ## Constitutional Alignment

    - Safety: Detects uncertainty, anomalies, degraded performance.
    - Evidence Before Confidence: Classifications carry confidence scores.
    - Explainability: Every anomaly includes rationale and evidence.
    - No Silent Failures: All anomalies are reported; none are swallowed.
    - Verification First: Anomalies trigger validation before escalation.
  """

  use GenServer

  require Logger

  @type severity() :: :info | :warning | :critical | :emergency
  @type anomaly_type() :: :threshold | :trend | :sudden_change | :correlation_break
  @type domain() :: :memory | :process | :performance | :integrity | :security

  @type anomaly() :: %{
    id: binary(), severity: severity(), type: anomaly_type(), domain: domain(),
    signal: atom(), value: term(), threshold: term(), confidence: float(),
    detected_at: DateTime.t(), rationale: String.t(), evidence: [term()]
  }

  @memory_warning_bytes 1_073_741_824
  @memory_critical_bytes 4_294_967_296
  @process_warning_ratio 0.8
  @atom_warning_ratio 0.8
  @run_queue_warning 10

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec classify([map()], [map()]) :: [anomaly()]
  def classify(observations, patterns) do
    GenServer.call(__MODULE__, {:classify, observations, patterns}, 30_000)
  end

  @spec total_detected() :: non_neg_integer()
  def total_detected do
    GenServer.call(__MODULE__, :total_detected)
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @impl true
  def init(_opts) do
    {:ok, %{active_anomalies: [], total_detected: 0, history: [], last_classification_at: nil}}
  end

  @impl true
  def handle_call({:classify, observations, patterns}, _from, state) do
    anomalies = detect_anomalies(observations, patterns)

    Enum.each(anomalies, fn anomaly ->
      if anomaly.severity in [:critical, :emergency] do
        Logger.warning("[AnomalyClassifier] #{String.upcase(to_string(anomaly.severity))} anomaly detected. Domain: #{anomaly.domain} Signal: #{anomaly.signal} Rationale: #{anomaly.rationale}")
      end
    end)

    :telemetry.execute([:tiannara, :sentinel, :anomalies_detected], %{count: length(anomalies)}, %{severities: Enum.map(anomalies, & &1.severity)})

    new_state = %{state | active_anomalies: anomalies, total_detected: state.total_detected + length(anomalies), history: Enum.take([anomalies | state.history], 100), last_classification_at: DateTime.utc_now()}

    {:reply, anomalies, new_state}
  end

  @impl true
  def handle_call(:total_detected, _from, state) do
    {:reply, state.total_detected, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{active_anomalies: length(state.active_anomalies), total_detected: state.total_detected, last_classification_at: state.last_classification_at, severities: Enum.map(state.active_anomalies, & &1.severity)}, state}
  end

  defp detect_anomalies(observations, patterns) do
    []
    |> check_memory_anomalies(observations)
    |> check_process_anomalies(observations)
    |> check_performance_anomalies(observations)
    |> check_pattern_anomalies(patterns)
  end

  defp check_memory_anomalies(anomalies, observations) do
    mem_obs = observations |> Enum.filter(fn obs -> obs[:type] == :memory_pressure end) |> List.last()

    if mem_obs do
      total = mem_obs.value[:total_bytes] || 0

      cond do
        total > @memory_critical_bytes ->
          [build_anomaly(:critical, :threshold, :memory, :total_memory, total, @memory_critical_bytes, 0.95, "Total memory #{total} bytes exceeds critical threshold #{@memory_critical_bytes}.", [mem_obs]) | anomalies]
        total > @memory_warning_bytes ->
          [build_anomaly(:warning, :threshold, :memory, :total_memory, total, @memory_warning_bytes, 0.85, "Total memory #{total} bytes exceeds warning threshold #{@memory_warning_bytes}.", [mem_obs]) | anomalies]
        true -> anomalies
      end
    else
      anomalies
    end
  end

  defp check_process_anomalies(anomalies, observations) do
    vm_obs = observations |> Enum.filter(fn obs -> obs[:type] == :vm_health end) |> List.last()

    if vm_obs do
      process_count = vm_obs.value[:process_count] || 0
      process_limit = vm_obs.value[:process_limit] || 262_144
      ratio = process_count / process_limit

      atom_count = vm_obs.value[:atom_count] || 0
      atom_limit = vm_obs.value[:atom_limit] || 1_048_576
      atom_ratio = atom_count / atom_limit

      anomalies = if ratio > @process_warning_ratio do
        [build_anomaly(:warning, :threshold, :process, :process_count, ratio, @process_warning_ratio, 0.9, "Process table at #{Float.round(ratio * 100, 1)}% capacity.", [vm_obs]) | anomalies]
      else
        anomalies
      end

      if atom_ratio > @atom_warning_ratio do
        [build_anomaly(:critical, :threshold, :process, :atom_count, atom_ratio, @atom_warning_ratio, 0.95, "Atom table at #{Float.round(atom_ratio * 100, 1)}% capacity. Risk of exhaustion.", [vm_obs]) | anomalies]
      else
        anomalies
      end
    else
      anomalies
    end
  end

  defp check_performance_anomalies(anomalies, observations) do
    vm_obs = observations |> Enum.filter(fn obs -> obs[:type] == :vm_health end) |> List.last()

    if vm_obs do
      run_queue = vm_obs.value[:run_queue] || 0

      if run_queue > @run_queue_warning do
        [build_anomaly(:warning, :sudden_change, :performance, :run_queue, run_queue, @run_queue_warning, 0.8, "BEAM run queue at #{run_queue} (threshold: #{@run_queue_warning}). Scheduler saturation likely.", [vm_obs]) | anomalies]
      else
        anomalies
      end
    else
      anomalies
    end
  end

  defp check_pattern_anomalies(anomalies, patterns) do
    trend_anomalies = patterns
    |> Enum.filter(fn p -> p.type == :trend and p.direction == :increasing and p.confidence > 0.8 end)
    |> Enum.map(fn p ->
      build_anomaly(:warning, :trend, :performance, p.signal, p.magnitude, nil, p.confidence, "Increasing trend detected: #{p.rationale}", [p])
    end)

    trend_anomalies ++ anomalies
  end

  defp build_anomaly(severity, type, domain, signal, value, threshold, confidence, rationale, evidence) do
    %{id: Tiannara.Executive.Types.new_id(), severity: severity, type: type, domain: domain, signal: signal, value: value, threshold: threshold, confidence: confidence, detected_at: DateTime.utc_now(), rationale: rationale, evidence: evidence}
  end
end
