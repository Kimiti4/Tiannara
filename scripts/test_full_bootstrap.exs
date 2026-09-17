# Run 50 projects and check for bootstrap law discovery

IO.puts("\n" <> String.duplicate("=", 80))
IO.puts("BOOTSTRAP LAW DISCOVERY TEST")
IO.puts(String.duplicate("=", 80) <> "\n")

# Start ASC processes
IO.puts("Starting ASC processes...\n")

processes = [
  {Tiannara.ASC.KnowledgeArchive, "Knowledge Archive"},
  {Tiannara.ASC.Observatory.ProjectObservatory, "Project Observatory"},
  {Tiannara.ASC.Laws.Registry, "Laws Registry"},
  {Tiannara.ASC.Requirements.Civilization, "Requirements Civilization"},
  {Tiannara.ASC.Testing.Civilization, "Testing Civilization"},
  {Tiannara.ASC.Implementation.Civilization, "Implementation Civilization"}
]

Enum.each(processes, fn {module, name} ->
  case Process.whereis(module) do
    nil ->
      IO.puts("  Starting #{name}...")
      {:ok, _} = module.start_link([])
    _pid -> :ok
  end
end)

IO.puts("  ✅ Ready\n")

# Run 50 projects
IO.puts("Running 50 synthetic projects...\n")

goals = [
  "Build an account service. Create accounts with unique user_id. List all accounts. Update account balance. Balance cannot go below zero. Must respond in under 100ms.",
  "Create a user management system. Register new users with unique emails. List users by role. Validate password strength. Delete inactive users after 90 days.",
  "Implement an inventory tracker. Add products to inventory. Update stock quantities atomically. List low-stock items. Stock quantity cannot be negative.",
  "Design a message queue. Publish messages to topics. Subscribe to message streams. Guarantee at-least-once delivery. Handle backpressure gracefully.",
  "Build a distributed cache. Store key-value pairs with TTL. Retrieve cached values. Expire entries after timeout. Consistent hashing across nodes."
]

Enum.each(1..50, fn i ->
  goal = Enum.at(goals, rem(i - 1, length(goals)))
  project_id = "bootstrap_test_#{String.pad_leading(Integer.to_string(i), 3, "0")}"
  
  if rem(i, 10) == 0, do: IO.write("[#{i}] ")
  
  try do
    project = Tiannara.ASC.Project.new(project_id, goal)
    {:ok, p1} = Tiannara.ASC.Requirements.Civilization.run(project)
    {:ok, p2} = Tiannara.ASC.Testing.Civilization.run(p1)
    {:ok, _p3} = Tiannara.ASC.Implementation.Civilization.run(p2)
    :ok
  rescue
    _e -> :error
  end
end)

IO.puts("✅ Done\n")

# Check snapshots
snapshots = Tiannara.ASC.Observatory.ProjectObservatory.all_snapshots()
IO.puts("Total snapshots: #{length(snapshots)}\n")

if length(snapshots) > 0 do
  first = hd(snapshots)
  IO.inspect(first, label: "Sample Snapshot", limit: 10)
  IO.puts("")
end

# Run law discovery
IO.puts("Running Laws.Discoverer...\n")
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
  IO.puts("No laws discovered yet. This is expected with only 50 projects.")
  IO.puts("Bootstrap laws need stronger correlations or more data.\n")
end

IO.puts(String.duplicate("=", 80) <> "\n")
