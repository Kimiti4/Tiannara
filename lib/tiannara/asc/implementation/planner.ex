defmodule Tiannara.ASC.Implementation.Planner do
  @moduledoc """
  Implementation Planner — converts ProjectWorld specifications into structured implementation plans.

  Takes capabilities, invariants, constraints, risks, and test contracts,
  then produces components, interfaces, workflows, storage models, validation rules,
  dependencies, and deployment units BEFORE any code is generated.

  Plans are stored as standalone artifacts (NOT embedded in ProjectWorld):
  - data/asc_projects/<id>/implementation_plan.json
  - data/asc_projects/<id>/component_graph.json

  Registered in Knowledge Archive for future reuse and pattern discovery.
  """

  alias Tiannara.ASC.Implementation.Plan

  @doc """
  Generate an implementation plan from a ProjectWorld model.
  """
  def generate_plan(%Tiannara.ASC.ProjectWorld{} = world, project_id) do
    plan = Plan.new(project_id)

    # Step 1: Select architecture style based on constraints and capabilities
    architecture_style = select_architecture_style(world)

    # Step 2: Generate components from capabilities
    components = generate_components(world.capabilities)

    # Step 3: Generate interfaces from capabilities
    interfaces = generate_interfaces(world.capabilities)

    # Step 4: Translate invariants to validation rules
    validation_rules = translate_invariants(world.invariants)

    # Step 5: Generate storage models from capabilities and invariants
    storage_models = generate_storage_models(world.capabilities, world.invariants)

    # Step 6: Translate constraints to deployment units
    deployment_units = translate_constraints(world.constraints)

    # Step 7: Build component dependencies
    dependencies = build_dependencies(components, world.capabilities)

    # Step 8: Generate workflows from complex capabilities
    workflows = generate_workflows(world.capabilities, world.risks)

    # Assemble plan
    plan = %Plan{
      plan
      | architecture_style: architecture_style,
        components: components,
        interfaces: interfaces,
        validation_rules: validation_rules,
        storage_models: storage_models,
        dependencies: dependencies,
        deployment_units: deployment_units,
        workflows: workflows
    }

    # Calculate quality metrics using deterministic formula
    complexity = Plan.calculate_complexity(plan)
    confidence = Plan.estimate_confidence(plan)

    %Plan{
      plan
      | complexity_score: complexity,
        confidence: confidence
    }
  end

  # ---------------------------------------------------------------------------
  # Step 1: Architecture Style Selection (Enhanced Rules)
  # ---------------------------------------------------------------------------

  defp select_architecture_style(%Tiannara.ASC.ProjectWorld{} = world) do
    cond do
      high_throughput?(world.constraints) ->
        :event_driven

      distributed_workflow?(world.capabilities) ->
        :actor_based

      workflow_heavy?(world.capabilities) ->
        :pipeline

      service_count_high?(world.capabilities) ->
        :microservice

      true ->
        :modular_monolith
    end
  end

  defp high_throughput?(constraints) do
    Enum.any?(constraints, fn constraint ->
      String.contains?(String.downcase(constraint.description || ""), ["throughput", "requests/sec", "rps", "high load"])
      or
      (constraint.type == :performance and constraint.value > 1000)
    end)
  end

  defp distributed_workflow?(capabilities) do
    Enum.any?(capabilities, fn cap ->
      String.contains?(String.downcase(cap.name || ""), ["distribute", "coordinate", "orchestrate", "workflow"])
    end)
  end

  defp service_count_high?(capabilities) do
    # Multiple independent domains suggest microservices (>20 services)
    subjects = Enum.map(capabilities, &(&1.subject || "")) |> Enum.uniq()
    length(subjects) > 20
  end

  defp workflow_heavy?(capabilities) do
    Enum.count(capabilities, fn cap ->
      String.contains?(String.downcase(cap.name || ""), ["transform", "process", "ingest", "pipeline"])
    end) > 3
  end

  # ---------------------------------------------------------------------------
  # Step 2: Component Generation
  # ---------------------------------------------------------------------------

  defp generate_components(capabilities) do
    capabilities
    |> Enum.group_by(&(&1.subject || "Unknown"))
    |> Enum.map(fn {subject, caps} ->
      responsibilities = Enum.map(caps, & &1.name)
      interface_names = Enum.map(caps, fn cap ->
        "#{String.downcase(cap.verb || "handle")}_#{String.downcase(subject)}"
      end)

      %Plan.Component{
        name: "#{subject}Service",
        responsibilities: responsibilities,
        interfaces: interface_names,
        dependencies: []  # Will be filled in build_dependencies/2
      }
    end)
  end

  # ---------------------------------------------------------------------------
  # Step 3: Interface Generation
  # ---------------------------------------------------------------------------

  defp generate_interfaces(capabilities) do
    Enum.map(capabilities, fn cap ->
      verb = String.downcase(cap.verb || "handle")
      subject = String.downcase(cap.subject || "resource")

      %Plan.Interface{
        name: "#{verb}_#{subject}",
        protocol: :http,
        method: http_method_for_verb(verb),
        path: "/#{subject}#{path_suffix_for_verb(verb)}",
        input_schema: %{params: "map()"},
        output_schema: %{result: "{:ok, term()} | {:error, term()}"}
      }
    end)
  end

  defp http_method_for_verb(verb) do
    case verb do
      "create" -> "POST"
      "list" -> "GET"
      "get" -> "GET"
      "update" -> "PUT"
      "delete" -> "DELETE"
      _ -> "POST"
    end
  end

  defp path_suffix_for_verb(verb) do
    case verb do
      "list" -> ""
      "get" -> "/:id"
      _ -> ""
    end
  end

  # ---------------------------------------------------------------------------
  # Step 4: Invariant → Validation Rules
  # ---------------------------------------------------------------------------

  defp translate_invariants(invariants) do
    Enum.map(invariants, fn inv ->
      rule_type = determine_rule_type(inv)
      implementation = generate_validation_description(inv)

      %Plan.ValidationRule{
        invariant_ref: inv.id,
        rule_type: rule_type,
        implementation: implementation,
        severity: if(inv.strength == :must, do: :error, else: :warning)
      }
    end)
  end

  defp determine_rule_type(invariant) do
    desc = String.downcase(invariant.statement || "")

    cond do
      String.contains?(desc, ["unique", "duplicate"]) -> :uniqueness
      String.contains?(desc, ["negative", "below zero", "minimum", "maximum"]) -> :range
      String.contains?(desc, ["format", "pattern", "regex"]) -> :format
      String.contains?(desc, ["exist", "present", "required"]) -> :presence
      true -> :business_logic
    end
  end

  defp generate_validation_description(invariant) do
    "Validate: #{invariant.statement}"
  end

  # ---------------------------------------------------------------------------
  # Step 5: Storage Model Generation
  # ---------------------------------------------------------------------------

  defp generate_storage_models(capabilities, invariants) do
    capabilities
    |> Enum.map(&(&1.subject || "Unknown"))
    |> Enum.uniq()
    |> Enum.map(fn subject ->
      fields = generate_fields_for_subject(subject)
      constraints = extract_storage_constraints(invariants, subject)
      indexes = generate_indexes(subject, constraints)

      %Plan.StorageModel{
        entity: String.downcase(subject),
        fields: fields,
        constraints: constraints,
        indexes: indexes
      }
    end)
  end

  defp generate_fields_for_subject(subject) do
    [
      %{name: "id", type: "string", primary_key: true},
      %{name: "created_at", type: "datetime"},
      %{name: "updated_at", type: "datetime"}
    ]
  end

  defp extract_storage_constraints(invariants, subject) do
    Enum.flat_map(invariants, fn inv ->
      desc = String.downcase(inv.statement || "")

      cond do
        String.contains?(desc, ["unique"]) and String.contains?(desc, String.downcase(subject)) ->
          ["unique_index"]

        String.contains?(desc, ["cannot be null", "required"]) and String.contains?(desc, String.downcase(subject)) ->
          ["not_null"]

        true ->
          []
      end
    end)
  end

  defp generate_indexes(subject, constraints) do
    if Enum.member?(constraints, "unique_index") do
      ["idx_#{String.downcase(subject)}_unique"]
    else
      []
    end
  end

  # ---------------------------------------------------------------------------
  # Step 6: Constraint → Deployment Units
  # ---------------------------------------------------------------------------

  defp translate_constraints(constraints) do
    Enum.flat_map(constraints, fn con ->
      desc = String.downcase(con.description || "")

      cond do
        String.contains?(desc, ["response time", "<100ms", "latency"]) ->
          [%Plan.DeploymentUnit{
            name: "CacheLayer",
            resources: %{memory: "512MB"},
            scaling: :horizontal,
            replicas: 2
          }]

        String.contains?(desc, ["throughput", "10,000 requests", "high load"]) ->
          [%Plan.DeploymentUnit{
            name: "LoadBalancer",
            resources: %{cpu: "2 cores"},
            scaling: :horizontal,
            replicas: 3
          },
           %Plan.DeploymentUnit{
             name: "QueueLayer",
             resources: %{memory: "1GB"},
             scaling: :horizontal,
             replicas: 2
           }]

        String.contains?(desc, ["availability", "99.9%", "uptime"]) ->
          [%Plan.DeploymentUnit{
            name: "HealthMonitor",
            resources: %{cpu: "0.5 cores"},
            scaling: :none,
            replicas: 1
          }]

        true ->
          []
      end
    end)
  end

  # ---------------------------------------------------------------------------
  # Step 7: Dependency Construction
  # ---------------------------------------------------------------------------

  defp build_dependencies(components, capabilities) do
    # Simple heuristic: services depend on repositories and validators
    Enum.flat_map(components, fn component ->
      service_name = component.name
      subject = String.replace(service_name, "Service", "")

      [
        %Plan.Dependency{
          from: service_name,
          to: "#{subject}Repository",
          type: :calls
        },
        %Plan.Dependency{
          from: service_name,
          to: "#{subject}Validator",
          type: :calls
        }
      ]
    end)
  end

  # ---------------------------------------------------------------------------
  # Step 8: Workflow Generation
  # ---------------------------------------------------------------------------

  defp generate_workflows(capabilities, risks) do
    # Identify multi-step operations
    complex_caps = Enum.filter(capabilities, fn cap ->
      String.contains?(String.downcase(cap.name || ""), ["transfer", "migrate", "synchronize", "reconcile"])
    end)

    Enum.map(complex_caps, fn cap ->
      steps = generate_workflow_steps(cap)
      error_handling = determine_error_handling(risks, cap)

      %Plan.Workflow{
        name: "#{cap.name}_workflow",
        steps: steps,
        error_handling: error_handling
      }
    end)
  end

  defp generate_workflow_steps(capability) do
    [
      "Validate input parameters",
      "Check preconditions",
      "Execute #{String.downcase(capability.verb || "operation")}",
      "Update related entities",
      "Emit completion event"
    ]
  end

  defp determine_error_handling(risks, _capability) do
    has_data_risk = Enum.any?(risks, fn risk ->
      String.contains?(String.downcase(risk.description || ""), ["corruption", "data loss", "integrity"])
    end)

    if has_data_risk, do: :rollback, else: :compensate
  end

  # ---------------------------------------------------------------------------
  # Persistence Helper
  # ---------------------------------------------------------------------------

  @doc """
  Persist implementation plan to disk (standalone artifact, NOT in ProjectWorld).
  """
  def persist_plan(%Plan{} = plan, project_id) do
    dir = Path.join(["data", "asc_projects", project_id])
    File.mkdir_p!(dir)

    file_path = Path.join(dir, "implementation_plan.json")
    json = Jason.encode!(plan, pretty: true)
    File.write!(file_path, json)

    file_path
  end
end
