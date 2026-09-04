File.mkdir_p!("data")

IO.puts("")
IO.puts("================================================================")
IO.puts("  TIANNARA CONSTITUTIONAL CERTIFICATION PROTOCOL (TCCP)")
IO.puts("  6 Tiers — 60 Exercises — Full Runtime Evaluation")
IO.puts("================================================================")
IO.puts("")

IO.puts("Running Tier 1 — Cognitive Intelligence (10 exercises)...")
t1 = Tiannara.Certification.Tier1Cognitive.run_all()
IO.puts("  #{t1.exercises_passed}/#{t1.exercises_completed} passed | Score: #{Float.round(t1.score * 100, 1)}%")

IO.puts("Running Tier 2 — Scientific Intelligence (10 exercises)...")
t2 = Tiannara.Certification.Tier2Scientific.run_all()
IO.puts("  #{t2.exercises_passed}/#{t2.exercises_completed} passed | Score: #{Float.round(t2.score * 100, 1)}%")

IO.puts("Running Tier 3 — Constitutional Intelligence (10 exercises)...")
t3 = Tiannara.Certification.Tier3Constitutional.run_all()
IO.puts("  #{t3.exercises_passed}/#{t3.exercises_completed} passed | Score: #{Float.round(t3.score * 100, 1)}%")

IO.puts("Running Tier 4 — Civilizational Intelligence (15 exercises)...")
t4 = Tiannara.Certification.Tier4Civilizational.run_all()
IO.puts("  #{t4.exercises_passed}/#{t4.exercises_completed} passed | Score: #{Float.round(t4.score * 100, 1)}%")

IO.puts("Running Tier 5 — Autonomous Runtime (10 exercises)...")
t5 = Tiannara.Certification.Tier5AutonomousRuntime.run_all()
IO.puts("  #{t5.exercises_passed}/#{t5.exercises_completed} passed | Score: #{Float.round(t5.score * 100, 1)}%")

IO.puts("Running Tier 6 — Discovery Certification (10 exercises)...")
t6 = Tiannara.Certification.Tier6Discovery.run_all()
IO.puts("  #{t6.exercises_passed}/#{t6.exercises_completed} passed | Score: #{Float.round(t6.score * 100, 1)}%")

all = t1.details ++ t2.details ++ t3.details ++ t4.details ++ t5.details ++ t6.details

sections =
  Enum.map(all, fn ex ->
    status = if ex.passed, do: "PASS", else: "FAIL"
    name = Map.get(ex, :name, "Unnamed")
    header = "\n\n=== Exercise #{ex.exercise_id} — #{name} [#{status}] ===\n" <>
             "Confidence: #{Float.round(ex.confidence, 2)} | Duration: #{ex.duration_us}us\n\n"
    output = Map.get(ex, :output, "no output captured")
    body = inspect(output, pretty: true, limit: :infinity, printable_limit: :infinity)
    metrics_body = case ex[:metrics] do
      nil -> ""
      m when is_map(m) and map_size(m) == 0 -> ""
      m -> "\nMetrics: #{inspect(m, pretty: true, limit: :infinity)}"
      _ -> ""
    end
    header <> body <> metrics_body
  end)

full = Enum.join(sections, "\n---\n")
File.write!("data/all_exercise_responses.txt", full)

total_passed = t1.exercises_passed + t2.exercises_passed + t3.exercises_passed + t4.exercises_passed + t5.exercises_passed + t6.exercises_passed
total = t1.exercises_completed + t2.exercises_completed + t3.exercises_completed + t4.exercises_completed + t5.exercises_completed + t6.exercises_completed
overall = (t1.score + t2.score + t3.score + t4.score + t5.score + t6.score) / 6

report = %{
  overall_status: cond do overall >= 0.9 -> :passing; overall >= 0.7 -> :degraded; true -> :failing end,
  overall_score: overall,
  total_passed: total_passed,
  total_exercises: total,
  tiers: %{
    cognitive: %{score: t1.score, passed: t1.exercises_passed, total: t1.exercises_completed, status: t1.status},
    scientific: %{score: t2.score, passed: t2.exercises_passed, total: t2.exercises_completed, status: t2.status},
    constitutional: %{score: t3.score, passed: t3.exercises_passed, total: t3.exercises_completed, status: t3.status},
    civilizational: %{score: t4.score, passed: t4.exercises_passed, total: t4.exercises_completed, status: t4.status},
    autonomous_runtime: %{score: t5.score, passed: t5.exercises_passed, total: t5.exercises_completed, status: t5.status},
    discovery: %{score: t6.score, passed: t6.exercises_passed, total: t6.exercises_completed, status: t6.status}
  },
  timestamp: DateTime.utc_now()
}

File.write!("data/certification_report.json", Jason.encode!(report, pretty: true))

IO.puts("")
IO.puts("================================================================")
IO.puts("  FULL CERTIFICATION REPORT")
IO.puts("================================================================")
IO.puts("")
IO.puts("  Overall Status: #{report.overall_status}")
IO.puts("  Overall Score:  #{Float.round(overall * 100, 1)}%")
IO.puts("  Total Passed:   #{total_passed}/#{total}")
IO.puts("")
IO.puts("  Tier Scores:")
IO.puts("    Tier 1 — Cognitive:       #{Float.round(t1.score * 100, 1)}% (#{t1.exercises_passed}/#{t1.exercises_completed})")
IO.puts("    Tier 2 — Scientific:      #{Float.round(t2.score * 100, 1)}% (#{t2.exercises_passed}/#{t2.exercises_completed})")
IO.puts("    Tier 3 — Constitutional:  #{Float.round(t3.score * 100, 1)}% (#{t3.exercises_passed}/#{t3.exercises_completed})")
IO.puts("    Tier 4 — Civilizational:  #{Float.round(t4.score * 100, 1)}% (#{t4.exercises_passed}/#{t4.exercises_completed})")
IO.puts("    Tier 5 — Autonomous:      #{Float.round(t5.score * 100, 1)}% (#{t5.exercises_passed}/#{t5.exercises_completed})")
IO.puts("    Tier 6 — Discovery:       #{Float.round(t6.score * 100, 1)}% (#{t6.exercises_passed}/#{t6.exercises_completed})")
IO.puts("")
IO.puts("  All #{length(all)} exercise responses saved to: data/all_exercise_responses.txt")
IO.puts("  Certification report saved to: data/certification_report.json")
IO.puts("================================================================")
