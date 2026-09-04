File.mkdir_p!("data")

IO.puts("")
IO.puts("================================================================")
IO.puts("  TIANNARA CONSTITUTIONAL CERTIFICATION PROTOCOL (TCCP)")
IO.puts("  4 Tiers — 45 Exercises — Real Runtime Evaluation")
IO.puts("================================================================")
IO.puts("")

IO.puts("--- TIER 1: Cognitive Intelligence (10 exercises) ---")
t1 = Tiannara.Certification.Tier1Cognitive.run_all()
IO.puts("  Score: #{Float.round(t1.score * 100, 1)}% | #{t1.exercises_passed}/#{t1.exercises_completed} passed | Status: #{t1.status}")
Enum.each(t1.details, fn ex ->
  icon = if ex.passed, do: "PASS", else: "FAIL"
  conf = Float.round(ex.confidence, 2)
  IO.puts("  [#{icon}] #{ex.exercise_id} (conf=#{conf}, #{ex.duration_us}us)")
end)

IO.puts("")
IO.puts("--- TIER 2: Scientific Intelligence (10 exercises) ---")
t2 = Tiannara.Certification.Tier2Scientific.run_all()
IO.puts("  Score: #{Float.round(t2.score * 100, 1)}% | #{t2.exercises_passed}/#{t2.exercises_completed} passed | Status: #{t2.status}")
Enum.each(t2.details, fn ex ->
  icon = if ex.passed, do: "PASS", else: "FAIL"
  IO.puts("  [#{icon}] #{ex.exercise_id} (#{ex.duration_us}us)")
end)

IO.puts("")
IO.puts("--- TIER 3: Constitutional Intelligence (10 exercises) ---")
t3 = Tiannara.Certification.Tier3Constitutional.run_all()
IO.puts("  Score: #{Float.round(t3.score * 100, 1)}% | #{t3.exercises_passed}/#{t3.exercises_completed} passed | Status: #{t3.status}")
Enum.each(t3.details, fn ex ->
  icon = if ex.passed, do: "PASS", else: "FAIL"
  IO.puts("  [#{icon}] #{ex.exercise_id} (#{ex.duration_us}us)")
end)

IO.puts("")
IO.puts("--- TIER 4: Civilizational Intelligence (15 exercises) ---")
t4 = Tiannara.Certification.Tier4Civilizational.run_all()
IO.puts("  Score: #{Float.round(t4.score * 100, 1)}% | #{t4.exercises_passed}/#{t4.exercises_completed} passed | Status: #{t4.status}")
Enum.each(t4.details, fn ex ->
  icon = if ex.passed, do: "PASS", else: "FAIL"
  IO.puts("  [#{icon}] #{ex.exercise_id} (#{ex.duration_us}us)")
end)

total_passed = t1.exercises_passed + t2.exercises_passed + t3.exercises_passed + t4.exercises_passed
total_exercises = t1.exercises_completed + t2.exercises_completed + t3.exercises_completed + t4.exercises_completed
overall = (t1.score + t2.score + t3.score + t4.score) / 4

overall_status = cond do
  overall >= 0.9 -> :passing
  overall >= 0.7 -> :degraded
  true -> :failing
end

IO.puts("")
IO.puts("================================================================")
IO.puts("  CERTIFICATION REPORT")
IO.puts("================================================================")
IO.puts("")
IO.puts("  Overall Status: #{overall_status}")
IO.puts("  Overall Score:  #{Float.round(overall * 100, 1)}%")
IO.puts("  Total Passed:   #{total_passed}/#{total_exercises}")
IO.puts("")
IO.puts("  Tier Scores:")
IO.puts("    Cognitive:       #{Float.round(t1.score * 100, 1)}% (#{t1.exercises_passed}/#{t1.exercises_completed})")
IO.puts("    Scientific:      #{Float.round(t2.score * 100, 1)}% (#{t2.exercises_passed}/#{t2.exercises_completed})")
IO.puts("    Constitutional:  #{Float.round(t3.score * 100, 1)}% (#{t3.exercises_passed}/#{t3.exercises_completed})")
IO.puts("    Civilizational:  #{Float.round(t4.score * 100, 1)}% (#{t4.exercises_passed}/#{t4.exercises_completed})")
IO.puts("")
IO.puts("================================================================")

report = %{
  overall_status: overall_status,
  overall_score: overall,
  total_passed: total_passed,
  total_exercises: total_exercises,
  tiers: %{
    cognitive: %{score: t1.score, passed: t1.exercises_passed, total: t1.exercises_completed, status: t1.status},
    scientific: %{score: t2.score, passed: t2.exercises_passed, total: t2.exercises_completed, status: t2.status},
    constitutional: %{score: t3.score, passed: t3.exercises_passed, total: t3.exercises_completed, status: t3.status},
    civilizational: %{score: t4.score, passed: t4.exercises_passed, total: t4.exercises_completed, status: t4.status}
  },
  timestamp: DateTime.utc_now()
}

File.write!("data/certification_report.json", Jason.encode!(report, pretty: true))
IO.puts("  Report saved to: data/certification_report.json")
IO.puts("")
