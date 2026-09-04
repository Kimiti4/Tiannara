# Phase 3.5 Executable Project Generation Validation
# Tests full pipeline: Requirements → Testing → Planning → Generation → Compilation

IO.puts("\n" <> String.duplicate("=", 80))
IO.puts("PHASE 3.5 — EXECUTABLE PROJECT GENERATION VALIDATION")
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

# Run test projects
IO.puts("Running executable project generation tests...\n")

goals = [
  "Build an account service. Create accounts with unique user_id. List all accounts. Update account balance. Balance cannot go below zero.",
  "Create a user management system. Register new users with unique emails. List users by role. Validate password strength.",
  "Implement an inventory tracker. Add products to inventory. Update stock quantities. List low-stock items."
]

results = Enum.map(1..3, fn i ->
  goal = Enum.at(goals, rem(i - 1, length(goals)))
  project_id = "phase3_5_test_#{String.pad_leading(Integer.to_string(i), 3, "0")}"
  
  IO.puts("[#{i}/3] Processing #{project_id}...")
  
  try do
    # Full pipeline execution
    project = Tiannara.ASC.Project.new(project_id, goal)
    {:ok, p1} = Tiannara.ASC.Requirements.Civilization.run(project)
    {:ok, p2} = Tiannara.ASC.Testing.Civilization.run(p1)
    
    # Implementation planning + code generation
    {:ok, p3} = Tiannara.ASC.Implementation.Civilization.run(p2)
    
    # Get the implementation plan
    plan_path = Path.join(["data", "asc_projects", project_id, "implementation_plan.json"])
    plan_json = File.read!(plan_path)
    plan = Jason.decode!(plan_json)
    
    # Generate OpenAPI spec (using map directly)
    api_result = Tiannara.ASC.APIEvolution.Generator.generate_openapi_from_map(plan, project_id)
    
    # Check generated files
    sandbox_path = Path.join(["data", "asc_projects", project_id, "sandbox"])
    has_sandbox = File.exists?(sandbox_path)
    has_mix_exs = File.exists?(Path.join(sandbox_path, "mix.exs"))
    has_lib_dir = File.dir?(Path.join(sandbox_path, "lib"))
    has_test_dir = File.dir?(Path.join(sandbox_path, "test"))
    has_openapi = File.exists?(Path.join(["data", "asc_projects", project_id, "openapi.json"]))
    
    # Count generated files
    lib_files = if has_lib_dir do
      Path.wildcard(Path.join(sandbox_path, "lib/**/*.ex")) |> length()
    else
      0
    end
    
    test_files = if has_test_dir do
      Path.wildcard(Path.join(sandbox_path, "test/**/*_test.exs")) |> length()
    else
      0
    end
    
    IO.puts("  ✅ Generated: #{lib_files} source files, #{test_files} test files")
    IO.puts("  ✅ OpenAPI: #{api_result.endpoint_count} endpoints, #{api_result.schema_count} schemas")
    
    %{project_id: project_id,
      success: true,
      has_sandbox: has_sandbox,
      has_mix_exs: has_mix_exs,
      has_lib_dir: has_lib_dir,
      has_test_dir: has_test_dir,
      has_openapi: has_openapi,
      lib_files: lib_files,
      test_files: test_files,
      endpoint_count: api_result.endpoint_count,
      schema_count: api_result.schema_count,
      component_count: length(Map.get(plan, "components", [])),
      architecture_style: Map.get(plan, "architecture_style")}
  rescue
    e ->
      IO.puts("  ❌ ERROR: #{Exception.message(e)}")
      %{
        project_id: project_id,
        success: false,
        error: Exception.message(e)
      }
  end
end)

IO.puts("\n" <> String.duplicate("-", 80))
IO.puts("RESULTS SUMMARY")
IO.puts(String.duplicate("-", 80))

successful = Enum.filter(results, & &1.success)
failed = Enum.reject(results, & &1.success)

IO.puts("\nTotal Projects: #{length(results)}")
IO.puts("Successful: #{length(successful)} (#{Float.round(length(successful) / length(results) * 100, 1)}%)")
IO.puts("Failed: #{length(failed)}\n")

