defmodule Tiannara.ToolForge.NeedDetector do
  alias Tiannara.ToolForge.Domain.ToolNeed

  @spec detect(map()) :: [ToolNeed.t()]
  def detect(system_state) when is_map(system_state) do
    []
    |> detect_from_bottlenecks(system_state)
    |> detect_from_discovery_gaps(system_state)
    |> detect_from_self_evaluation(system_state)
    |> detect_from_degradation(system_state)
    |> rank_by_priority()
  end

  @spec from_human_request(String.t(), map()) :: ToolNeed.t()
  def from_human_request(description, opts \\ %{}) do
    ToolNeed.new(%{
      source: :human_request,
      description: description,
      capability_gap: Map.get(opts, :capability, "unspecified"),
      required_interfaces: Map.get(opts, :interfaces, []),
      constraints: Map.get(opts, :constraints, %{}),
      priority: Map.get(opts, :priority, :medium),
      estimated_impact: Map.get(opts, :impact, 0.5)
    })
  end

  defp detect_from_bottlenecks(needs, system_state) do
    bottlenecks = Map.get(system_state, :bottlenecks, [])
    tool_needs =
      Enum.filter(bottlenecks, fn b -> Map.get(b, :solvable_by_tool, false) end)
      |> Enum.map(fn b ->
        ToolNeed.new(%{
          source: :bottleneck_detector,
          description: "Bottleneck: #{Map.get(b, :description, "unknown")}",
          capability_gap: Map.get(b, :capability_needed, "unspecified"),
          priority: :high,
          estimated_impact: Map.get(b, :impact, 0.7)
        })
      end)
    needs ++ tool_needs
  end

  defp detect_from_discovery_gaps(needs, system_state) do
    gaps = Map.get(system_state, :discovery_gaps, [])
    tool_needs =
      Enum.filter(gaps, fn g -> Map.get(g, :requires_tool, false) end)
      |> Enum.map(fn g ->
        ToolNeed.new(%{
          source: :discovery_engine,
          description: "Discovery gap requires tool: #{Map.get(g, :description, "unknown")}",
          capability_gap: Map.get(g, :tool_capability, "unspecified"),
          priority: Map.get(g, :severity, :medium),
          estimated_impact: Map.get(g, :estimated_impact, 0.5)
        })
      end)
    needs ++ tool_needs
  end

  defp detect_from_self_evaluation(needs, system_state) do
    replaceable = Map.get(system_state, :replaceable_components, [])
    tool_needs =
      Enum.map(replaceable, fn comp ->
        ToolNeed.new(%{
          source: :self_evaluation,
          description: "Self-evaluation: #{comp} could be replaced by a better tool",
          capability_gap: "Replace #{comp} with improved implementation",
          priority: :low,
          estimated_impact: 0.4
        })
      end)
    needs ++ tool_needs
  end

  defp detect_from_degradation(needs, system_state) do
    degraded = Map.get(system_state, :degraded_services, [])
    tool_needs =
      Enum.map(degraded, fn svc ->
        ToolNeed.new(%{
          source: :self_evaluation,
          description: "Service #{svc} is degraded; needs tooling improvement",
          capability_gap: "Improve #{svc} performance/reliability",
          priority: :high,
          estimated_impact: 0.6
        })
      end)
    needs ++ tool_needs
  end

  defp rank_by_priority(needs) do
    priority_weight = %{critical: 4, high: 3, medium: 2, low: 1}
    Enum.sort_by(needs, fn need ->
      Map.get(priority_weight, need.priority, 0) * need.estimated_impact
    end, :desc)
  end
end
