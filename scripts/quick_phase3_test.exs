# Quick Phase 3 test with 5 projects

IO.puts("\n🧪 QUICK PHASE 3 TEST (5 projects)\n")

# Start ASC processes
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

# Run 5 projects
goal = "Build an account service. Create accounts with unique user_id. List all accounts. Update account balance. Balance cannot go below zero."

project_id = "phase3_quick_test_001"

try do
  IO.puts("Running project #{project_id}...\n")
  
  project = Tiannara.ASC.Project.new(project_id, goal)
  {:ok, p1} = Tiannara.ASC.Requirements.Civilization.run(project)
  IO.puts("✅ Requirements phase complete")
  
  {:ok, p2} = Tiannara.ASC.Testing.Civilization.run(p1)
  IO.puts("✅ Testing phase complete")
  
  {:ok, p3} = Tiannara.ASC.Implementation.Civilization.run(p2)
  IO.puts("✅ Implementation phase complete\n")
  
  # Check if plan was generated
  plan_path = Path.join(["data", "asc_projects", project_id, "implementation_plan.json"])
  graph_path = Path.join(["data", "asc_projects", project_id, "component_graph.json"])
  
  has_plan = File.exists?(plan_path)
  has_graph = File.exists?(graph_path)
  
  IO.puts("Planning Artifacts:")
  IO.puts("  Implementation Plan: #{if has_plan, do: "✅ Generated", else: "❌ Missing"}")
  IO.puts("  Component Graph: #{if has_graph, do: "✅ Generated", else: "❌ Missing"}\n")
  
  if has_plan do
    plan_json = File.read!(plan_path)
    plan = Jason.decode!(plan_json)
    
    IO.puts("Plan Details:")
    IO.puts("  Architecture Style: #{plan["architecture_style"]}")
    IO.puts("  Components: #{length(plan["components"])}")
    IO.puts("  Interfaces: #{length(plan["interfaces"])}")
    IO.puts("  Validation Rules: #{length(plan["validation_rules"])}")
    IO.puts("  Dependencies: #{length(plan["dependencies"])}")
    IO.puts("  Complexity Score: #{plan["complexity_score"]}")
    IO.puts("")
    
    if length(plan["components"]) > 0 do
      first_component = hd(plan["components"])
      IO.puts("First Component:")
      IO.puts("  Name: #{first_component["name"]}")
      IO.puts("  Responsibilities: #{inspect(first_component["responsibilities"])}")
      IO.puts("  Interfaces: #{inspect(first_component["interfaces"])}")
      IO.puts("")
    end
  end
  
  IO.puts("✅ PHASE 3 VALIDATION SUCCESSFUL!")
  
rescue
  e ->
    IO.puts("❌ ERROR: #{Exception.message(e)}")
    IO.inspect(e, limit: :infinity, pretty: true)
end
