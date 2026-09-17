defmodule Tiannara.RRG.Node do
  @moduledoc """
  Ontology Node - Represents units in the Rate-limiting Ontological Graph.
  Each node is an OntologyUnit with type, entropy, confidence, and provenance.
  """

  defstruct [
    :id,
    :type,
    :entropy_score,
    :confidence_weight,
    :causal_depth,
    :provenance_trace,
    :created_at,
    :last_updated
  ]

  @type node_type :: :fact | :model | :observer | :event | :rule

  def new(id, type, opts \\ []) when type in [:fact, :model, :observer, :event, :rule] do
    %__MODULE__{
      id: id,
      type: type,
      entropy_score: Keyword.get(opts, :entropy_score, 0.0),
      confidence_weight: Keyword.get(opts, :confidence_weight, 1.0),
      causal_depth: Keyword.get(opts, :causal_depth, 0),
      provenance_trace: Keyword.get(opts, :provenance_trace, []),
      created_at: Keyword.get(opts, :created_at, System.system_time(:millisecond)),
      last_updated: Keyword.get(opts, :last_updated, System.system_time(:millisecond))
    }
  end

  def update_entropy(node, new_entropy) when is_number(new_entropy) do
    %{node | entropy_score: new_entropy, last_updated: System.system_time(:millisecond)}
  end

  def update_confidence(node, new_confidence) when is_number(new_confidence) do
    %{node | confidence_weight: new_confidence, last_updated: System.system_time(:millisecond)}
  end

  def add_provenance_trace(node, trace_item) do
    updated_trace = [trace_item | node.provenance_trace]
    %{node | provenance_trace: updated_trace, last_updated: System.system_time(:millisecond)}
  end

  def increment_causal_depth(node) do
    %{node | causal_depth: node.causal_depth + 1, last_updated: System.system_time(:millisecond)}
  end

  def is_high_entropy?(node, threshold \\ 0.8) do
    node.entropy_score > threshold
  end

  def is_low_confidence?(node, threshold \\ 0.3) do
    node.confidence_weight < threshold
  end

  def valid_type?(type) do
    type in [:fact, :model, :observer, :event, :rule]
  end
end
