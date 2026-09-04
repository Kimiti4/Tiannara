# Full Tiannara Constitutional Certification Protocol
# Runs all 6 tiers and produces a structured report.
# Usage: mix run full_certification.exs

defmodule CertificationRunner do
  @tier_names %{
    1 => "Cognitive",
    2 => "Scientific",
    3 => "Constitutional",
    4 => "Civilizational",
    5 => "Autonomous Runtime",
    6 => "Discovery"
  }

  @exercise_names %{
    "1.1" => "Nested negation logic",
    "1.2" => "Contradiction detection",
    "1.3" => "Consistency repair",
    "1.4" => "Causal DAG construction",
    "1.5" => "Counterfactual reasoning",
    "1.6" => "Budget planning",
    "1.7" => "Multi-objective optimization",
    "1.8" => "Hypothesis generation",
    "1.9" => "Cross-domain transfer",
    "1.10" => "Tool dependency resolution",

    "2.1" => "Statistical hypothesis testing",
    "2.2" => "Experimental design validation",
    "2.3" => "Polynomial interpolation",
    "2.4" => "Linear regression",
    "2.5" => "Bayesian inference",
    "2.6" => "Error propagation",
    "2.7" => "Sample size calculation",
    "2.8" => "Confound detection",
    "2.9" => "Meta-analysis",
    "2.10" => "Causal inference",

    "3.1" => "Ethical dilemma resolution",
    "3.2" => "Harm minimization",
    "3.3" => "Rights conflict resolution",
    "3.4" => "Transparency audit",
    "3.5" => "Bias detection",
    "3.6" => "Privacy enforcement",
    "3.7" => "Consent verification",
    "3.8" => "Fairness metrics",
    "3.9" => "Accountability chain",
    "3.10" => "Value alignment",

    "4.1" => "Resource allocation",
    "4.2" => "Intergenerational equity",
    "4.3" => "Institutional design",
    "4.4" => "Technology impact",
    "4.5" => "Governance evaluation",
    "4.6" => "Ecological capacity",
    "4.7" => "Cultural preservation",
    "4.8" => "Conflict resolution",
    "4.9" => "Information ecosystem",
    "4.10" => "Economic stability",
    "4.11" => "Democratic participation",
    "4.12" => "Coordination game",
    "4.13" => "Existential risk",
    "4.14" => "Constitutional amendment",
    "4.15" => "Phase transition",

    "5.1" => "Memory Stability Under Load",
    "5.2" => "Self-Healing Under Supervisor Kill",
    "5.3" => "Hot-Swap Ontology Module",
    "5.4" => "Distributed Node Sync",
    "5.5" => "Scheduler Fairness",
    "5.6" => "Observatory Consistency",
    "5.7" => "Backpressure Handling",
    "5.8" => "Clock Skew Tolerance",
    "5.9" => "Chaos Resilience",
    "5.10" => "Complete Audit",

    "6.1" => "Novel Hypothesis Generation",
    "6.2" => "Model Invalidation",
    "6.3" => "Engineering Optimization",
    "6.4" => "Patent-Worthy Design",
    "6.5" => "Mathematical Identity Discovery",
    "6.6" => "Experimental Protocol Design",
    "6.7" => "Cross-Domain Transfer",
    "6.8" => "Causal Preservation",
    "6.9" => "Falsification Under Contradictory Evidence",
    "6.10" => "Cumulative Discovery Chain"
  }

  def run do
    IO.puts("\n" <> String.duplicate("═", 70))
    IO.puts("  TIANNARA CONSTITUTIONAL CERTIFICATION PROTOCOL")
    IO.puts("  #{DateTime.utc_now() |> DateTime.to_string()}")
    IO.puts(String.duplicate("═", 70) <> "\n")

    start_ms = System.monotonic_time(:millisecond)

    tiers = [
      {1, &Tiannara.Certification.Tier1Cognitive.run_all/0},
      {2, &Tiannara.Certification.Tier2Scientific.run_all/0},
      {3, &Tiannara.Certification.Tier3Constitutional.run_all/0},
      {4, &Tiannara.Certification.Tier4Civilizational.run_all/0},
      {5, &Tiannara.Certification.Tier5AutonomousRuntime.run_all/0},
      {6, &Tiannara.Certification.Tier6Discovery.run_all/0}
    ]

    results = Enum.map(tiers, fn {n, runner} ->
      tier_name = Map.get(@tier_names, n)
      IO.puts("┌─ Tier #{n}: #{tier_name}")
      IO.puts("│")

      result = runner.()

      Enum.each(result.details, fn ex ->
        icon = if ex.passed, do: "✓", else: "✗"
        conf = Map.get(ex, :confidence, 0.0)
        dur = format_duration(Map.get(ex, :duration_us, 0))
        name = Map.get(ex, :name) || Map.get(@exercise_names, ex.exercise_id) || "Unknown Exercise"
        IO.puts("│  #{icon} #{ex.exercise_id}: #{name} [conf=#{Float.round(conf, 2)} #{dur}]")

        unless ex.passed do
          error = Map.get(ex, :error, nil)
          if error, do: IO.puts("│     → #{error}")
        end
      end)

      pct = Float.round(result.score * 100, 1)
      bar = progress_bar(result.score, 20)
      IO.puts("│")
      IO.puts("└─ Score: #{bar} #{pct}% (#{result.exercises_passed}/#{result.exercises_completed})")
      IO.puts("")

      {n, result}
    end)

    duration_ms = System.monotonic_time(:millisecond) - start_ms

    # Overall summary
    scores = Enum.map(results, fn {_, r} -> r.score end)
    overall = Enum.sum(scores) / length(scores)
    total_ex = Enum.sum(Enum.map(results, fn {_, r} -> r.exercises_completed end))
    total_passed = Enum.sum(Enum.map(results, fn {_, r} -> r.exercises_passed end))

    status = cond do
      overall >= 0.9 -> "PASSING ✓"
      overall >= 0.7 -> "DEGRADED ⚠"
      true           -> "FAILING ✗"
    end

    IO.puts(String.duplicate("═", 70))
    IO.puts("  CERTIFICATION SUMMARY")
    IO.puts(String.duplicate("─", 70))

    Enum.each(results, fn {n, r} ->
      name = Map.get(@tier_names, n)
      bar  = progress_bar(r.score, 15)
      pct  = Float.round(r.score * 100, 1)
      IO.puts("  Tier #{n} #{String.pad_trailing(name, 20)} #{bar} #{pct}%")
    end)

    IO.puts(String.duplicate("─", 70))
    overall_pct = Float.round(overall * 100, 1)
    IO.puts("  Overall: #{progress_bar(overall, 20)} #{overall_pct}%  (#{total_passed}/#{total_ex} exercises)")
    IO.puts("  Status:  #{status}")
    IO.puts("  Runtime: #{duration_ms}ms")
    IO.puts(String.duplicate("═", 70) <> "\n")

    # Save JSON report
    report = %{
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      overall_status: status,
      overall_score: overall,
      overall_pct: overall_pct,
      total_exercises: total_ex,
      total_passed: total_passed,
      duration_ms: duration_ms,
      tiers: Enum.map(results, fn {n, r} ->
        %{
          tier: n,
          name: Map.get(@tier_names, n),
          score: r.score,
          pct: Float.round(r.score * 100, 1),
          passed: r.exercises_passed,
          total: r.exercises_completed,
          exercises: Enum.map(r.details, fn ex ->
            %{
              id: ex.exercise_id,
              name: Map.get(ex, :name) || Map.get(@exercise_names, ex.exercise_id) || "Unknown Exercise",
              passed: ex.passed,
              confidence: Map.get(ex, :confidence, 0.0),
              duration_us: Map.get(ex, :duration_us, 0),
              error: Map.get(ex, :error, nil)
            }
          end)
        }
      end)
    }

    json = Jason.encode!(report, pretty: true)
    path = "certification_run.json"
    File.write!(path, json)
    IO.puts("💾 Report saved → #{path}\n")

    overall
  end

  defp progress_bar(score, width) do
    filled = round(score * width)
    empty  = width - filled
    "[" <> String.duplicate("█", filled) <> String.duplicate("░", empty) <> "]"
  end

  defp format_duration(us) when is_integer(us) and us >= 1_000_000,
    do: "#{Float.round(us / 1_000_000, 1)}s"
  defp format_duration(us) when is_integer(us) and us >= 1_000,
    do: "#{Float.round(us / 1_000, 1)}ms"
  defp format_duration(us) when is_integer(us),
    do: "#{us}μs"
  defp format_duration(_), do: "?"
end

CertificationRunner.run()