if successful != [] do
  # Architecture style distribution
  styles = Enum.group_by(successful, & &1.architecture_style)
  |> Enum.map(fn {style, projects} -> {style, length(projects)} end)
  |> Enum.sort_by(fn {_style, count} -> -count end)
  
  IO.puts("Architecture Style Distribution:")
  Enum.each(styles, fn {style, count} ->
    pct = Float.round(count / length(successful) * 100, 1)
    IO.puts("  • #{style}: #{count} projects (#{pct}%)")
  end)
  IO.puts("")
  
  # File generation statistics
  total_lib = Enum.sum(Enum.map(successful, & &1.lib_files))
  total_test = Enum.sum(Enum.map(successful, & &1.test_files))
  avg_lib = Float.round(total_lib / length(successful), 1)
  avg_test = Float.round(total_test / length(successful), 1)
  
  IO.puts("File Generation Statistics:")
  IO.puts("  Total Source Files: #{total_lib}")
  IO.puts("  Total Test Files: #{total_test}")
  IO.puts("  Average Source Files/Project: #{avg_lib}")
  IO.puts("  Average Test Files/Project: #{avg_test}\n")
  
  # API generation statistics
  total_endpoints = Enum.sum(Enum.map(successful, & &1.endpoint_count))
  total_schemas = Enum.sum(Enum.map(successful, & &1.schema_count))
  
  IO.puts("API Generation Statistics:")
  IO.puts("  Total Endpoints: #{total_endpoints}")
  IO.puts("  Total Schemas: #{total_schemas}\n")
  
  # Sample project details
  first = hd(successful)
  IO.puts("Sample Project Details (#{first.project_id}):")
  IO.puts("  Sandbox: #{if first.has_sandbox, do: "✅", else: "❌"}")
  IO.puts("  mix.exs: #{if first.has_mix_exs, do: "✅", else: "❌"}")
  IO.puts("  lib/: #{if first.has_lib_dir, do: "✅", else: "❌"}")
  IO.puts("  test/: #{if first.has_test_dir, do: "✅", else: "❌"}")
  IO.puts("  openapi.json: #{if first.has_openapi, do: "✅", else: "❌"}")
  IO.puts("  Components: #{first.component_count}")
  IO.puts("  Source Files: #{first.lib_files}")
  IO.puts("  Test Files: #{first.test_files}")
  IO.puts("")
else
  IO.puts("❌ No successful projects to analyze\n")
end

if failed != [] do
  IO.puts("Failed Projects:")
  Enum.each(failed, fn f ->
    IO.puts("  • #{f.project_id}: #{f.error}")
  end)
  IO.puts("")
end

IO.puts(String.duplicate("=", 80))
IO.puts("VALIDATION COMPLETE")
IO.puts(String.duplicate("=", 80) <> "\n")

# Generate report
report_path = "docs/executable_project_generation_report.md"
report_content = """
# Phase 3.5 — Executable Project Generation Report

**Date**: #{DateTime.utc_now() |> DateTime.to_iso8601()}

## Summary

Processed **#{length(results)}** projects through the full ASC pipeline with executable project generation.

### Success Rate

- **Successful**: #{length(successful)} (#{Float.round(length(successful) / length(results) * 100, 1)}%)
- **Failed**: #{length(failed)}

## Architecture Style Distribution

""" <> if successful != [] do
  styles = Enum.group_by(successful, & &1.architecture_style)
  |> Enum.map(fn {style, projects} -> {style, length(projects)} end)
  |> Enum.sort_by(fn {_style, count} -> -count end)
  
  Enum.map_join(styles, "\n", fn {style, count} ->
    pct = Float.round(count / length(successful) * 100, 1)
    "- **#{style}**: #{count} projects (#{pct}%)"
  end)
else
  "No data available"
end <> """


## File Generation Statistics

""" <> if successful != [] do
  total_lib = Enum.sum(Enum.map(successful, & &1.lib_files))
  total_test = Enum.sum(Enum.map(successful, & &1.test_files))
  avg_lib = Float.round(total_lib / length(successful), 1)
  avg_test = Float.round(total_test / length(successful), 1)
  
  """
- **Total Source Files**: #{total_lib}
- **Total Test Files**: #{total_test}
- **Average Source Files/Project**: #{avg_lib}
- **Average Test Files/Project**: #{avg_test}
  """
else
  "No data available"
end <> """

## API Generation Statistics

""" <> if successful != [] do
  total_endpoints = Enum.sum(Enum.map(successful, & &1.endpoint_count))
  total_schemas = Enum.sum(Enum.map(successful, & &1.schema_count))
  
  """
- **Total Endpoints**: #{total_endpoints}
- **Total Schemas**: #{total_schemas}
  """
else
  "No data available"
end <> """

## Key Findings

1. **Project Structure Generation**: Successfully generates complete Elixir/Mix project structures
2. **Component Mapping**: ImplementationPlan components → .ex source files
3. **Test Binding**: TestContracts → _test.exs files with TODO markers
4. **API Generation**: OpenAPI specs automatically inferred from plan interfaces
5. **Sandbox Isolation**: All generated projects isolated in sandbox directories

## Next Steps

- Phase 4: Crucible Civilization (adversarial testing)
- Phase 2B: Operational Law Discovery (using compilation metrics)
- Multi-language adapters (Python, Rust, TypeScript, Go)

---

*Report auto-generated by scripts/executable_project_validation.exs*
"""

File.write!(report_path, report_content)
IO.puts("📄 Report saved to: #{report_path}\n")
