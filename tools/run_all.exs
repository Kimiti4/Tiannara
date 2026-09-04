File.mkdir_p!("data")

IO.puts("=== Generating Constitutional Runtime Atlas ===")
case Tiannara.CRAV.RuntimeAtlas.export() do
  {:ok, path} -> IO.puts("Atlas written to: #{path}")
  {:error, reason} -> IO.puts("Atlas error: #{inspect(reason)}")
  other -> IO.puts("Atlas result: #{inspect(other)}")
end

IO.puts("")
IO.puts("=== Running Alpha Launch Pre-Flight ===")
case Tiannara.CRAV.AlphaLaunch.pre_flight() do
  {:ok, checklist} ->
    Enum.each(checklist, fn item ->
      status = if item[:pass], do: "PASS", else: "FAIL"
      IO.puts("  [#{status}] #{item[:name]}: #{item[:detail] || ""}")
    end)
  other ->
    IO.puts("Pre-flight result: #{inspect(other)}")
end

IO.puts("")
IO.puts("=== Running Alpha Launch ===")
case Tiannara.CRAV.AlphaLaunch.launch() do
  {:ok, cert} ->
    IO.puts("Launch certificate:")
    IO.puts("  ID: #{cert[:certificate_id]}")
    IO.puts("  Recommendation: #{cert[:recommendation]}")
    IO.puts("  Conditions: #{inspect(cert[:launch_conditions])}")
  other ->
    IO.puts("Launch result: #{inspect(other)}")
end

IO.puts("")
IO.puts("=== Running 10 Constitutional Challenges ===")
case Tiannara.CRAV.ChallengeRunner.run_all() do
  {:ok, results} ->
    passed = Enum.count(results, fn r ->
      case r[:result] do
        {:ok, _} -> true
        _ -> false
      end
    end)
    IO.puts("Results: #{passed}/#{length(results)} passed")
    IO.puts("")
    Enum.each(results, fn r ->
      status = case r[:result] do
        {:ok, _} -> "PASS"
        _ -> "FAIL"
      end
      conf = Float.round(r[:confidence], 2)
      IO.puts("  [#{status}] #{r[:name]} (confidence: #{conf})")
      
      case r[:result] do
        {:ok, data} ->
          IO.puts("    Response: #{inspect(data, pretty: true, limit: 500)}")
        {:error, err} ->
          IO.puts("    Error: #{inspect(err)}")
      end
      IO.puts("")
    end)
    
    File.write!("data/challenge_full_output.txt", 
      Enum.map_join(results, "\n---\n", fn r ->
        status = case r[:result] do
          {:ok, _} -> "PASS"
          _ -> "FAIL"
        end
        "[#{status}] #{r[:name]}\n#{inspect(r[:result], pretty: true, limit: :infinity)}"
      end)
    )
    IO.puts("Full output written to: data/challenge_full_output.txt")
    
  other ->
    IO.puts("Challenge result: #{inspect(other)}")
end
