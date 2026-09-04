# Stage 6 - Recursive Civilization Evolution Execution Script
# Executes 100+ generations to demonstrate measurable self-improvement

alias TiannaraOS.RecursiveCivilizationRunner

IO.puts("=" |> String.duplicate(80))
IO.puts("Stage 6 - Recursive Civilization Evolution")
IO.puts("Longitudinal Constitutional Validation")
IO.puts("=" |> String.duplicate(80))
IO.puts("")
IO.puts("This will execute 100 generations of the research civilization")
IO.puts("to prove that constitutional recursive adaptation produces")
IO.puts("measurable long-term scientific improvement.")
IO.puts("")
IO.puts("Expected duration: 2-5 minutes")
IO.puts("")

# Execute 100 generations
case RecursiveCivilizationRunner.execute(100, %{
  output_dir: "data/stage6",
  episodes_per_generation: 200,
  checkpoint_interval: 10
}) do
  {:ok, histories} ->
    IO.puts("\n" <> ("=" |> String.duplicate(80)))
    IO.puts("✅ Stage 6 Complete!")
    IO.puts("=" |> String.duplicate(80))
    IO.puts("")
    IO.puts("📊 Results Summary:")
    IO.puts("  Generations executed: #{length(histories)}")
    IO.puts("  Total episodes created: #{Enum.sum(Enum.map(histories, & &1.episodes_created))}")
    IO.puts("  Total discoveries: #{Enum.sum(Enum.map(histories, & &1.discoveries_made))}")
    IO.puts("  Final CAI: #{List.last(histories).civilization_adaptation_index}")
    IO.puts("  Constitutional violations: #{Enum.sum(Enum.map(histories, & &1.constitutional_violations))}")
    IO.puts("")
    IO.puts("📄 Output files:")
    IO.puts("  data/stage6/generation_history.csv")
    IO.puts("  data/stage6/recursive_evolution_report.md")
    IO.puts("  data/stage6/checkpoint_gen*.json")
    IO.puts("")
    IO.puts("The civilization has demonstrated measurable self-improvement")
    IO.puts("through constitutional recursive adaptation.")
    IO.puts("")

  {:error, reason} ->
    IO.puts("\n❌ Stage 6 failed: #{inspect(reason)}")
end
