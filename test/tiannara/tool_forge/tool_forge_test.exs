defmodule Tiannara.ToolForge.ToolForgeTest do
  use ExUnit.Case, async: true

  alias Tiannara.ToolForge.{NeedDetector, ToolArchitect, ToolBuilder}
  alias Tiannara.ToolForge.Domain.{ToolNeed, ToolSpecification, GeneratedTool}

  describe "NeedDetector" do
    test "detects needs from bottlenecks" do
      state = %{
        bottlenecks: [
          %{description: "Slow data processing", solvable_by_tool: true, capability_needed: "parallel_processing", impact: 0.8}
        ],
        discovery_gaps: [],
        replaceable_components: [],
        degraded_services: []
      }

      needs = NeedDetector.detect(state)
      assert length(needs) >= 1
      assert hd(needs).source == :bottleneck_detector
    end

    test "creates need from human request" do
      need = NeedDetector.from_human_request("Build a data visualization tool", %{
        capability: "visualization",
        priority: :high
      })

      assert need.source == :human_request
      assert need.priority == :high
    end

    test "returns empty for healthy system" do
      state = %{bottlenecks: [], discovery_gaps: [], replaceable_components: [], degraded_services: []}
      assert NeedDetector.detect(state) == []
    end
  end

  describe "ToolArchitect" do
    test "designs an Elixir tool for internal needs" do
      need = ToolNeed.new(%{
        source: :bottleneck_detector,
        description: "Need parallel processing",
        capability_gap: "parallel_processing",
        constraints: %{internal: true},
        priority: :high
      })

      spec = ToolArchitect.design(need)

      assert spec.language == :elixir
      assert spec.architecture.pattern == :genserver
      assert length(spec.interfaces) >= 3
      assert spec.verification_plan != nil
    end

    test "designs a Python tool for API needs" do
      need = ToolNeed.new(%{
        source: :human_request,
        description: "Build a REST API for user management",
        capability_gap: "API for user management"
      })

      spec = ToolArchitect.design(need)
      assert spec.language == :python
      assert spec.architecture.pattern == :fastapi_service
    end

    test "generates alternative architectures" do
      need = ToolNeed.new(%{
        source: :bottleneck_detector,
        description: "Need data processing tool",
        capability_gap: "data_processing"
      })

      alternatives = ToolArchitect.design_alternatives(need, 3)
      assert length(alternatives) == 3

      languages = Enum.map(alternatives, & &1.language)
      assert :elixir in languages
      assert :python in languages
    end
  end

  describe "ToolBuilder" do
    setup do
      case Tiannara.ToolForge.ToolBuilder.start_link([]) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
      end
      :ok
    end

    test "builds an Elixir tool from specification" do
      need = ToolNeed.new(%{
        source: :human_request,
        description: "Build a caching tool",
        capability_gap: "caching",
        constraints: %{internal: true}
      })

      spec = ToolArchitect.design(need)
      {:ok, tool} = Tiannara.ToolForge.ToolBuilder.build(spec)

      assert is_struct(tool, GeneratedTool)
      assert tool.language == :elixir
      assert map_size(tool.source_files) >= 1
      assert map_size(tool.test_files) >= 1
      assert tool.entry_point != nil

      main_file = tool.source_files |> Map.values() |> hd()
      assert String.contains?(main_file, "defmodule")
      assert String.contains?(main_file, "GenServer")
      assert String.contains?(main_file, "def execute")
      assert String.contains?(main_file, "def health")
    end

    test "builds a Python tool from specification" do
      need = ToolNeed.new(%{
        source: :human_request,
        description: "Build a REST API",
        capability_gap: "API"
      })

      spec = ToolArchitect.design(need)
      {:ok, tool} = Tiannara.ToolForge.ToolBuilder.build(spec)

      assert tool.language == :python
      assert Map.has_key?(tool.source_files, "main.py")
      assert Map.has_key?(tool.source_files, "requirements.txt")
      assert Map.has_key?(tool.source_files, "Dockerfile")

      main_py = tool.source_files["main.py"]
      assert String.contains?(main_py, "FastAPI")
      assert String.contains?(main_py, "/health")
      assert String.contains?(main_py, "/execute")
    end
  end

  describe "ToolForgeEngine integration" do
    setup do
      case Tiannara.ToolForge.ToolForgeEngine.start_link([]) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
      end
      :ok
    end

    test "engineers a tool from a need" do
      need = ToolNeed.new(%{
        source: :human_request,
        description: "Build a test tool",
        capability_gap: "testing_helper",
        constraints: %{internal: true}
      })

      {:ok, tool} = Tiannara.ToolForge.ToolForgeEngine.engineer_tool(need)
      assert is_struct(tool, GeneratedTool)
      assert String.starts_with?(tool.name, "tool_")
    end

    test "detect_and_engineer returns :no_needs_detected for empty state" do
      result = Tiannara.ToolForge.ToolForgeEngine.detect_and_engineer(%{
        bottlenecks: [],
        discovery_gaps: [],
        replaceable_components: [],
        degraded_services: []
      })
      assert result == {:ok, :no_needs_detected}
    end

    test "stats are tracked" do
      stats = Tiannara.ToolForge.ToolForgeEngine.stats()
      assert is_map(stats)
      assert Map.has_key?(stats, :tools_built)
      assert Map.has_key?(stats, :tools_failed)
    end
  end
end
