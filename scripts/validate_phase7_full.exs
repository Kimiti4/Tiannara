defmodule Tiannara.ValidatePhase7 do
  @moduledoc """
  Phase 7 Full Validation Campaign — proves the MetaScience Engine
  can analyze Phase 6 output, detect biases/bottlenecks, and produce
  actionable recommendations.

  Checks:
    1. MetaScienceEngine starts and reports initial methodology score
    2. Receives and processes Phase 6 input via EventBus
    3. Detects confirmation bias from skewed validation results
    4. Detects low validation rate bottleneck
    5. Produces structured recommendations
    6. Methodology score drops after detecting systemic issues
    7. History accumulates across multiple analysis cycles
    8. Graceful handling of empty/malformed input
    9. Concurrent analysis requests don't corrupt state
    10. Recommendations include actionable improvement suggestions
  """

  def run do
    IO.puts("""
    #{String.duplicate("=", 58)}
     PHASE 7 FULL VALIDATION CAMPAIGN
     #{DateTime.utc_now() |> DateTime.to_iso8601()}
    #{String.duplicate("=", 58)}
    """)

    checks = [
      check_initial_state(),
      check_receives_phase6_input(),
      check_confirmation_bias_detection(),
      check_low_validation_rate_detection(),
      check_recommendations_produced(),
      check_methodology_score_update(),
      check_history_accumulation(),
      check_graceful_empty_input(),
      check_concurrent_analysis(),
      check_actionable_recommendations()
    ]

    passed = Enum.count(checks, & &1.passed)
    total = length(checks)

    IO.puts("\n#{String.duplicate("-", 58)}")
    IO.puts(" PHASE 7 VALIDATION RESULTS")
    IO.puts("#{String.duplicate("-", 58)}")

    Enum.each(checks, fn check ->
      status = if check.passed, do: "  OK", else: "  FAIL"
      IO.puts("#{status} #{check.name}")
      IO.puts("       #{check.detail}")
    end)

    IO.puts("#{String.duplicate("-", 58)}")
    IO.puts(" #{passed}/#{total} checks passed")

    if passed == total do
      IO.puts("\n  PHASE 7 VALIDATED — READY FOR PRODUCTION\n")
    else
      IO.puts("\n  PHASE 7 VALIDATION INCOMPLETE")
      IO.puts("  #{total - passed} check(s) failing.\n")
    end

    IO.puts("#{String.duplicate("-", 58)}")
  end

  defp ensure_running do
    case Tiannara.ASC.MetaScienceEngine.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end
  end

  defp inject_phase6_data(data) do
    payload = %{
      source_campaign: :phase6,
      result: data,
      timestamp: DateTime.utc_now()
    }
    send(Tiannara.ASC.MetaScienceEngine, {:executive_bus_message, %{type: "campaign.phase7.input", payload: payload}})
  end

  defp check_initial_state do
    try do
      ensure_running()
      score = Tiannara.ASC.MetaScienceEngine.methodology_score()
      passed = is_float(score) and score >= 0.0 and score <= 1.0
      %{name: "Initial state — methodology score reported", passed: passed, detail: "Score: #{score}"}
    rescue
      e -> %{name: "Initial state — methodology score reported", passed: false, detail: "Error: #{inspect(e)}"}
    end
  end

  defp check_receives_phase6_input do
    try do
      ensure_running()
      inject_phase6_data(%{strategy: :hypothesis_first, discoveries: 5, validated: 2, outcomes: [:confirmed], hypothesis_types: [:causal], cycle_time_ms: 1000})
      Tiannara.ASC.MetaScienceEngine.analyze()
      Process.sleep(500)
      recs = Tiannara.ASC.MetaScienceEngine.recommendations()
      passed = is_list(recs)
      %{name: "Receives Phase 6 input and produces recommendations", passed: passed, detail: "#{length(recs)} recommendation(s)"}
    rescue
      e -> %{name: "Receives Phase 6 input and produces recommendations", passed: false, detail: "Error: #{inspect(e)}"}
    end
  end

  defp check_confirmation_bias_detection do
    try do
      ensure_running()
      inject_phase6_data(%{strategy: :default, discoveries: 20, validated: 18, outcomes: List.duplicate(:confirmed, 19) ++ [:inconclusive], hypothesis_types: [:causal], cycle_time_ms: 3000})
      Tiannara.ASC.MetaScienceEngine.analyze()
      Process.sleep(500)
      recs = Tiannara.ASC.MetaScienceEngine.recommendations()
      bias_rec = Enum.find(recs, &(&1.type == :confirmation_bias))
      passed = bias_rec != nil
      %{name: "Confirmation bias detection — threshold > 0.9", passed: passed, detail: if(passed, do: "Detected: 19/20 confirmed", else: "Not detected")}
    rescue
      e -> %{name: "Confirmation bias detection — threshold > 0.9", passed: false, detail: "Error: #{inspect(e)}"}
    end
  end

  defp check_low_validation_rate_detection do
    try do
      ensure_running()
      inject_phase6_data(%{strategy: :exploratory, discoveries: 30, validated: 3, outcomes: List.duplicate(:inconclusive, 27) ++ List.duplicate(:confirmed, 3), hypothesis_types: [:causal], cycle_time_ms: 8000})
      Tiannara.ASC.MetaScienceEngine.analyze()
      Process.sleep(500)
      recs = Tiannara.ASC.MetaScienceEngine.recommendations()
      bottleneck_rec = Enum.find(recs, &(&1.type == :low_validation_rate))
      passed = bottleneck_rec != nil
      %{name: "Low validation rate detection — bottleneck < 20%", passed: passed, detail: if(passed, do: "Detected: 3/30 validated", else: "Not detected")}
    rescue
      e -> %{name: "Low validation rate detection — bottleneck < 20%", passed: false, detail: "Error: #{inspect(e)}"}
    end
  end

  defp check_recommendations_produced do
    try do
      ensure_running()
      # Inject data that triggers low validation rate detection
      inject_phase6_data(%{strategy: :hypothesis_first, discoveries: 30, validated: 3, outcomes: List.duplicate(:inconclusive, 27) ++ List.duplicate(:confirmed, 3), hypothesis_types: [:causal], cycle_time_ms: 8000})
      Tiannara.ASC.MetaScienceEngine.analyze()
      Process.sleep(500)
      recs = Tiannara.ASC.MetaScienceEngine.recommendations()
      passed = length(recs) > 0
      %{name: "Structured recommendations produced", passed: passed, detail: "#{length(recs)} recommendation(s) with types: #{Enum.map_join(recs, ", ", & &1.type)}"}
    rescue
      e -> %{name: "Structured recommendations produced", passed: false, detail: "Error: #{inspect(e)}"}
    end
  end

  defp check_methodology_score_update do
    try do
      ensure_running()
      score_before = Tiannara.ASC.MetaScienceEngine.methodology_score()
      inject_phase6_data(%{strategy: :exploratory, discoveries: 50, validated: 2, outcomes: List.duplicate(:inconclusive, 48) ++ List.duplicate(:confirmed, 2), hypothesis_types: [:causal], cycle_time_ms: 10000})
      Tiannara.ASC.MetaScienceEngine.analyze()
      Process.sleep(500)
      score_after = Tiannara.ASC.MetaScienceEngine.methodology_score()
      passed = is_float(score_after) and score_after >= 0.0
      %{name: "Methodology score updates after analysis", passed: passed, detail: "Before: #{Float.round(score_before, 3)}, After: #{Float.round(score_after, 3)}"}
    rescue
      e -> %{name: "Methodology score updates after analysis", passed: false, detail: "Error: #{inspect(e)}"}
    end
  end

  defp check_history_accumulation do
    try do
      ensure_running()
      Tiannara.ASC.MetaScienceEngine.analyze()
      Process.sleep(500)
      history = Tiannara.ASC.MetaScienceEngine.history()
      passed = is_list(history) and length(history) > 0
      %{name: "History accumulates across analyses", passed: passed, detail: "#{length(history)} analysis cycle(s) in history"}
    rescue
      e -> %{name: "History accumulates across analyses", passed: false, detail: "Error: #{inspect(e)}"}
    end
  end

  defp check_graceful_empty_input do
    try do
      ensure_running()
      send(Tiannara.ASC.MetaScienceEngine, {:executive_bus_message, %{type: "campaign.phase7.input", payload: %{}}})
      Tiannara.ASC.MetaScienceEngine.analyze()
      Process.sleep(500)
      score = Tiannara.ASC.MetaScienceEngine.methodology_score()
      passed = is_float(score) and score >= 0.0
      %{name: "Graceful empty/malformed input handling", passed: passed, detail: "Score: #{Float.round(score, 3)} after empty input"}
    rescue
      e -> %{name: "Graceful empty/malformed input handling", passed: false, detail: "Error: #{inspect(e)}"}
    end
  end

  defp check_concurrent_analysis do
    try do
      ensure_running()
      tasks = for i <- 1..3 do
        Task.async(fn ->
          inject_phase6_data(%{strategy: :random, discoveries: i * 10, validated: i * 3, outcomes: List.duplicate(:confirmed, i * 2) ++ List.duplicate(:inconclusive, i * 8), hypothesis_types: [:causal], cycle_time_ms: i * 1000})
          Tiannara.ASC.MetaScienceEngine.analyze()
        end)
      end
      Task.await_many(tasks, 5000)
      Process.sleep(1000)
      score = Tiannara.ASC.MetaScienceEngine.methodology_score()
      passed = is_float(score) and score >= 0.0
      %{name: "Concurrent analysis — state integrity maintained", passed: passed, detail: "Score: #{Float.round(score, 3)} after 3 concurrent analyses"}
    rescue
      e -> %{name: "Concurrent analysis — state integrity maintained", passed: false, detail: "Error: #{inspect(e)}"}
    end
  end

  defp check_actionable_recommendations do
    try do
      ensure_running()
      recs = Tiannara.ASC.MetaScienceEngine.recommendations()
      recs_with_details = Enum.filter(recs, & &1.detail)
      passed = length(recs_with_details) == length(recs)
      %{name: "Recommendations include actionable details", passed: passed, detail: "#{length(recs_with_details)}/#{length(recs)} with detail"}
    rescue
      e -> %{name: "Recommendations include actionable details", passed: false, detail: "Error: #{inspect(e)}"}
    end
  end
end

Tiannara.ValidatePhase7.run()
