defmodule Tiannara.ToolForge.ToolArchitect do
  alias Tiannara.ToolForge.Domain.{ToolNeed, ToolSpecification}

  @spec design(ToolNeed.t()) :: ToolSpecification.t()
  def design(%ToolNeed{} = need) do
    language = select_language(need)
    architecture = select_architecture(need, language)
    interfaces = design_interfaces(need)
    dependencies = identify_dependencies(need, language)

    ToolSpecification.new(%{
      need_id: need.id,
      name: generate_name(need),
      description: "Tool to address: #{need.description}",
      language: language,
      architecture: architecture,
      interfaces: interfaces,
      dependencies: dependencies,
      resource_requirements: estimate_resources(need, architecture),
      security_requirements: identify_security_requirements(need),
      verification_plan: design_verification_plan(need, language),
      evolution_strategy: design_evolution_strategy(need),
      status: :specified
    })
  end

  @spec design_alternatives(ToolNeed.t(), non_neg_integer()) :: [ToolSpecification.t()]
  def design_alternatives(%ToolNeed{} = need, count \\ 3) do
    languages = [:elixir, :python, :rust]
    languages
    |> Enum.take(count)
    |> Enum.map(fn lang ->
      spec = design(%{need | id: need.id})
      %{spec | language: lang, architecture: select_architecture(need, lang)}
    end)
  end

  defp select_language(%ToolNeed{} = need) do
    cond do
      Map.get(need.constraints, :internal, false) -> :elixir
      String.contains?(need.description, "API") or String.contains?(need.capability_gap, "API") -> :python
      Map.get(need.constraints, :performance_critical, false) -> :rust
      String.contains?(need.description, "dashboard") or String.contains?(need.description, "UI") -> :typescript
      true -> :elixir
    end
  end

  defp select_architecture(need, :elixir) do
    %{
      pattern: :genserver,
      supervision: :one_for_one,
      interfaces: [:gen_server_api, :public_functions],
      integration: :supervision_tree,
      description: "OTP GenServer with public API functions, supervised by ToolForge"
    }
  end

  defp select_architecture(need, :python) do
    %{
      pattern: :fastapi_service,
      interfaces: [:rest_api, :websocket],
      integration: :http_client,
      description: "FastAPI microservice with REST endpoints, called via HTTP from Tiannara"
    }
  end

  defp select_architecture(need, :rust) do
    %{
      pattern: :native_library,
      interfaces: [:nif, :port],
      integration: :erlang_nif,
      description: "Rust native library exposed via Erlang NIFs for performance-critical paths"
    }
  end

  defp select_architecture(need, :typescript) do
    %{
      pattern: :react_app,
      interfaces: [:http, :websocket],
      integration: :phoenix_live_view,
      description: "TypeScript/React frontend served by Phoenix"
    }
  end

  defp design_interfaces(%ToolNeed{} = need) do
    base_interfaces = [
      %{name: :execute, type: :function, description: "Primary execution entry point"},
      %{name: :health, type: :function, description: "Health check"},
      %{name: :metrics, type: :function, description: "Runtime metrics"}
    ]
    required = Map.get(need, :required_interfaces, [])
    base_interfaces ++ Enum.map(required, fn iface ->
      %{name: iface, type: :function, description: "Required interface: #{iface}"}
    end)
  end

  defp identify_dependencies(need, :elixir), do: [%{name: :otp, version: ">= 26.0", type: :runtime}]
  defp identify_dependencies(need, :python), do: [
    %{name: :fastapi, version: ">= 0.100.0", type: :framework},
    %{name: :uvicorn, version: ">= 0.23.0", type: :server},
    %{name: :pydantic, version: ">= 2.0.0", type: :validation}
  ]
  defp identify_dependencies(need, :rust), do: [%{name: :rustler, version: ">= 0.30.0", type: :nif_bridge}]
  defp identify_dependencies(need, :typescript), do: [%{name: :react, version: ">= 18.0.0", type: :framework}]

  defp estimate_resources(need, architecture) do
    %{
      compute: Map.get(need.constraints, :max_compute, 100),
      memory_mb: Map.get(need.constraints, :max_memory_mb, 256),
      disk_mb: Map.get(need.constraints, :max_disk_mb, 100)
    }
  end

  defp identify_security_requirements(need) do
    %{
      sandboxed: true,
      max_execution_time_ms: Map.get(need.constraints, :timeout_ms, 30_000),
      no_network_access: not Map.get(need.constraints, :requires_network, false),
      resource_limits: true
    }
  end

  defp design_verification_plan(need, language) do
    %{
      unit_tests: "Test each function in isolation",
      integration_tests: "Test tool integration with Tiannara",
      property_tests: "Invariants hold under randomized input",
      chaos_tests: "Tool failure does not crash Tiannara",
      performance_tests: "Tool meets latency/throughput requirements",
      security_tests: "Tool cannot escape sandbox or exhaust resources",
      acceptance_criteria: [
        "All unit tests pass",
        "Integration with Tiannara verified",
        "No resource leaks after 1 hour of operation",
        "Health check responds within 100ms"
      ]
    }
  end

  defp design_evolution_strategy(need) do
    %{
      method: :genetic,
      population_size: 10,
      generations: 20,
      fitness_function: "multi_objective(#{need.capability_gap})",
      mutation_rate: 0.2,
      selection: :tournament,
      description: "Evolve tool implementation using genetic algorithm (API Evolution Engine pattern)"
    }
  end

  defp generate_name(need) do
    base = need.capability_gap
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s]/, "")
    |> String.split()
    |> Enum.take(3)
    |> Enum.join("_")
    "tool_#{base}"
  end
end
