defmodule Tiannara.REA.OrbitGatewayDetector do
  @moduledoc """
  Detects bottlenecks, intermediate states, and forbidden boundaries.
  Classifies gateways based on betweenness centrality gateway scores.
  """

  alias Tiannara.REA.OrbitReachabilityNode
  alias Tiannara.REA.OrbitReachabilityEdge

  @doc """
  Classifies gateway nodes based on their gateway centrality score:
  - hard_gateway: score >= 0.8
  - soft_gateway: 0.4 <= score < 0.8
  - optional_gateway: score < 0.4
  """
  def classify_gateway(%OrbitReachabilityNode{gateway_score: score}) do
    cond do
      score >= 0.8 -> :hard_gateway
      score >= 0.4 -> :soft_gateway
      true -> :optional_gateway
    end
  end

  @doc """
  Identifies forbidden transitions (edges with extremely low transition probability, e.g. < 0.015).
  """
  def detect_forbidden_transitions(edges) do
    Enum.filter(edges, fn %OrbitReachabilityEdge{transition_probability: prob} ->
      prob < 0.015
    end)
  end

  @doc """
  Identifies bottleneck states on a path. A state is a bottleneck if its gateway score is high
  and it lies on the primary paths.
  """
  def detect_bottlenecks(nodes) do
    Enum.filter(nodes, fn node ->
      classify_gateway(node) in [:hard_gateway, :soft_gateway]
    end)
  end
end
