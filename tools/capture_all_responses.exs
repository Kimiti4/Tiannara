File.mkdir_p!("data")

IO.puts("")
IO.puts("Capturing all 45 exercise responses...")
IO.puts("")

t1 = Tiannara.Certification.Tier1Cognitive.run_all()
IO.puts("Tier 1: #{t1.exercises_passed}/#{t1.exercises_completed}")

t2 = Tiannara.Certification.Tier2Scientific.run_all()
IO.puts("Tier 2: #{t2.exercises_passed}/#{t2.exercises_completed}")

t3 = Tiannara.Certification.Tier3Constitutional.run_all()
IO.puts("Tier 3: #{t3.exercises_passed}/#{t3.exercises_completed}")

t4 = Tiannara.Certification.Tier4Civilizational.run_all()
IO.puts("Tier 4: #{t4.exercises_passed}/#{t4.exercises_completed}")

all = t1.details ++ t2.details ++ t3.details ++ t4.details

sections =
  Enum.map(all, fn ex ->
    status = if ex.passed, do: "PASS", else: "FAIL"
    name = Map.get(ex, :name, "Unnamed")
    header = "\n\n=== Exercise #{ex.exercise_id} — #{name} [#{status}] ===\n" <>
             "Confidence: #{Float.round(ex.confidence, 2)} | Duration: #{ex.duration_us}us\n\n"
    body = inspect(ex.output, pretty: true, limit: :infinity, printable_limit: :infinity)
    metrics_body = case ex.metrics do
      nil -> ""
      m when map_size(m) == 0 -> ""
      m -> "\nMetrics: #{inspect(m, pretty: true, limit: :infinity)}"
    end
    header <> body <> metrics_body
  end)

full = Enum.join(sections, "\n---\n")
File.write!("data/all_exercise_responses.txt", full)

IO.puts("")
IO.puts("All #{length(all)} responses saved to: data/all_exercise_responses.txt")
total_passed = t1.exercises_passed + t2.exercises_passed + t3.exercises_passed + t4.exercises_passed
total = t1.exercises_completed + t2.exercises_completed + t3.exercises_completed + t4.exercises_completed
IO.puts("Total: #{total_passed}/#{total} passed")
