defmodule Tiannara.RealityGraph do
  @moduledoc """
  Reality Graph Facade.

  Replaces the previous stub implementation. Maintains backward compatibility
  with existing Agency and OS calls, but routes them to the canonical
  UnifiedRealityGraph with enriched constitutional metadata.

  Constitutional Alignment:
    - "Independent replacement": Subsystems don't need to know the underlying graph changed.
    - "Preserve lineage": Automatically infers memory stage and logs the ingestion.
  """
  require Logger

  alias Tiannara.Graph.UnifiedRealityGraph

  @doc """
  Adds a knowledge record to the reality graph.

  Infers the memory stage from the record type, defaulting to :information
  if not explicitly specified.
  """
  def add_node(type, record) when is_atom(type) do
    stage = infer_memory_stage(type, record)
    node_id = Map.get(record, :id, "#{type}_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}")

    case UnifiedRealityGraph.add_node(node_id, stage, record) do
      {:ok, id} ->
        Logger.info("RealityGraph: Ingested #{type} as #{stage} (id: #{id})")
        :ok

      {:error, reason} ->
        Logger.error("RealityGraph: Failed to ingest #{type}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Links two records in the reality graph.
  """
  def add_edge(from_id, to_id, relationship, metadata \\ %{}) do
    UnifiedRealityGraph.add_edge(from_id, to_id, relationship, metadata)
  end

  @doc """
  Queries the graph for a specific node and its context.
  """
  def get_node(node_id) do
    UnifiedRealityGraph.get_node_with_context(node_id)
  end

  defp infer_memory_stage(type, record) do
    cond do
      type == :raw_observation or type == :telemetry -> :data
      type == :hypothesis or type == :prediction -> :information
      type == :experiment_result or type == :validated_discovery -> :knowledge
      type == :pattern or type == :trend -> :pattern
      type == :model or type == :simulation -> :model
      type == :principle or type == :law -> :principle
      Map.has_key?(record, :stage) -> record.stage
      true -> :information
    end
  end

  def find_causal_paths(source, observation) do
    Logger.debug("[RealityGraph] find_causal_paths(#{inspect(source)}, #{inspect(observation)})")

    if Code.ensure_loaded?(Tiannara.Sentinel.CausalIntelligence) do
      try do
        result = apply(Tiannara.Sentinel.CausalIntelligence, :trace_root_causes, [to_string(observation)])
        Enum.map(result, fn pathway ->
          root = List.first(pathway.path)
          %{
            root_cause: if(root, do: elem(root, 0), else: "unknown"),
            confidence: pathway.average_confidence,
            path: Enum.map(pathway.path, fn {id, _w, _c} -> id end)
          }
        end)
      rescue
        _ -> default_causal_path(source)
      end
    else
      default_causal_path(source)
    end
  end

  defp default_causal_path(source) do
    [
      %{
        root_cause: "Causal analysis pending for #{source}",
        confidence: 0.3,
        path: [source, :causal_analysis_pending]
      }
    ]
  end
end
