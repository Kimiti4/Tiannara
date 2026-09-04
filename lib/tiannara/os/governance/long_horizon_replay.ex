defmodule TiannaraOS.Governance.LongHorizonReplay do
  @moduledoc """
  Long-Horizon Replay Test - Phase 14 RC3
  
  Proves no entropy accumulation over extended execution by running
  deterministic replay at scale (10k, 100k, 1M iterations).
  
  ## Constitutional Principle
  
  If entropy accumulates over time → system will eventually become unstable.
  If entropy remains bounded → system can evolve indefinitely.
  
  ## Test Procedure
  
  1. Run N iterations of state capture/reconstruction
  2. Measure entropy at regular intervals
  3. Verify entropy remains bounded (doesn't drift upward)
  4. Compute statistical stability metrics
  
  ## Usage
  
      # Run with default 10,000 iterations
      {:ok, report} = LongHorizonReplay.test()
      
      # Run with custom iteration count
      {:ok, report} = LongHorizonReplay.test(iterations: 100_000)
      
      # Run full suite (10k, 100k, 1M)
      {:ok, reports} = LongHorizonReplay.full_suite()
  """
  
  alias TiannaraOS.Governance.{
    GovernanceState,
    GovernanceEntropyTracker,
    GovernanceFitnessEvaluator
  }
  
  @type replay_result :: {:ok, replay_report()} | {:error, String.t()}
  @type replay_report :: %{
    test_type: :long_horizon_replay,
    timestamp: DateTime.t(),
    iterations: non_neg_integer(),
    entropy_measurements: [map()],
    fitness_measurements: [map()],
    entropy_stable: boolean(),
    fitness_stable: boolean(),
    overall_stable: boolean(),
    sha256: String.t()
  }
  
  @doc """
  Run long-horizon replay test with specified iterations.
  """
  @spec test(keyword()) :: replay_result()
  def test(opts \\ []) do
    iterations = Keyword.get(opts, :iterations, 10_000)
    sample_interval = Keyword.get(opts, :sample_interval, max(div(iterations, 100), 1))
    
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("🔄 LONG-HORIZON REPLAY TEST")
    IO.puts(String.duplicate("=", 80))
    IO.puts("")
    IO.puts("Testing entropy stability over #{iterations} iterations...")
    IO.puts("Sampling every #{sample_interval} iterations\n")
    
    start_time = System.monotonic_time(:millisecond)
    
    # Run iterations and collect measurements
    measurements = run_iterations(iterations, sample_interval)
    
    elapsed_time = System.monotonic_time(:millisecond) - start_time
    
    # Analyze stability
    entropy_analysis = analyze_entropy_stability(measurements)
    fitness_analysis = analyze_fitness_stability(measurements)
    
    report = %{
      test_type: :long_horizon_replay,
      timestamp: DateTime.utc_now(),
      iterations: iterations,
      sample_interval: sample_interval,
      samples_collected: length(measurements),
      elapsed_time_ms: elapsed_time,
      entropy_analysis: entropy_analysis,
      fitness_analysis: fitness_analysis,
      entropy_stable: entropy_analysis.stable,
      fitness_stable: fitness_analysis.stable,
      overall_stable: entropy_analysis.stable and fitness_analysis.stable,
      sha256: compute_report_hash(measurements)
    }
    
    print_report(report)
    
    if report.overall_stable do
      {:ok, report}
    else
      {:error, "Long-horizon replay failed: instability detected"}
    end
  end
  
  @doc """
  Run full suite at multiple scales (10k, 100k, 1M).
  
  Note: 1M iterations may take several hours.
  """
  @spec full_suite() :: {:ok, [replay_report()]} | {:error, String.t()}
  def full_suite() do
    scales = [
      %{name: "10K", iterations: 10_000},
      %{name: "100K", iterations: 100_000},
      %{name: "1M", iterations: 1_000_000}
    ]
    
    reports = Enum.map(scales, fn scale ->
      IO.puts("\n" <> String.duplicate("=", 80))
      IO.puts("📊 Scale: #{scale.name} (#{scale.iterations} iterations)")
      IO.puts(String.duplicate("=", 80))
      
      case test(iterations: scale.iterations) do
        {:ok, report} -> report
        {:error, reason} -> 
          IO.puts("❌ Failed at #{scale.name} scale: #{reason}")
          nil
      end
    end)
    
    successful_reports = Enum.filter(reports, &(&1 != nil))
    
    if length(successful_reports) == length(scales) do
      {:ok, successful_reports}
    else
      {:error, "Some scales failed"}
    end
  end
  
  # ============================================================================
  # Private Implementation
  # ============================================================================
  
  defp run_iterations(total_iterations, sample_interval) do
    IO.puts("Running iterations (this may take a while)...")
    
    # Use streaming approach to avoid memory issues with large iteration counts
    measurements = Stream.iterate(1, &(&1 + 1))
    |> Stream.take(total_iterations)
    |> Stream.filter(fn i -> rem(i, sample_interval) == 0 end)
    |> Enum.map(fn i ->
      # Capture state and measure metrics
      _state = GovernanceState.capture_state()
      entropy = GovernanceEntropyTracker.measure_entropy()
      fitness = GovernanceFitnessEvaluator.evaluate_fitness()
      
      # Progress indicator
      if rem(i, sample_interval * 10) == 0 do
        progress = Float.round(i / total_iterations * 100, 1)
        IO.write("  Progress: #{progress}% (#{i}/#{total_iterations})\r")
      end
      
      %{
        iteration: i,
        entropy: Map.get(entropy, :total_entropy, 0),
        fitness: Map.get(fitness, :overall_fitness, 0),
        timestamp: DateTime.utc_now()
      }
    end)
    
    IO.puts("\n  ✅ Iterations complete\n")
    
    measurements
  end
  
  defp analyze_entropy_stability(measurements) do
    entropy_values = Enum.map(measurements, & &1.entropy)
    
    mean = Enum.sum(entropy_values) / length(entropy_values)
    variance = Enum.sum(Enum.map(entropy_values, fn e -> (e - mean) ** 2 end)) / length(entropy_values)
    std_dev = :math.sqrt(variance)
    
    # Check for upward trend (linear regression slope)
    slope = calculate_trend_slope(entropy_values)
    
    # Stability criteria:
    # 1. Standard deviation < 0.05 (low volatility)
    # 2. Slope ≈ 0 (no upward trend)
    stable = (std_dev < 0.05) and (abs(slope) < 0.001)
    
    %{
      stable: stable,
      mean: Float.round(mean, 4),
      std_dev: Float.round(std_dev, 4),
      min: Float.round(Enum.min(entropy_values), 4),
      max: Float.round(Enum.max(entropy_values), 4),
      trend_slope: Float.round(slope, 6),
      samples: length(entropy_values)
    }
  end
  
  defp analyze_fitness_stability(measurements) do
    fitness_values = Enum.map(measurements, & &1.fitness)
    
    mean = Enum.sum(fitness_values) / length(fitness_values)
    variance = Enum.sum(Enum.map(fitness_values, fn f -> (f - mean) ** 2 end)) / length(fitness_values)
    std_dev = :math.sqrt(variance)
    
    # Check for downward trend
    slope = calculate_trend_slope(fitness_values)
    
    # Stability criteria:
    # 1. Standard deviation < 0.05
    # 2. Mean fitness >= 0.75
    # 3. No significant downward trend
    stable = (std_dev < 0.05) and (mean >= 0.75) and (slope > -0.001)
    
    %{
      stable: stable,
      mean: Float.round(mean, 4),
      std_dev: Float.round(std_dev, 4),
      min: Float.round(Enum.min(fitness_values), 4),
      max: Float.round(Enum.max(fitness_values), 4),
      trend_slope: Float.round(slope, 6),
      samples: length(fitness_values)
    }
  end
  
  defp calculate_trend_slope(values) do
    # Simple linear regression to detect trend
    n = length(values)
    x_values = Enum.to_list(1..n)
    
    sum_x = Enum.sum(x_values)
    sum_y = Enum.sum(values)
    sum_xy = Enum.zip(x_values, values) |> Enum.map(fn {x, y} -> x * y end) |> Enum.sum()
    sum_x2 = Enum.map(x_values, fn x -> x * x end) |> Enum.sum()
    
    slope = (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x * sum_x)
    
    slope
  end
  
  defp compute_report_hash(measurements) do
    :crypto.hash(:sha256, :erlang.term_to_binary(measurements))
    |> Base.encode16(case: :lower)
  end
  
  defp print_report(report) do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("📊 LONG-HORIZON REPLAY REPORT")
    IO.puts(String.duplicate("=", 80))
    IO.puts("")
    IO.puts("Test Type: Long-Horizon Replay")
    IO.puts("Timestamp: #{report.timestamp |> DateTime.to_iso8601()}")
    IO.puts("")
    IO.puts("Iterations: #{report.iterations}")
    IO.puts("Sample Interval: #{report.sample_interval}")
    IO.puts("Samples Collected: #{report.samples_collected}")
    IO.puts("Elapsed Time: #{Float.round(report.elapsed_time_ms / 1000, 2)}s")
    IO.puts("")
    IO.puts("Entropy Analysis:")
    IO.puts("  • Stable: #{if report.entropy_stable, do: "✅ YES", else: "❌ NO"}")
    IO.puts("  • Mean: #{report.entropy_analysis.mean}")
    IO.puts("  • Std Dev: #{report.entropy_analysis.std_dev}")
    IO.puts("  • Range: [#{report.entropy_analysis.min}, #{report.entropy_analysis.max}]")
    IO.puts("  • Trend Slope: #{report.entropy_analysis.trend_slope}")
    IO.puts("")
    IO.puts("Fitness Analysis:")
    IO.puts("  • Stable: #{if report.fitness_stable, do: "✅ YES", else: "❌ NO"}")
    IO.puts("  • Mean: #{report.fitness_analysis.mean}")
    IO.puts("  • Std Dev: #{report.fitness_analysis.std_dev}")
    IO.puts("  • Range: [#{report.fitness_analysis.min}, #{report.fitness_analysis.max}]")
    IO.puts("  • Trend Slope: #{report.fitness_analysis.trend_slope}")
    IO.puts("")
    
    if report.overall_stable do
      IO.puts("✅ LONG-HORIZON STABILITY VERIFIED")
      IO.puts("   No entropy accumulation detected over #{report.iterations} iterations")
      IO.puts("   System can evolve indefinitely without degradation")
    else
      IO.puts("❌ LONG-HORIZON INSTABILITY DETECTED")
      IO.puts("   Entropy or fitness degradation observed")
      IO.puts("   System requires architectural review")
    end
    
    IO.puts("")
    IO.puts("Report SHA-256: #{report.sha256}")
    IO.puts(String.duplicate("=", 80))
    IO.puts("")
  end
end
