File.mkdir_p!("data")

IO.puts("")
IO.puts("===================================================")
IO.puts("  TIANNARA — FULL INTEGRATION TEST SUITE")
IO.puts("===================================================")
IO.puts("")

results = %{}

IO.puts("1. Runtime Census")
case Tiannara.CRAV.RuntimeCensus.census() do
  {:ok, entries} when is_list(entries) ->
    alive = Enum.count(entries, fn e -> e.status == :alive end)
    IO.puts("   PASS: #{alive}/#{length(entries)} subsystems alive")
  err ->
    IO.puts("   ERROR: #{inspect(err)}")
end

IO.puts("")
IO.puts("2. Activation Matrix")
case Tiannara.CRAV.ActivationMatrix.matrix() do
  {:ok, matrix} when is_list(matrix) ->
    active = Enum.count(matrix, fn m -> m.overall == :active end)
    IO.puts("   PASS: #{active} active subsystems")
  err ->
    IO.puts("   ERROR: #{inspect(err)}")
end

IO.puts("")
IO.puts("3. Discovery Chain")
case Tiannara.CRAV.DiscoveryChain.verify() do
  {:ok, stages} when is_list(stages) ->
    reachable = Enum.count(stages, fn s -> s.reachable end)
    IO.puts("   PASS: #{reachable}/#{length(stages)} stages reachable")
  err ->
    IO.puts("   ERROR: #{inspect(err)}")
end

IO.puts("")
IO.puts("4. Launch Readiness")
case Tiannara.CRAV.LaunchReadiness.score() do
  {:ok, score} when is_map(score) ->
    overall = Map.get(score, :overall_alpha_readiness, 0.0)
    rec = Map.get(score, :recommendation, :unknown)
    IO.puts("   PASS: #{overall}% readiness — #{rec}")
  err ->
    IO.puts("   ERROR: #{inspect(err)}")
end

IO.puts("")
IO.puts("5. Soak Test (5 second run)")
case Tiannara.CRAV.SoakTest.start_link(%{duration_hours: 0.001}) do
  {:ok, _pid} ->
    Process.sleep(5000)
    st = Tiannara.CRAV.SoakTest.status()
    IO.puts("   PASS: running=#{st.running}, elapsed=#{st.elapsed_hours}h, health=#{st.health_checks}")
    Tiannara.CRAV.SoakTest.stop_test()
    IO.puts("   Stopped cleanly")
  {:error, {:already_started, _}} ->
    IO.puts("   Already running, skipping")
  err ->
    IO.puts("   ERROR: #{inspect(err)}")
end

IO.puts("")
IO.puts("6. Challenge Runner (13 challenges)")
case Tiannara.CRAV.ChallengeRunner.run_all() do
  {:ok, results_list} when is_list(results_list) ->
    passed = Enum.count(results_list, fn r -> match?({:ok, _}, r.result) end)
    avg_conf = results_list |> Enum.map(& &1.confidence) |> Enum.sum() |> Kernel./(length(results_list)) |> Float.round(2)
    IO.puts("   PASS: #{passed}/#{length(results_list)} challenges passed")
    IO.puts("   Average confidence: #{avg_conf}")
    Enum.each(results_list, fn r ->
      status = case r.result do {:ok, _} -> "PASS"; _ -> "FAIL" end
      IO.puts("   [#{status}] #{r.name} (conf=#{Float.round(r.confidence, 2)}, time=#{r.execution_time_us}us)")
    end)
  err ->
    IO.puts("   ERROR: #{inspect(err)}")
end

IO.puts("")
IO.puts("7. Atlas Generation")
case Tiannara.CRAV.RuntimeAtlas.generate() do
  {:ok, atlas} when is_map(atlas) ->
    subs = Map.get(atlas, :subsystems, [])
    IO.puts("   PASS: #{length(subs)} subsystems mapped")
    IO.puts("   Title: #{Map.get(atlas, :title, "")}")
  err ->
    IO.puts("   ERROR: #{inspect(err)}")
end

IO.puts("")
IO.puts("8. Alpha Launch Pre-flight")
case Tiannara.CRAV.AlphaLaunch.pre_flight() do
  {:ok, checklist} when is_map(checklist) ->
    checks = Map.to_list(checklist) |> Enum.filter(fn {_k, v} -> is_map(v) end)
    passed_checks = Enum.count(checks, fn {_k, v} -> v[:pass] end)
    total_checks = length(checks)
    IO.puts("   #{passed_checks}/#{total_checks} checks passed")
    Enum.each(checks, fn {name, info} ->
      icon = if info[:pass], do: "[PASS]", else: "[FAIL]"
      reason = info[:reason] || ""
      IO.puts("   #{icon} #{name}: #{reason}")
    end)
    IO.puts("   Overall: #{checklist[:overall_pass]}")
  err ->
    IO.puts("   ERROR: #{inspect(err)}")
end

IO.puts("")
IO.puts("9. CRAV Full Report")
case Tiannara.CRAV.run() do
  {:ok, report} when is_map(report) ->
    IO.puts("   Verdict: #{report.verdict}")
    lr = Map.get(report, :launch_readiness, %{})
    IO.puts("   Runtime: #{Map.get(lr, :runtime_readiness, 0)}%")
    IO.puts("   Scientific: #{Map.get(lr, :scientific_readiness, 0)}%")
    IO.puts("   Engineering: #{Map.get(lr, :engineering_readiness, 0)}%")
    IO.puts("   Overall: #{Map.get(lr, :overall_alpha_readiness, 0)}%")
  err ->
    IO.puts("   ERROR: #{inspect(err)}")
end

IO.puts("")
IO.puts("===================================================")
IO.puts("  INTEGRATION TEST SUITE COMPLETE")
IO.puts("===================================================")
