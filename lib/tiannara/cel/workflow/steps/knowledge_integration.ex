defmodule Tiannara.CEL.Workflow.Steps.KnowledgeIntegration do
  @moduledoc """
  Knowledge Integration step — integrates validated knowledge into the world model.
  This is where memory evolves from Information -> Knowledge -> Patterns.
  """
  @behaviour Tiannara.CEL.Workflow.Step

  alias Tiannara.Graph.UnifiedRealityGraph

  @impl true
  def step_type, do: :knowledge_integration

  @impl true
  def required_capability, do: :knowledge_integration

  @impl true
  def validate_input(input) do
    cond do
      not Map.has_key?(input, :validated_knowledge) -> {:error, :missing_knowledge}
      not Map.has_key?(input, :target_domain) -> {:error, :missing_domain}
      true -> :ok
    end
  end

  @impl true
  def execute(input, _context) do
    start_time = System.monotonic_time(:millisecond)

    {:ok, node_id} = UnifiedRealityGraph.add_node(
      "knowledge_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}",
      :knowledge,
      input.validated_knowledge
    )

    if Map.has_key?(input, :related_knowledge_ids) do
      Enum.each(input.related_knowledge_ids, fn related_id ->
        UnifiedRealityGraph.add_edge(node_id, related_id, :related_to)
      end)
    end

    duration = System.monotonic_time(:millisecond) - start_time

    {:ok, %{
      integrated_node_id: node_id,
      domain: input.target_domain,
      evidence: [%{type: :knowledge_integration, node_id: node_id}],
      confidence: 0.95,
      quality_metrics: %{integration_completeness: 1.0},
      resource_usage: %{compute: 20, memory: 50},
      duration_ms: duration
    }}
  end

  @impl true
  def compensate(_input, _result, _context), do: :ok

  @impl true
  def metadata, do: %{description: "Integrates validated knowledge into the world model"}
end
