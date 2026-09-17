# Test bootstrap law discovery on existing snapshots

IO.puts("\nRunning Laws.Discoverer...\n")

laws = Tiannara.ASC.Laws.Discoverer.run()

IO.puts("Discovered #{length(laws)} laws\n")

if laws != [] do
  Enum.each(laws, fn law ->
    IO.puts("✅ LAW DISCOVERED:")
    IO.puts("   Statement: #{law.statement}")
    IO.puts("   Confidence: #{Float.round(law.confidence * 100, 1)}%")
    IO.puts("   Status: #{law.status}")
    IO.puts("   Supporting Projects: #{length(law.supporting_project_ids)}")
    IO.puts("")
  end)
else
  IO.puts("No laws discovered (need more projects or stronger correlations)")
end
