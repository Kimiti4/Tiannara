File.mkdir_p!("data")

IO.puts("")
IO.puts("=============================================")
IO.puts("  TIANNARA — 13 CONSTITUTIONAL CHALLENGES")
IO.puts("=============================================")
IO.puts("")

case Tiannara.CRAV.ChallengeRunner.run_all() do
  {:ok, results} ->
    passed = Enum.count(results, fn r ->
      case r[:result] do
        {:ok, _} -> true
        _ -> false
      end
    end)

    avg_conf = results
    |> Enum.map(& &1[:confidence])
    |> Enum.sum()
    |> Kernel./(length(results))
    |> Float.round(2)

    IO.puts("Results: #{passed}/#{length(results)} passed")
    IO.puts("Average confidence: #{avg_conf}")
    IO.puts("")

    Enum.each(results, fn r ->
      status = case r[:result] do
        {:ok, _} -> "PASS"
        _ -> "FAIL"
      end
      conf = Float.round(r[:confidence], 2)
      time_us = r[:execution_time_us] || 0
      IO.puts("─────────────────────────────────────────")
      IO.puts("[#{status}] #{r[:name]}  (confidence: #{conf}, time: #{time_us}us)")
      IO.puts("")

      case r[:result] do
        {:ok, data} ->
          formatted = inspect(data, pretty: true, limit: :infinity)
          IO.puts(formatted)
        {:error, err} ->
          IO.puts("Error: #{inspect(err, pretty: true, limit: :infinity)}")
      end
      IO.puts("")
    end)

    output = Enum.map_join(results, "\n═══════════════════════════════════════════\n\n", fn r ->
      status = case r[:result] do
        {:ok, _} -> "PASS"
        _ -> "FAIL"
      end
      conf = Float.round(r[:confidence], 2)
      time_us = r[:execution_time_us] || 0
      header = "[#{status}] #{r[:name]}  (confidence: #{conf}, time: #{time_us}us)\n"
      body = case r[:result] do
        {:ok, data} -> inspect(data, pretty: true, limit: :infinity)
        {:error, err} -> "Error: #{inspect(err, pretty: true, limit: :infinity)}"
      end
      header <> "\n" <> body
    end)

    File.write!("data/challenge_full_output.txt", output)
    IO.puts("═══════════════════════════════════════════")
    IO.puts("Full output written to: data/challenge_full_output.txt")

  other ->
    IO.puts("Unexpected result: #{inspect(other)}")
end
