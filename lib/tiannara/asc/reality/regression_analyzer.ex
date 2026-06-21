defmodule Tiannara.ASC.Reality.RegressionAnalyzer do
  @moduledoc """
  Phase 8B: Analyzes multidimensional EngineeringOutcomes to detect
  performance regressions, coverage drops, or other issues.
  Acts as the approval gate before a patch is committed.
  """
  
  alias Tiannara.ASC.Reality.EngineeringOutcome
  require Logger

  @doc """
  Evaluates an outcome and returns `:approve` or `:reject`.
  """
  def evaluate(%EngineeringOutcome{} = outcome) do
    cond do
      not outcome.compilation_success ->
        Logger.warning("  ❌ [RegressionAnalyzer] Rejected: Compilation failed")
        :reject
        
      not outcome.tests_passed ->
        Logger.warning("  ❌ [RegressionAnalyzer] Rejected: Tests failed")
        :reject
        
      outcome.coverage_delta < 0.0 ->
        Logger.warning("  ❌ [RegressionAnalyzer] Rejected: Test coverage dropped by #{outcome.coverage_delta}")
        :reject
        
      outcome.performance_delta_ms > 0 ->
        Logger.warning("  ❌ [RegressionAnalyzer] Rejected: Performance regression of #{outcome.performance_delta_ms}ms")
        :reject
        
      true ->
        Logger.info("  ✅ [RegressionAnalyzer] Approved: No regressions detected")
        :approve
    end
  end

  @doc """
  Calculates a multi-dimensional ROI to avoid overfitting to just performance.
  ROI = Performance Gain + Reliability Gain + Coverage Gain + Stability Gain - Complexity Cost
  """
  def calculate_roi(%EngineeringOutcome{} = outcome) do
    if not outcome.compilation_success or not outcome.tests_passed do
      -50.0
    else
      perf_gain = if outcome.performance_delta_ms < 0, do: abs(outcome.performance_delta_ms) / 1000.0, else: 0.0
      coverage_gain = outcome.coverage_delta * 100.0
      
      # Base reliability/stability for passing tests
      base_reliability = 5.0
      
      Float.round(perf_gain + coverage_gain + base_reliability - outcome.complexity_delta, 3)
    end
  end
end
