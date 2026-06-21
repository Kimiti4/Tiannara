defmodule Tiannara.Topology.ACF.ViolationDetector do
  @moduledoc """
  Violation Detector for ACF.

  Detects, analyzes, and reports conservation law violations across the system.
  """

  use GenServer
  require Logger

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def scan_for_violations(system_state) do
    GenServer.call(__MODULE__, {:scan_for_violations, system_state})
  end

  def analyze_violation(violation_data) do
    GenServer.call(__MODULE__, {:analyze_violation, violation_data})
  end

  def get_violation_history() do
    GenServer.call(__MODULE__, :get_violation_history)
  end

  def get_violation_statistics() do
    GenServer.call(__MODULE__, :get_violation_statistics)
  end

  def set_violation_threshold(threshold) do
    GenServer.call(__MODULE__, {:set_violation_threshold, threshold})
  end

  def get_violation_threshold() do
    GenServer.call(__MODULE__, :get_violation_threshold)
  end

  def classify_violation_severity(violation_data) do
    GenServer.call(__MODULE__, {:classify_violation_severity, violation_data})
  end

  def generate_violation_report() do
    GenServer.call(__MODULE__, :generate_violation_report)
  end

  def prioritize_violations(violations) do
    GenServer.call(__MODULE__, {:prioritize_violations, violations})
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    # Create ETS table for violation records
    :ets.new(:violation_records, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    # Create ETS table for violation patterns
    :ets.new(:violation_patterns, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    # Create ETS table for violation thresholds
    :ets.new(:violation_thresholds, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    # Initialize violation thresholds
    :ets.insert(:violation_thresholds, {
      :critical, 0.95,  # Critical threshold
      :high, 0.85,     # High threshold
      :medium, 0.75,   # Medium threshold
      :low, 0.65       # Low threshold
    })

    # Initialize violation statistics
    :ets.insert(:violation_records, {
      System.system_time(:millisecond),
      :initialized,
      0,
      %{}
    })

    Logger.info("Violation Detector initialized")

    # Start periodic violation scanning
    schedule_violation_scan()

    {:ok, %{
      total_violations: 0,
      critical_violations: 0,
      high_violations: 0,
      medium_violations: 0,
      low_violations: 0,
      last_scan: 0
    }}
  end

  @impl true
  def handle_call({:scan_for_violations, system_state}, _from, state) when is_map(system_state) do
    # Scan for violations in system state
    violations = detect_violations(system_state)
    
    # Record violations
    Enum.each(violations, fn violation ->
      record_violation(violation)
    end)
    
    # Update statistics
    updated_state = update_violation_statistics(state, violations)
    
    Logger.info("Scanned for violations: found #{length(violations)} violations")
    
    {:reply, {:ok, violations}, updated_state}
  end

  @impl true
  def handle_call({:analyze_violation, violation_data}, _from, state) when is_map(violation_data) do
    # Analyze violation data
    analysis = analyze_violation_data(violation_data)
    
    # Record analysis
    record_violation_analysis(violation_data, analysis)
    
    Logger.info("Analyzed violation: #{violation_data.type}")
    
    {:reply, {:ok, analysis}, state}
  end

  @impl true
  def handle_call(:get_violation_history, _from, state) do
    history = :ets.tab2list(:violation_records)
    |> Enum.map(fn record ->
      %{
        timestamp: record.timestamp,
        violation_type: record.violation_type,
        severity: record.severity,
        description: record.description,
        system_state: record.system_state,
        resolution_status: record.resolution_status
      }
    end)
    
    {:reply, {:ok, history}, state}
  end

  @impl true
  def handle_call(:get_violation_statistics, _from, state) do
    stats = calculate_violation_statistics()
    
    {:reply, {:ok, stats}, state}
  end

  @impl true
  def handle_call({:set_violation_threshold, threshold}, _from, state) when is_number(threshold) and threshold >= 0 and threshold <= 1 do
    # Update violation threshold
    :ets.insert(:violation_thresholds, {:critical, threshold})
    
    Logger.info("Updated critical violation threshold to #{threshold}")
    
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:get_violation_threshold, _from, state) do
    case :ets.lookup(:violation_thresholds, :critical) do
      [{:critical, threshold}] ->
        {:reply, {:ok, threshold}, state}
      [] ->
        {:reply, {:error, :threshold_not_found}, state}
    end
  end

  @impl true
  def handle_call({:classify_violation_severity, violation_data}, _from, state) when is_map(violation_data) do
    # Classify violation severity
    severity = classify_severity(violation_data)
    
    {:reply, {:ok, severity}, state}
  end

  @impl true
  def handle_call(:generate_violation_report, _from, state) do
    # Generate comprehensive violation report
    report = generate_report()
    
    Logger.info("Generated violation report")
    
    {:reply, {:ok, report}, state}
  end

  @impl true
  def handle_call({:prioritize_violations, violations}, _from, state) when is_list(violations) do
    # Prioritize violations by severity and impact
    prioritized_violations = prioritize_violations_list(violations)
    
    {:reply, {:ok, prioritized_violations}, state}
  end

  # Periodic violation scanning
  @impl true
  def handle_info(:violation_scan, state) do
    Logger.info("Running periodic violation scan")
    
    # Mock system state
    mock_system_state = %{
      timestamp: System.system_time(:millisecond),
      components: []
    }
    
    # Scan for violations
    violations = detect_violations(mock_system_state)
    
    # Record violations
    Enum.each(violations, fn violation ->
      record_violation(violation)
    end)
    
    # Update statistics
    updated_state = update_violation_statistics(state, violations)
    
    # Schedule next scan
    schedule_violation_scan()
    
    {:noreply, updated_state}
  end

  # Helper functions
  defp schedule_violation_scan() do
    # Schedule violation scan every 30 seconds
    Process.send_after(self(), :violation_scan, 30_000)
  end

  defp detect_violations(system_state) when is_map(system_state) do
    check_information_violations(system_state) ++
    check_energy_violations(system_state) ++
    check_momentum_violations(system_state) ++
    check_causal_violations(system_state) ++
    check_semantic_violations(system_state) ++
    check_computational_violations(system_state)
  end

  defp check_information_violations(system_state) when is_map(system_state) do
    # Check information conservation violations
    case system_state do
      %{information: info} ->
        initial = info.initial || 0
        current = info.current || 0
        delta = current - initial
        
        if abs(delta) > 0.01 do
          [%{
            type: :information_conservation,
            severity: :high,
            description: "Information conservation violated: ΔI = #{delta}",
            details: %{initial: initial, current: current, delta: delta},
            timestamp: System.system_time(:millisecond),
            system_state: system_state,
            resolution_status: :unresolved
          }]
        else
          []
        end
      _ ->
        []
    end
  end

  defp check_energy_violations(system_state) when is_map(system_state) do
    # Check energy conservation violations
    case system_state do
      %{energy: energy} ->
        initial = energy.initial || 0
        current = energy.current || 0
        delta = current - initial
        
        if abs(delta) > 0.01 do
          [%{
            type: :energy_conservation,
            severity: :critical,
            description: "Energy conservation violated: ΔE = #{delta}",
            details: %{initial: initial, current: current, delta: delta},
            timestamp: System.system_time(:millisecond),
            system_state: system_state,
            resolution_status: :unresolved
          }]
        else
          []
        end
      _ ->
        []
    end
  end

  defp check_momentum_violations(system_state) when is_map(system_state) do
    # Check momentum conservation violations
    case system_state do
      %{momentum: momentum} ->
        initial = momentum.initial || 0
        current = momentum.current || 0
        delta = current - initial
        
        if abs(delta) > 0.01 do
          [%{
            type: :momentum_conservation,
            severity: :high,
            description: "Momentum conservation violated: Δp = #{delta}",
            details: %{initial: initial, current: current, delta: delta},
            timestamp: System.system_time(:millisecond),
            system_state: system_state,
            resolution_status: :unresolved
          }]
        else
          []
        end
      _ ->
        []
    end
  end

  defp check_causal_violations(system_state) when is_map(system_state) do
    # Check causal closure violations
    case system_state do
      %{causal: causal} ->
        integral = causal.integral || 0
        
        if integral < 0 do
          [%{
            type: :causal_closure,
            severity: :critical,
            description: "Causal closure violated: ∮C(t)dt = #{integral}",
            details: %{integral: integral},
            timestamp: System.system_time(:millisecond),
            system_state: system_state,
            resolution_status: :unresolved
          }]
        else
          []
        end
      _ ->
        []
    end
  end

  defp check_semantic_violations(system_state) when is_map(system_state) do
    # Check semantic invertibility violations
    case system_state do
      %{semantic: semantic} ->
        original = semantic.original || 0
        inverted = semantic.inverted || 0
        
        if abs(inverted - original) > 0.01 do
          [%{
            type: :semantic_invertibility,
            severity: :medium,
            description: "Semantic invertibility violated: f⁻¹(f(Ω)) = #{inverted} ≠ #{original}",
            details: %{original: original, inverted: inverted},
            timestamp: System.system_time(:millisecond),
            system_state: system_state,
            resolution_status: :unresolved
          }]
        else
          []
        end
      _ ->
        []
    end
  end

  defp check_computational_violations(system_state) when is_map(system_state) do
    # Check computational boundedness violations
    case system_state do
      %{computational: computational} ->
        complexity = computational.complexity || 0
        bound = computational.bound || 100
        
        if complexity > bound do
          [%{
            type: :computational_boundedness,
            severity: :high,
            description: "Computational boundedness violated: K(P) = #{complexity} > #{bound}",
            details: %{complexity: complexity, bound: bound},
            timestamp: System.system_time(:millisecond),
            system_state: system_state,
            resolution_status: :unresolved
          }]
        else
          []
        end
      _ ->
        []
    end
  end

  defp record_violation(violation) when is_map(violation) do
    # Record violation
    record = {
      violation.timestamp,
      violation.type,
      violation.severity,
      violation.description,
      violation.details,
      violation.system_state,
      violation.resolution_status
    }
    
    :ets.insert(:violation_records, {record})
  end

  defp analyze_violation_data(violation_data) when is_map(violation_data) do
    # Analyze violation data
    analysis = %{
      violation_type: violation_data.type,
      severity: violation_data.severity,
      impact_score: calculate_impact_score(violation_data),
      root_cause: identify_root_cause(violation_data),
      repair_probability: estimate_repair_probability(violation_data),
      recommended_action: recommend_action(violation_data),
      analysis_timestamp: System.system_time(:millisecond)
    }
    
    analysis
  end

  defp calculate_impact_score(violation_data) when is_map(violation_data) do
    # Calculate impact score based on violation type and severity
    case violation_data.type do
      :energy_conservation -> 0.95 * severity_multiplier(violation_data.severity)
      :causal_closure -> 0.90 * severity_multiplier(violation_data.severity)
      :information_conservation -> 0.85 * severity_multiplier(violation_data.severity)
      :momentum_conservation -> 0.80 * severity_multiplier(violation_data.severity)
      :semantic_invertibility -> 0.70 * severity_multiplier(violation_data.severity)
      :computational_boundedness -> 0.65 * severity_multiplier(violation_data.severity)
      _ -> 0.50
    end
  end

  defp severity_multiplier(severity) do
    case severity do
      :critical -> 1.0
      :high -> 0.8
      :medium -> 0.6
      :low -> 0.4
      _ -> 0.5
    end
  end

  defp identify_root_cause(violation_data) when is_map(violation_data) do
    # Identify root cause of violation
    case violation_data.type do
      :energy_conservation -> "Energy source imbalance or computational error"
      :causal_closure -> "Incomplete causal chain or external intervention"
      :information_conservation -> "Information leak or processing error"
      :momentum_conservation -> "External force or boundary condition violation"
      :semantic_invertibility -> "Semantic transformation error"
      :computational_boundedness -> "Algorithm complexity exceeded"
      _ -> "Unknown or system-wide issue"
    end
  end

  defp estimate_repair_probability(violation_data) when is_map(violation_data) do
    # Estimate probability of successful repair
    case violation_data.severity do
      :low -> 0.95
      :medium -> 0.85
      :high -> 0.75
      :critical -> 0.60
      _ -> 0.50
    end
  end

  defp recommend_action(violation_data) when is_map(violation_data) do
    # Recommend action based on violation type and severity
    case violation_data.severity do
      :critical ->
        "IMMEDIATE intervention required - system integrity at risk"
      :high ->
        "High priority intervention required within time window"
      :medium ->
        "Standard intervention procedure applicable"
      :low ->
        "Monitoring and potential automated repair"
      _ ->
        "Review and assess"
    end
  end

  defp record_violation_analysis(violation_data, analysis) when is_map(violation_data) and is_map(analysis) do
    # Record violation analysis
    analysis_record = {
      analysis.analysis_timestamp,
      violation_data.type,
      violation_data.severity,
      analysis.impact_score,
      analysis.root_cause,
      analysis.repair_probability,
      analysis.recommended_action
    }
    
    :ets.insert(:violation_patterns, {analysis_record})
  end

  defp update_violation_statistics(state, violations) when is_list(violations) do
    # Update violation statistics
    Enum.reduce(violations, state, fn violation, acc ->
      case violation.severity do
        :critical -> %{acc | critical_violations: acc.critical_violations + 1, total_violations: acc.total_violations + 1}
        :high -> %{acc | high_violations: acc.high_violations + 1, total_violations: acc.total_violations + 1}
        :medium -> %{acc | medium_violations: acc.medium_violations + 1, total_violations: acc.total_violations + 1}
        :low -> %{acc | low_violations: acc.low_violations + 1, total_violations: acc.total_violations + 1}
        _ -> acc
      end
    end)
  end

  defp calculate_violation_statistics() do
    violations = :ets.tab2list(:violation_records)
    
    statistics = %{
      total_violations: length(violations),
      critical_violations: Enum.count(violations, fn v -> v.severity == :critical end),
      high_violations: Enum.count(violations, fn v -> v.severity == :high end),
      medium_violations: Enum.count(violations, fn v -> v.severity == :medium end),
      low_violations: Enum.count(violations, fn v -> v.severity == :low end),
      unresolved_violations: Enum.count(violations, fn v -> v.resolution_status == :unresolved end),
      resolved_violations: Enum.count(violations, fn v -> v.resolution_status == :resolved end),
      violations_by_type: group_violations_by_type(violations),
      average_severity: calculate_average_severity(violations),
      recent_violations: get_recent_violations(violations, 10)
    }
    
    statistics
  end

  defp group_violations_by_type(violations) when is_list(violations) do
    violations
    |> Enum.group_by(fn v -> v.type end)
    |> Enum.map(fn {type, viol_list} -> {type, length(viol_list)} end)
    |> Map.new()
  end

  defp calculate_average_severity(violations) when is_list(violations) do
    case length(violations) do
      0 -> 0.0
      n ->
        severity_values = Enum.map(violations, fn v ->
          case v.severity do
            :critical -> 4.0
            :high -> 3.0
            :medium -> 2.0
            :low -> 1.0
            _ -> 0.0
          end
        end)
        
        Enum.sum(severity_values) / n
    end
  end

  defp get_recent_violations(violations, count) when is_list(violations) do
    violations
    |> Enum.sort_by(fn v -> v.timestamp end, :desc)
    |> Enum.take(count)
  end

  defp classify_severity(violation_data) when is_map(violation_data) do
    # Classify violation severity based on type and impact
    case violation_data.type do
      :energy_conservation -> :critical
      :causal_closure -> :critical
      :information_conservation -> :high
      :momentum_conservation -> :high
      :semantic_invertibility -> :medium
      :computational_boundedness -> :high
      _ -> :medium
    end
  end

  defp generate_report() do
    # Generate comprehensive violation report
    stats = calculate_violation_statistics()
    
    report = %{
      timestamp: System.system_time(:millisecond),
      summary: stats,
      critical_violations: get_violations_by_severity(:critical),
      high_violations: get_violations_by_severity(:high),
      medium_violations: get_violations_by_severity(:medium),
      low_violations: get_violations_by_severity(:low),
      recommendations: generate_recommendations(stats),
      next_steps: suggest_next_steps(stats)
    }
    
    report
  end

  defp get_violations_by_severity(severity) do
    :ets.tab2list(:violation_records)
    |> Enum.filter(fn v -> v.severity == severity end)
    |> Enum.map(fn v -> %{
        type: v.type,
        description: v.description,
        timestamp: v.timestamp,
        resolution_status: v.resolution_status
      }
    end)
  end

  defp generate_recommendations(stats) do
    critical_recs =
      if stats.critical_violations > 0,
        do: ["Address critical violations immediately - system integrity at risk"],
        else: []

    unresolved_recs =
      if stats.unresolved_violations > 10,
        do: ["High number of unresolved violations - prioritize resolution"],
        else: []

    severity_recs =
      if stats.average_severity > 2.5,
        do: ["High average severity - consider strengthening enforcement"],
        else: []

    recs = critical_recs ++ unresolved_recs ++ severity_recs

    if recs == [] do
      ["System violation monitoring is within acceptable parameters"]
    else
      recs
    end
  end

  defp suggest_next_steps(stats) do
    critical_steps =
      if stats.critical_violations > 0,
        do: ["Implement emergency repair procedures for critical violations"],
        else: ["Continue monitoring system integrity"]

    unresolved_steps =
      if stats.unresolved_violations > 5,
        do: ["Prioritize resolution of unresolved violations"],
        else: []

    critical_steps ++ unresolved_steps
  end

  defp prioritize_violations_list(violations) when is_list(violations) do
    # Prioritize violations by severity and impact
    sorted_violations = Enum.sort(violations, fn a, b ->
      # Sort by severity first, then by timestamp (newer violations first)
      severity_order = %{
        :critical => 4,
        :high => 3,
        :medium => 2,
        :low => 1
      }
      
      a_severity = Map.get(severity_order, a.severity, 0)
      b_severity = Map.get(severity_order, b.severity, 0)
      
      if a_severity != b_severity do
        a_severity > b_severity
      else
        a.timestamp > b.timestamp
      end
    end)
    
    # Assign priority levels
    Enum.with_index(sorted_violations, 1)
    |> Enum.map(fn {violation, index} ->
      %{violation | priority: index}
    end)
  end
end
