defmodule TiannaraOS.Provenance.Graph do
  @moduledoc """
  Provenance graph: typed, directed edges over identity objects and envelopes.

  Edge types:
    source->contract       : contract_asserts_source
    contract->execution    : execution_under_contract
    execution->result      : result_derived_from_execution
    result->metric         : metric_computed_from_result   (raw corpus -> derived metric)
    metric->certificate    : certificate_certifies_metric  (via envelope bindings)
    source->certificate    : certificate_depends_on_source (envelope parent chain)

  Immutable accounts: an edge is created once, and the graph records
  verification_status per node. Traversal is deterministic forward/backward.
  """

  alias TiannaraOS.Provenance.Canon

  @edge_types [
    "contract_asserts_source",
    "execution_under_contract",
    "result_derived_from_execution",
    "metric_computed_from_result",
    "certificate_certifies_metric",
    "certificate_depends_on_contract",
    "certificate_depends_on_source",
    "execution_started_by_environment",
    "PARENT_OF"
  ]

  def new, do: %{"nodes" => [], "edges" => [], "verification_statuses" => %{}}

  @doc "Full graph build from a provenance recording (see Demo)."
  def build(opts) do
    source = Keyword.get(opts, :source)
    contract = Keyword.get(opts, :contract)
    execution = Keyword.get(opts, :execution)
    result = Keyword.get(opts, :result)
    metric = Keyword.get(opts, :metric)
    certificate = Keyword.get(opts, :certificate)
    environment = Keyword.get(opts, :environment)

    graph = new()

    graph =
      graph
      |> add_node("source", source["object_hash"], source)
      |> add_node("contract", contract["object_hash"], contract)
      |> add_node("environment", environment["object_hash"], environment)
      |> add_node("execution", execution["execution_id"], execution)
      |> add_node("result", result["result_id"], %{"payload_hash" => result["payload_hash"], "envelope_id" => result["envelope"]["envelope_id"]})
      |> add_node("metric", metric["metric_id"]["object_hash"], metric["value"])
      |> add_node("certificate", certificate["certificate_id"], certificate)

    graph =
      graph
      |> add_edge("source", source["object_hash"], "contract", contract["object_hash"], "contract_asserts_source")
      |> add_edge("contract", contract["object_hash"], "execution", execution["execution_id"], "execution_under_contract")
      |> add_edge("environment", environment["object_hash"], "execution", execution["execution_id"], "execution_started_by_environment")
      |> add_edge("execution", execution["execution_id"], "result", result["result_id"], "result_derived_from_execution")
      |> add_edge("result", result["result_id"], "metric", metric["metric_id"]["object_hash"], "metric_computed_from_result")
      |> add_edge("metric", metric["metric_id"]["object_hash"], "certificate", certificate["certificate_id"], "certificate_certifies_metric")

    %{graph | "nodes" => Enum.uniq(graph["nodes"])}
  end

  def add_node(graph, kind, id, payload) do
    node = %{"kind" => kind, "id" => id, "payload" => payload, "verification_status" => "unverified"}
    %{graph | "nodes" => [node | graph["nodes"]]}
  end

  def add_edge(graph, src_kind, src_id, dst_kind, dst_id, type) when type in @edge_types do
    edge = %{
      "from" => %{"kind" => src_kind, "id" => src_id},
      "to" => %{"kind" => dst_kind, "id" => dst_id},
      "type" => type
    }
    %{graph | "edges" => [edge | graph["edges"]]}
  end

  def node_ids_needed_from(graph, parent_kind, parent_id, dst_kind) do
    graph["edges"]
    |> Enum.filter(fn e ->
      e["from"]["kind"] == parent_kind && e["from"]["id"] == parent_id && e["to"]["kind"] == dst_kind
    end)
    |> Enum.map(fn e -> e["to"]["id"] end)
  end

  def mark_verified(graph, kind, id) do
    %{graph | "verification_statuses" => Map.put(graph["verification_statuses"], {kind, id}, "verified")}
  end

  def to_json(graph), do: Canon.canon(graph)
end