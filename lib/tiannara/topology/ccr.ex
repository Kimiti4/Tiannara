defmodule Tiannara.Topology.CCR do
  @moduledoc """
  Cosmological Compiler Reflection (CCR).

  Reflects on cosmological compilation, manages compiler state, and provides meta-compilation services.
  """

  use GenServer
  require Logger

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def reflect_on_compilation(compilation_data) do
    GenServer.call(__MODULE__, {:reflect_on_compilation, compilation_data})
  end

  def get_compiler_state() do
    GenServer.call(__MODULE__, :get_compiler_state)
  end

  def analyze_compiler_performance() do
    GenServer.call(__MODULE__, :analyze_compiler_performance)
  end

  def optimize_compiler_strategies() do
    GenServer.call(__MODULE__, :optimize_compiler_strategies)
  end

  def detect_compilation_anomalies() do
    GenServer.call(__MODULE__, :detect_compilation_anomalies)
  end

  def get_compilation_history() do
    GenServer.call(__MODULE__, :get_compilation_history)
  end

  def set_compilation_strategy(strategy) do
    GenServer.call(__MODULE__, {:set_compilation_strategy, strategy})
  end

  def get_compilation_strategy() do
    GenServer.call(__MODULE__, :get_compilation_strategy)
  end

  def validate_compiler_integrity() do
    GenServer.call(__MODULE__, :validate_compiler_integrity)
  end

  def get_meta_compilation_metrics() do
    GenServer.call(__MODULE__, :get_meta_compilation_metrics)
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    reset_named_table(:compilation_history, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    reset_named_table(:compiler_strategies, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    reset_named_table(:compilation_metrics, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    reset_named_table(:compilation_anomalies, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    reset_named_table(:compiler_state, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    # Initialize default compiler state
    default_state = %{
      compilation_count: 0,
      total_time: 0,
      average_time: 0,
      success_rate: 1.0,
      current_strategy: :adaptive,
      last_compilation: 0,
      optimization_score: 1.0,
      convergence_status: :stable
    }

    :ets.insert(:compiler_state, {default_state})

    # Initialize default strategies
    default_strategies = %{
      :aggressive => %{
        priority: :performance,
        resource_allocation: :high,
        risk_tolerance: :high,
        optimization_level: :minimal
      },
      :adaptive => %{
        priority: :balance,
        resource_allocation: :medium,
        risk_tolerance: :medium,
        optimization_level: :moderate
      },
      :conservative => %{
        priority: :safety,
        resource_allocation: :low,
        risk_tolerance: :low,
        optimization_level: :maximum
      }
    }

    Enum.each(default_strategies, fn {strategy_name, strategy_data} ->
      :ets.insert(:compiler_strategies, {strategy_name, strategy_data})
    end)

    Logger.info("Cosmological Compiler Reflection initialized")

    # Start periodic analysis
    schedule_compilation_analysis()

    {:ok, %{}}
  end

  defp reset_named_table(name, options) do
    case :ets.whereis(name) do
      :undefined ->
        :ets.new(name, options)

      _tid ->
        :ets.delete(name)
        :ets.new(name, options)
    end
  end

  @impl true
  def handle_call({:reflect_on_compilation, compilation_data}, _from, state) when is_map(compilation_data) do
    # Reflect on compilation data
    reflection_result = reflect_on_compilation_data(compilation_data)
    
    # Record compilation in history
    record_compilation(compilation_data, reflection_result)
    
    # Update compiler state
    update_compiler_state(compilation_data, reflection_result)
    
    Logger.info("Completed compilation reflection for #{compilation_data.compilation_id}")
    
    {:reply, {:ok, reflection_result}, state}
  end

  @impl true
  def handle_call(:get_compiler_state, _from, state) do
    case :ets.lookup(:compiler_state, :state) do
      [{:state, compiler_state}] ->
        {:reply, {:ok, compiler_state}, state}
      [] ->
        {:reply, {:error, :compiler_state_not_found}, state}
    end
  end

  @impl true
  def handle_call(:analyze_compiler_performance, _from, state) do
    # Analyze compiler performance
    performance_analysis = analyze_compilation_performance()
    
    Logger.info("Completed compiler performance analysis")
    
    {:reply, {:ok, performance_analysis}, state}
  end

  @impl true
  def handle_call(:optimize_compiler_strategies, _from, state) do
    # Optimize compiler strategies
    optimization_result = optimize_compilation_strategies()
    
    # Record optimization
    record_compilation_optimization(optimization_result)
    
    Logger.info("Completed compiler strategy optimization")
    
    {:reply, {:ok, optimization_result}, state}
  end

  @impl true
  def handle_call(:detect_compilation_anomalies, _from, state) do
    # Detect compilation anomalies
    anomalies = detect_compilation_anomalies_internal()
    
    # Record anomalies
    Enum.each(anomalies, fn anomaly ->
      :ets.insert(:compilation_anomalies, {anomaly})
    end)
    
    Logger.info("Detected #{length(anomalies)} compilation anomalies")
    
    {:reply, {:ok, anomalies}, state}
  end

  @impl true
  def handle_call(:get_compilation_history, _from, state) do
    history = :ets.tab2list(:compilation_history)
    |> Enum.map(fn record ->
      %{
        compilation_id: record.compilation_id,
        start_time: record.start_time,
        end_time: record.end_time,
        duration: record.duration,
        compilation_type: record.compilation_type,
        success: record.success,
        reflection_score: record.reflection_score,
        optimization_applied: record.optimization_applied
      }
    end)
    
    {:reply, {:ok, history}, state}
  end

  @impl true
  def handle_call({:set_compilation_strategy, strategy}, _from, state) when strategy in [:aggressive, :adaptive, :conservative] do
    # Update compilation strategy
    case :ets.lookup(:compiler_strategies, strategy) do
      [{^strategy, _strategy_data}] ->
        # Update current strategy
        update_current_strategy(strategy)

        Logger.info("Compilation strategy updated to #{strategy}")

        {:reply, :ok, state}
      [] ->
        {:reply, {:error, :strategy_not_found}, state}
    end
  end

  @impl true
  def handle_call(:get_compilation_strategy, _from, state) do
    case :ets.lookup(:compiler_state, :state) do
      [{:state, compiler_state}] ->
        {:reply, {:ok, compiler_state.current_strategy}, state}
      [] ->
        {:reply, {:error, :strategy_not_found}, state}
    end
  end

  @impl true
  def handle_call(:validate_compiler_integrity, _from, state) do
    # Validate compiler integrity
    integrity_result = validate_compiler_integrity_internal()
    
    Logger.info("Compiler integrity validation: #{integrity_result.status}")
    
    {:reply, {:ok, integrity_result}, state}
  end

  @impl true
  def handle_call(:get_meta_compilation_metrics, _from, state) do
    # Get meta-compilation metrics
    metrics = calculate_meta_compilation_metrics()
    
    {:reply, {:ok, metrics}, state}
  end

  # Periodic analysis
  @impl true
  def handle_info(:analyze_compilation_performance, state) do
    Logger.info("Running periodic compilation analysis")
    
    # Analyze performance
    performance_analysis = analyze_compilation_performance()
    
    # Record metrics
    record_compilation_metrics(performance_analysis)
    
    # Schedule next analysis
    schedule_compilation_analysis()
    
    {:noreply, state}
  end

  # Helper functions
  defp schedule_compilation_analysis() do
    # Schedule compilation analysis every 60 seconds
    Process.send_after(self(), :analyze_compilation_performance, 60_000)
  end

  defp record_compilation_metrics(performance_analysis) when is_map(performance_analysis) do
    # Record performance analysis metrics
    metrics_record = {
      System.system_time(:millisecond),
      :performance_analysis,
      performance_analysis.total_compilations,
      performance_analysis.successful_compilations,
      performance_analysis.failed_compilations,
      performance_analysis.success_rate,
      performance_analysis.average_duration,
      performance_analysis.performance_assessment
    }

    :ets.insert(:compilation_metrics, {metrics_record})
  end

  defp reflect_on_compilation_data(compilation_data) when is_map(compilation_data) do
    # Reflect on compilation data
    start_time = compilation_data.start_time || 0
    end_time = compilation_data.end_time || System.system_time(:millisecond)
    duration = end_time - start_time
    
    # Calculate reflection score
    reflection_score = calculate_reflection_score(compilation_data)
    
    # Identify optimization opportunities
    optimization_opportunities = identify_optimization_opportunities(compilation_data)
    
    # Determine compilation quality
    compilation_quality = assess_compilation_quality(compilation_data)
    
    %{
      compilation_id: compilation_data.compilation_id,
      start_time: start_time,
      end_time: end_time,
      duration: duration,
      reflection_score: reflection_score,
      compilation_quality: compilation_quality,
      optimization_opportunities: optimization_opportunities,
      recommendations: generate_reflection_recommendations(compilation_data, reflection_score),
      analysis_timestamp: System.system_time(:millisecond)
    }
  end

  defp calculate_reflection_score(compilation_data) when is_map(compilation_data) do
    # Calculate reflection score based on various factors
    base_score = 0.5
    
    # Success bonus
    success_bonus = if compilation_data.success == true do
      0.3
    else
      -0.2
    end
    
    # Duration factor (optimal duration)
    optimal_duration = 5000  # 5 seconds
    duration_factor = case compilation_data.duration do
      d when d <= optimal_duration -> 0.2
      d when d <= optimal_duration * 2 -> 0.1
      _ -> -0.1
    end
    
    # Resource efficiency
    resource_efficiency = case compilation_data.resource_usage do
      usage when usage <= 0.8 -> 0.2
      usage when usage <= 1.0 -> 0.1
      _ -> -0.1
    end
    
    # Complexity factor
    complexity_factor = case compilation_data.complexity do
      :low -> 0.1
      :medium -> 0.0
      :high -> -0.1
      _ -> 0.0
    end
    
    total_score = base_score + success_bonus + duration_factor + resource_efficiency + complexity_factor
    min(1.0, max(0.0, total_score))
  end

  defp identify_optimization_opportunities(compilation_data) when is_map(compilation_data) do
    time_ops =
      if compilation_data.duration > 10000,
        do: [%{type: :performance, description: "Compilation time exceeds optimal threshold", impact: :high}],
        else: []

    resource_ops =
      if compilation_data.resource_usage > 0.9,
        do: [%{type: :resource, description: "High resource usage detected", impact: :medium}],
        else: []

    complexity_ops =
      if compilation_data.complexity == :high,
        do: [%{type: :complexity, description: "High complexity suggests optimization potential", impact: :high}],
        else: []

    time_ops ++ resource_ops ++ complexity_ops
  end

  defp assess_compilation_quality(compilation_data) when is_map(compilation_data) do
    # Assess overall compilation quality
    quality_factors = %{
      success: compilation_data.success == true,
      duration_within_threshold: compilation_data.duration <= 8000,
      resource_efficient: compilation_data.resource_usage <= 0.8,
      no_errors: compilation_data.error_count == 0,
      optimal_output: compilation_data.output_quality == :optimal
    }
    
    # Calculate quality score
    passed_checks = Enum.count(quality_factors, fn {_, passed} -> passed end)
    total_checks = map_size(quality_factors)
    
    if total_checks > 0 do
      passed_checks / total_checks
    else
      1.0
    end
  end

  defp generate_reflection_recommendations(compilation_data, reflection_score) when is_map(compilation_data) do
    score_recs =
      cond do
        reflection_score >= 0.8 -> ["Compilation quality is excellent"]
        reflection_score >= 0.6 -> ["Compilation quality is good but could be improved"]
        true -> ["Compilation quality requires attention"]
      end

    duration_recs =
      if compilation_data.duration > 10000,
        do: ["Consider optimizing compilation time"],
        else: []

    resource_recs =
      if compilation_data.resource_usage > 0.9,
        do: ["Monitor resource usage closely"],
        else: []

    score_recs ++ duration_recs ++ resource_recs
  end

  defp record_compilation(compilation_data, reflection_result) when is_map(compilation_data) and is_map(reflection_result) do
    # Record compilation in history
    record = {
      compilation_data.compilation_id,
      compilation_data.start_time,
      compilation_data.end_time,
      reflection_result.duration,
      compilation_data.compilation_type,
      compilation_data.success,
      reflection_result.reflection_score,
      reflection_result.optimization_applied
    }
    
    :ets.insert(:compilation_history, {record})
    
    # Record metrics
    metrics_record = {
      System.system_time(:millisecond),
      compilation_data.compilation_id,
      reflection_result.duration,
      compilation_data.resource_usage,
      compilation_data.success,
      reflection_result.reflection_score
    }
    
    :ets.insert(:compilation_metrics, {metrics_record})
  end

  defp update_compiler_state(compilation_data, reflection_result) when is_map(compilation_data) and is_map(reflection_result) do
    # Get current state
    case :ets.lookup(:compiler_state, :state) do
      [{:state, current_state}] ->
        # Calculate new statistics
        new_compilation_count = current_state.compilation_count + 1
        new_total_time = current_state.total_time + reflection_result.duration
        new_average_time = new_total_time / new_compilation_count
        
        # Update success rate
        new_success_count = if compilation_data.success == true do
          current_state.success_count + 1
        else
          current_state.success_count
        end
        
        new_success_rate = new_success_count / new_compilation_count
        
        # Update optimization score
        new_optimization_score = calculate_new_optimization_score(current_state, reflection_result)
        
        # Check convergence
        convergence_status = determine_convergence_status(current_state, reflection_result)
        
        new_state = %{
          compilation_count: new_compilation_count,
          total_time: new_total_time,
          average_time: new_average_time,
          success_count: new_success_count,
          success_rate: new_success_rate,
          current_strategy: current_state.current_strategy,
          last_compilation: System.system_time(:millisecond),
          optimization_score: new_optimization_score,
          convergence_status: convergence_status
        }
        
        :ets.insert(:compiler_state, {new_state})
      [] ->
        # Initialize state
        initial_state = %{
          compilation_count: 1,
          total_time: reflection_result.duration,
          average_time: reflection_result.duration,
          success_count: if(compilation_data.success == true, do: 1, else: 0),
          success_rate: if(compilation_data.success == true, do: 1.0, else: 0.0),
          current_strategy: :adaptive,
          last_compilation: System.system_time(:millisecond),
          optimization_score: reflection_result.reflection_score,
          convergence_status: :stable
        }
        
        :ets.insert(:compiler_state, {initial_state})
    end
  end

  defp calculate_new_optimization_score(current_state, reflection_result) when is_map(current_state) and is_map(reflection_result) do
    # Calculate new optimization score based on previous score and current result
    current_score = current_state.optimization_score || 0.0
    result_score = reflection_result.reflection_score
    
    # Weighted average
    0.7 * current_score + 0.3 * result_score
  end

  defp determine_convergence_status(current_state, reflection_result) when is_map(current_state) and is_map(reflection_result) do
    # Determine convergence status based on various factors
    case reflection_result.reflection_score do
      score when score >= 0.9 ->
        :optimal
      score when score >= 0.7 ->
        :stable
      score when score >= 0.5 ->
        :converging
      _ ->
        :unstable
    end
  end

  defp analyze_compilation_performance() do
    # Analyze overall compiler performance
    compilations = :ets.tab2list(:compilation_history)
    
    # Calculate performance metrics
    total_compilations = length(compilations)
    successful_compilations = Enum.count(compilations, fn c -> c.success == true end)
    failed_compilations = total_compilations - successful_compilations
    
    # Calculate average duration
    durations = Enum.map(compilations, fn c -> c.duration end)
    average_duration = if length(durations) > 0 do
      Enum.sum(durations) / length(durations)
    else
      0
    end
    
    # Calculate success rate
    success_rate = if total_compilations > 0 do
      successful_compilations / total_compilations
    else
      0.0
    end
    
    # Identify trends
    recent_compilations = Enum.take(compilations, 10)
    recent_success_rate = if length(recent_compilations) > 0 do
      Enum.count(recent_compilations, fn c -> c.success == true end) / length(recent_compilations)
    else
      0.0
    end
    
    # Performance assessment
    performance_assessment = cond do
      success_rate >= 0.95 and average_duration <= 5000 ->
        :excellent
      success_rate >= 0.85 and average_duration <= 10000 ->
        :good
      success_rate >= 0.75 ->
        :moderate
      true ->
        :poor
    end
    
    %{
      timestamp: System.system_time(:millisecond),
      total_compilations: total_compilations,
      successful_compilations: successful_compilations,
      failed_compilations: failed_compilations,
      success_rate: success_rate,
      average_duration: average_duration,
      recent_success_rate: recent_success_rate,
      performance_assessment: performance_assessment,
      recommendations: generate_performance_recommendations(success_rate, average_duration)
    }
  end

  defp generate_performance_recommendations(success_rate, average_duration) do
    rate_recs =
      cond do
        success_rate < 0.8 -> ["Low success rate detected - investigate compilation failures"]
        success_rate < 0.9 -> ["Success rate could be improved"]
        true -> []
      end

    duration_recs =
      cond do
        average_duration > 10000 -> ["Compilation time is high - consider performance optimizations"]
        average_duration > 5000  -> ["Compilation time could be optimized"]
        true -> []
      end

    recs = rate_recs ++ duration_recs
    if recs == [], do: ["Performance is within acceptable parameters"], else: recs
  end

  defp optimize_compilation_strategies() do
    # Optimize compilation strategies based on performance data
    performance_analysis = analyze_compilation_performance()
    
    # Determine optimal strategy
    optimal_strategy = determine_optimal_strategy(performance_analysis)
    
    # Update strategy
    update_current_strategy(optimal_strategy)
    
    # Generate optimization report
    %{
      timestamp: System.system_time(:millisecond),
      original_strategy: get_current_strategy(),
      optimal_strategy: optimal_strategy,
      optimization_reason: generate_optimization_reason(performance_analysis),
      performance_improvement: estimate_performance_improvement(performance_analysis)
    }
  end

  defp determine_optimal_strategy(performance_analysis) when is_map(performance_analysis) do
    # Determine optimal strategy based on performance analysis
    case performance_analysis.performance_assessment do
      :excellent ->
        :adaptive  # Keep current excellent strategy
      :good ->
        :adaptive  # Maintain good performance
      :moderate ->
        :adaptive  # Try to improve with adaptive strategy
      :poor ->
        :conservative  # Switch to conservative strategy for stability
    end
  end

  defp generate_optimization_reason(performance_analysis) when is_map(performance_analysis) do
    case performance_analysis.performance_assessment do
      :excellent -> "Performance is excellent - maintaining current strategy"
      :good -> "Performance is good - maintaining adaptive strategy"
      :moderate -> "Performance could be improved - optimizing strategy"
      :poor -> "Performance is poor - switching to conservative strategy"
    end
  end

  defp estimate_performance_improvement(performance_analysis) when is_map(performance_analysis) do
    # Estimate performance improvement based on strategy change
    case performance_analysis.performance_assessment do
      :excellent -> 0.0  # No improvement needed
      :good -> 0.05      # Small improvement expected
      :moderate -> 0.15  # Moderate improvement expected
      :poor -> 0.25      # Significant improvement expected
    end
  end

  defp record_compilation_metrics(performance_analysis) when is_map(performance_analysis) do
    metrics_record = {
      System.system_time(:millisecond),
      :performance_analysis,
      performance_analysis.total_compilations,
      performance_analysis.success_rate,
      performance_analysis.average_duration,
      performance_analysis.performance_assessment
    }
    :ets.insert(:compilation_metrics, {metrics_record})
  end

  defp record_compilation_optimization(optimization_result) when is_map(optimization_result) do
    # Record optimization in metrics
    metrics_record = {
      System.system_time(:millisecond),
      :strategy_optimization,
      optimization_result.original_strategy,
      optimization_result.optimal_strategy,
      optimization_result.optimization_reason
    }
    
    :ets.insert(:compilation_metrics, {metrics_record})
  end

  defp detect_compilation_anomalies_internal() do
    # Detect compilation anomalies
    compilations = :ets.tab2list(:compilation_history)

    spike_anomalies =
      if length(compilations) >= 5 do
        recent = Enum.take(compilations, 5)
        durations = Enum.map(recent, fn c -> c.duration end)
        if Enum.max(durations) > 2 * Enum.min(durations) do
          [%{
            type: :performance_spike,
            severity: :medium,
            description: "Sudden compilation time detected",
            details: %{max_duration: Enum.max(durations), min_duration: Enum.min(durations)},
            timestamp: System.system_time(:millisecond)
          }]
        else [] end
      else [] end

    failure_anomalies =
      if length(compilations) >= 10 do
        recent = Enum.take(compilations, 10)
        failures = Enum.count(recent, fn c -> c.success == false end)
        if failures >= 5 do
          [%{
            type: :high_failure_rate,
            severity: :high,
            description: "High compilation failure rate detected",
            details: %{failures: failures, total: length(recent)},
            timestamp: System.system_time(:millisecond)
          }]
        else [] end
      else [] end

    metrics = :ets.tab2list(:compilation_metrics)
    resource_usages = Enum.map(metrics, fn m -> m.resource_usage end)

    resource_anomalies =
      if length(resource_usages) >= 5 do
        max_usage = Enum.max(resource_usages)
        if max_usage > 0.95 do
          [%{
            type: :resource_overload,
            severity: :high,
            description: "Resource usage exceeds safe threshold",
            details: %{max_usage: max_usage, threshold: 0.95},
            timestamp: System.system_time(:millisecond)
          }]
        else [] end
      else [] end

    spike_anomalies ++ failure_anomalies ++ resource_anomalies
  end

  defp validate_compiler_integrity_internal() do
    # Validate overall compiler integrity
    validations = %{
      state_consistency: validate_state_consistency(),
      strategy_consistency: validate_strategy_consistency(),
      history_consistency: validate_history_consistency(),
      metrics_consistency: validate_metrics_consistency()
    }
    
    # Calculate overall integrity score
    passed_validations = Enum.count(validations, fn {_, passed} -> passed == :valid end)
    total_validations = map_size(validations)
    
    overall_score = if total_validations > 0 do
      passed_validations / total_validations
    else
      1.0
    end
    
    %{
      timestamp: System.system_time(:millisecond),
      overall_score: overall_score,
      passed_validations: passed_validations,
      total_validations: total_validations,
      validations: validations,
      status: if(overall_score >= 0.9, do: :valid, else: :invalid)
    }
  end

  defp validate_state_consistency() do
    # Validate compiler state consistency
    case :ets.lookup(:compiler_state, :state) do
      [{:state, state}] ->
        cond do
          state.compilation_count >= 0 and state.total_time >= 0 and 
          state.success_rate >= 0.0 and state.success_rate <= 1.0 ->
            :valid
          true ->
            :invalid
        end
      [] ->
        :invalid
    end
  end

  defp validate_strategy_consistency() do
    # Validate strategy consistency
    case :ets.lookup(:compiler_state, :state) do
      [{:state, state}] ->
        case state.current_strategy do
          :aggressive -> :valid
          :adaptive -> :valid
          :conservative -> :valid
          _ -> :invalid
        end
      [] ->
        :invalid
    end
  end

  defp validate_history_consistency() do
    # Validate history consistency
    history = :ets.tab2list(:compilation_history)
    
    # Check for duplicate compilation IDs
    compilation_ids = Enum.map(history, fn h -> h.compilation_id end)
    unique_ids = Enum.uniq(compilation_ids)
    
    if length(compilation_ids) == length(unique_ids) do
      :valid
    else
      :invalid
    end
  end

  defp validate_metrics_consistency() do
    # Validate metrics consistency
    metrics = :ets.tab2list(:compilation_metrics)
    
    # Check for metric validity
    valid_metrics = Enum.filter(metrics, fn m ->
      m.timestamp > 0 and 
      (m.compilation_id != nil or m.type != nil) and
      (m.resource_usage >= 0.0 and m.resource_usage <= 1.0)
    end)
    
    if length(valid_metrics) == length(metrics) do
      :valid
    else
      :invalid
    end
  end

  defp calculate_meta_compilation_metrics() do
    # Calculate meta-compilation metrics
    history = :ets.tab2list(:compilation_history)
    metrics = :ets.tab2list(:compilation_metrics)
    anomalies = :ets.tab2list(:compilation_anomalies)
    
    # Calculate compilation efficiency
    total_duration = Enum.sum(Enum.map(history, fn h -> h.duration end))
    total_compilations = length(history)
    average_duration = if total_compilations > 0 do
      total_duration / total_compilations
    else
      0
    end
    
    # Calculate compilation success rate
    successful_compilations = Enum.count(history, fn h -> h.success == true end)
    success_rate = if total_compilations > 0 do
      successful_compilations / total_compilations
    else
      0.0
    end
    
    # Calculate reflection quality
    reflection_scores = Enum.map(history, fn h -> h.reflection_score end)
    average_reflection_score = if length(reflection_scores) > 0 do
      Enum.sum(reflection_scores) / length(reflection_scores)
    else
      0.0
    end
    
    # Calculate anomaly rate
    anomaly_rate = if total_compilations > 0 do
      length(anomalies) / total_compilations
    else
      0.0
    end
    
    # Calculate optimization effectiveness
    optimizations = Enum.filter(metrics, fn m -> m.type == :strategy_optimization end)
    optimization_count = length(optimizations)
    
    %{
      timestamp: System.system_time(:millisecond),
      total_compilations: total_compilations,
      total_duration: total_duration,
      average_duration: average_duration,
      success_rate: success_rate,
      average_reflection_score: average_reflection_score,
      anomaly_rate: anomaly_rate,
      optimization_count: optimization_count,
      compilation_efficiency: if(average_duration > 0, do: 1.0 / average_duration, else: 0.0),
      meta_stability: calculate_meta_stability()
    }
  end

  defp calculate_meta_stability() do
    # Calculate meta-compilation stability
    history = :ets.tab2list(:compilation_history)
    metrics = :ets.tab2list(:compilation_metrics)
    
    # Check for stability indicators
    recent_history = Enum.take(history, 10)
    recent_metrics = Enum.take(metrics, 20)
    
    # Calculate stability score based on various factors
    duration_stability = calculate_duration_stability(recent_history)
    success_stability = calculate_success_stability(recent_history)
    resource_stability = calculate_resource_stability(recent_metrics)
    
    # Weighted average
    0.3 * duration_stability + 0.4 * success_stability + 0.3 * resource_stability
  end

  defp calculate_duration_stability(recent_history) when is_list(recent_history) do
    if length(recent_history) < 2 do
      1.0
    else
      durations = Enum.map(recent_history, fn h -> h.duration end)
      
      # Calculate coefficient of variation
      mean_duration = Enum.sum(durations) / length(durations)
      variance = Enum.reduce(durations, 0, fn d, acc -> acc + :math.pow(d - mean_duration, 2) end) / length(durations)
      std_dev = :math.sqrt(variance)
      
      # Lower coefficient of variation means higher stability
      coefficient_of_variation = std_dev / mean_duration
      
      max(0.0, min(1.0, 1.0 - coefficient_of_variation))
    end
  end

  defp calculate_success_stability(recent_history) when is_list(recent_history) do
    if length(recent_history) < 2 do
      1.0
    else
      # Calculate success rate stability
      successful_count = Enum.count(recent_history, fn h -> h.success == true end)
      success_rate = successful_count / length(recent_history)
      
      # Perfect success rate or perfect failure rate indicates stability
      if success_rate >= 0.95 or success_rate <= 0.05 do
        1.0
      else
        success_rate  # Intermediate success rates are less stable
      end
    end
  end

  defp calculate_resource_stability(recent_metrics) when is_list(recent_metrics) do
    if length(recent_metrics) < 2 do
      1.0
    else
      resource_usages = Enum.map(recent_metrics, fn m -> m.resource_usage end)
      
      # Calculate resource usage stability
      mean_usage = Enum.sum(resource_usages) / length(resource_usages)
      variance = Enum.reduce(resource_usages, 0, fn u, acc -> acc + :math.pow(u - mean_usage, 2) end) / length(resource_usages)
      std_dev = :math.sqrt(variance)
      
      # Lower standard deviation means higher stability
      max(0.0, min(1.0, 1.0 - std_dev))
    end
  end

  defp update_current_strategy(strategy) when strategy in [:aggressive, :adaptive, :conservative] do
    # Update current strategy in compiler state
    case :ets.lookup(:compiler_state, :state) do
      [{:state, current_state}] ->
        updated_state = %{current_state | current_strategy: strategy}
        :ets.insert(:compiler_state, {updated_state})
      [] ->
        initial_state = %{
          compilation_count: 0,
          total_time: 0,
          average_time: 0,
          success_rate: 1.0,
          current_strategy: strategy,
          last_compilation: 0,
          optimization_score: 1.0,
          convergence_status: :stable
        }
        :ets.insert(:compiler_state, {initial_state})
    end
  end

  defp get_current_strategy() do
    case :ets.lookup(:compiler_state, :state) do
      [{:state, state}] -> state.current_strategy
      [] -> :adaptive
    end
  end
end
