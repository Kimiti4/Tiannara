defmodule Tiannara.ASC.Implementation.Supervisor do
  use Supervisor
  def start_link(opts \\ []), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_), do: Supervisor.init([Tiannara.ASC.Implementation.Civilization], strategy: :one_for_one)
end

defmodule Tiannara.ASC.Implementation.Civilization do
  @moduledoc """
  Implementation Civilization (Phase E — skeleton generator active).

  Generates structurally correct Elixir source module skeletons from the
  `ProjectWorld`, using `TestContracts` as the specification.

  ## Phase E.1 Approach

  Generates empty modules with:
  - Correct module naming derived from `ProjectWorld.capabilities`
  - `@spec` annotations derived from `TestContracts`
  - `@doc` sections summarising the contract and expected behaviour
  - Function bodies returning `{:error, :not_implemented}` (Crucible will catch these)
  - Compilation validation via `Code.string_to_quoted/1` before persisting

  Full function-body generation (filling in logic) comes in Phase F+ when
  the Architecture.Candidate genomes are richer and the Crucible loop is active.

  ## Guard Condition

  Requires `project.world.test_contracts` to be populated (Testing must have run first).
  Returns `{:error, :no_test_contracts}` if contracts are missing.

  ## Outputs

  - `project.world.source_files` — list of generated file maps
  - `project.artifacts.source` — list of file paths
  - `data/asc_projects/<id>/source/` — persisted .ex skeletons
  - Observatory: `architecture_fitness` (syntax-valid ratio)
  """

  use GenServer
  require Logger

  alias Tiannara.ASC.{Project, ProjectWorld}
  alias Tiannara.ASC.Observatory.ProjectObservatory
  alias Tiannara.ASC.Implementation.{Planner, Plan, ComponentGraph, Compiler}

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @spec run(Project.t()) :: {:ok, Project.t()} | {:error, term()}
  def run(%Project{world: nil} = project) do
    Logger.warning("[ASC.Implementation] No world model on project #{project.id}")
    {:error, :no_world_model}
  end

  def run(%Project{world: world} = project) when world.test_contracts == [] do
    Logger.warning("[ASC.Implementation] No test contracts on project #{project.id} — Testing must run first")
    {:error, :no_test_contracts}
  end

  def run(%Project{} = project) do
    Logger.info("[ASC.Implementation] Generating implementation plan for project #{project.id}")

    # Phase 3: Generate implementation plan FIRST
    plan = Planner.generate_plan(project.world, project.id)
    
    # Persist plan to disk
    plan_path = Planner.persist_plan(plan, project.id)
    Logger.info("[ASC.Implementation] Plan persisted to #{plan_path}")

    # Build component graph
    graph = ComponentGraph.build(plan)
    graph_path = persist_component_graph(graph, project.id)
    Logger.info("[ASC.Implementation] Component graph persisted to #{graph_path}")

    # Record planning metrics in observatory
    ProjectObservatory.record(project.id, %{
      component_count: length(plan.components),
      dependency_count: length(plan.dependencies),
      validation_rule_count: length(plan.validation_rules),
      workflow_count: length(plan.workflows),
      implementation_complexity: plan.complexity_score,
      architecture_style: Atom.to_string(plan.architecture_style)
    })

    Logger.info("[ASC.Implementation] Generating source skeletons from plan for project #{project.id}")

    # Phase 3.5: Generate executable project and compile
    Logger.info("[ASC.Implementation] Running compiler pipeline for project #{project.id}")
    {:ok, compilation_result} = Compiler.compile_and_test(plan, project.id, :elixir)
    
    Logger.info(
      "[ASC.Implementation] Compilation complete: success=#{compilation_result.success}, " <>
      "errors=#{length(compilation_result.compile_errors)}, " <>
      "tests_passed=#{compilation_result.test_pass_count}, " <>
      "tests_failed=#{compilation_result.test_fail_count}, " <>
      "duration_ms=#{compilation_result.duration_ms}"
    )

    # Phase 3.5: Generate OpenAPI spec from plan
    Logger.info("[ASC.Implementation] Generating OpenAPI specification for project #{project.id}")
    api_result = Tiannara.ASC.APIEvolution.Generator.generate_openapi(plan, project.id)
    
    Logger.info(
      "[ASC.Implementation] OpenAPI generated: #{api_result.endpoint_count} endpoints, " <>
      "#{api_result.schema_count} schemas at #{api_result.file_path}"
    )

    world  = project.world
    source_files = generate_source_files_from_plan(plan, world, project.id)

    {valid, invalid} = Enum.split_with(source_files, & &1.syntax_valid)

    Logger.info(
      "[ASC.Implementation] Generated #{length(source_files)} source files " <>
      "(#{length(valid)} valid, #{length(invalid)} invalid syntax)"
    )

    if length(invalid) > 0 do
      Enum.each(invalid, fn f ->
        Logger.warning("[ASC.Implementation] Syntax invalid: #{f.path}")
      end)
    end

    updated_world = ProjectWorld.put_source_files(world, source_files)
    updated = %{project |
      world:      updated_world,
      artifacts:  add_source_paths(project.artifacts, source_files),
      updated_at: DateTime.utc_now()
    }

    persist_source_files(project.id, source_files)

    fitness = if length(source_files) > 0,
      do: Float.round(length(valid) / length(source_files), 4), else: 0.0

    ProjectObservatory.record(project.id, %{
      architecture_fitness:  fitness,
      source_file_count:     length(source_files),
      syntax_valid_count:    length(valid)
    })

    {:ok, updated}
  rescue
    e ->
      Logger.error("[ASC.Implementation] Failed for #{project.id}: #{Exception.message(e)}")
      {:error, e}
  end

  @impl true
  def init(_opts) do
    Logger.info("[ASC.Implementation] Civilization initialized")
    {:ok, %{}}
  end

  defp project_module_prefix(project_id) do
    project_id
    |> String.split(~r/[_\-]/)
    |> Enum.map(&String.capitalize/1)
    |> Enum.join()
  end

  defp module_to_path(module_name) do
    module_name
    |> String.split(".")
    |> Enum.map(&Macro.underscore/1)
    |> Enum.join("/")
    |> Kernel.<>(".ex")
  end

  defp syntax_valid?(content) do
    case Code.string_to_quoted(content) do
      {:ok, _}    -> true
      {:error, _} -> false
    end
  end

  defp add_source_paths(artifacts, source_files) do
    existing = Map.get(artifacts, :source, [])
    new_paths = Enum.map(source_files, & &1.path)
    Map.put(artifacts, :source, Enum.uniq(existing ++ new_paths))
  end

  defp persist_source_files(project_id, source_files) do
    dir = Path.join(["data", "asc_projects", project_id, "source"])
    File.mkdir_p!(dir)
    Enum.each(source_files, fn f ->
      File.write!(Path.join(dir, Path.basename(f.path)), f.content)
    end)
    Logger.debug("[ASC.Implementation] Persisted #{length(source_files)} source files")
  rescue
    e -> Logger.warning("[ASC.Implementation] Could not persist: #{Exception.message(e)}")
  end

  # ---------------------------------------------------------------------------
  # Phase 3 — Plan-based source generation
  # ---------------------------------------------------------------------------

  defp generate_source_files_from_plan(%Plan{} = plan, %ProjectWorld{} = world, project_id) do
    prefix = project_module_prefix(project_id)

    # Generate source files from components in the plan
    plan.components
    |> Enum.map(fn component ->
      module_name = "#{prefix}.#{component.name}"
      content     = build_module_from_component(module_name, component, world)
      path        = module_to_path(module_name)

      %{
        path:         path,
        module_name:  module_name,
        content:      content,
        capabilities: component.responsibilities,
        syntax_valid: syntax_valid?(content),
        generated_at: DateTime.utc_now()
      }
    end)
  end

  defp build_module_from_component(module_name, component, world) do
    cap_list  = Enum.map_join(component.responsibilities, "\n", &"    - #{&1}")
    
    # Find test contracts for this component's responsibilities
    relevant_contracts = Enum.filter(world.test_contracts, fn tc ->
      Enum.any?(component.responsibilities, fn resp ->
        String.contains?(resp, tc.source_ref || "")
      end)
    end)

    # Generate functions based on interfaces
    functions = Enum.map_join(component.interfaces, "\n\n", fn interface_name ->
      contracts = Enum.filter(relevant_contracts, fn tc ->
        String.contains?(tc.description || "", interface_name)
      end)
      
      build_function_from_interface(interface_name, contracts)
    end)

    validation_comments = if length(component.dependencies) > 0 do
      "\n    ## Dependencies\n" <>
      Enum.map_join(component.dependencies, "\n", &"    - #{&1}")
    else
      ""
    end

    """
    defmodule #{module_name} do
      @moduledoc """
      Generated by ASC.Implementation.Civilization — Phase 3 (from Implementation Plan).

      ## Responsibilities

#{cap_list}
#{validation_comments}

      ## Note
      Function bodies return `{:error, :not_implemented}`. The Crucible phase
      will verify each TestContract and guide the next Implementation iteration.
      \"""

#{functions}
    end
    """
  end

  defp build_function_from_interface(interface_name, contracts) do
    contract_comments =
      contracts
      |> Enum.map_join("\n    ", fn tc ->
        "# [#{tc.type}] #{tc.description}"
      end)

    """
      @doc """
      Interface: #{interface_name}.

      TestContracts: #{length(contracts)}
      \"""
      @spec #{interface_name}(map()) :: {:ok, term()} | {:error, term()}
      def #{interface_name}(params) do
        #{contract_comments}
        {:error, :not_implemented}
      end
    """
  end

  defp persist_component_graph(%ComponentGraph{} = graph, project_id) do
    dir = Path.join(["data", "asc_projects", project_id])
    File.mkdir_p!(dir)

    file_path = Path.join(dir, "component_graph.json")
    json = Jason.encode!(graph, pretty: true)
    File.write!(file_path, json)

    file_path
  rescue
    e ->
      Logger.warning("[ASC.Implementation] Could not persist component graph: #{Exception.message(e)}")
      nil
  end
end
