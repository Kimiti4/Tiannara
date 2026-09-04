# scripts/run_phase_11_7_trajectory_tensor.exs
require Logger

Logger.configure(level: :info)

# Ensure application dependencies are started
Application.ensure_all_started(:gnat)
Application.ensure_all_started(:jason)

# Boot the coordinator GenServer
{:ok, pid} = Tiannara.UCC.TrajectoryTensor.start_link()

# Run the 500-sample discovery
case Tiannara.UCC.TrajectoryTensor.run_discovery(pid) do
  {:ok, %{results_count: count, rankings: rankings}} ->
    IO.puts("\n=== DISCOVERY COMPLETE ===")
    IO.puts("Evaluated #{count} successful configurations.")
    IO.puts("\nTrajectory Family GSI Rankings:")
    Enum.each(rankings, fn r ->
      IO.puts("  Family: #{r.family} | Max GSI: #{r.max_gsi} | Avg GSI: #{r.average_gsi}")
    end)
    
    IO.puts("\nSuccess Criterion Check:")
    case rankings do
      [best_family | rest] ->
        other_max_gsis = Enum.map(rest, & &1.max_gsi)
        if length(other_max_gsis) > 0 and best_family.max_gsi > Enum.max(other_max_gsis) do
          IO.puts("✅ SUCCESS: Trajectory family '#{best_family.family}' outperformed all other families on GSI.")
        else
          IO.puts("⚠️ WARNING: No single family clearly outperformed all others on max GSI.")
        end
      [] ->
        IO.puts("❌ ERROR: No rankings computed.")
    end
    System.halt(0)

  {:error, reason} ->
    IO.puts("\n❌ ERROR: Trajectory Tensor Discovery failed: #{inspect(reason)}")
    System.halt(1)
end
