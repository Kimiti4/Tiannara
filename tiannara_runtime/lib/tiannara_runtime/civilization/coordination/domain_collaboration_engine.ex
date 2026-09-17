defmodule TiannaraRuntime.Civilization.Coordination.DomainCollaborationEngine do
  def initialize(domains) do
    {:ok, %{domains: domains, collaboration_graph: %{}, proposals: []}}
  end

  def propose(engine, source, target, reason) do
    proposal = %{id: :erlang.unique_integer([:positive]), source: source, target: target, reason: reason, status: :proposed}
    {:ok, %{engine | proposals: engine.proposals ++ [proposal]}}
  end

  def activate(engine, proposal_id) do
    proposal = Enum.find(engine.proposals, fn p -> Map.get(p, :id) == proposal_id end)
    case proposal do
      nil -> {:ok, engine}
      p ->
        edge_key = "#{Map.get(p, :source)}-#{Map.get(p, :target)}"
        graph = Map.put(engine.collaboration_graph, edge_key, p)
        {:ok, %{engine | collaboration_graph: graph}}
    end
  end

  def find_potential(engine) do
    pairs = for a <- engine.domains, b <- engine.domains, a != b do
      %{source: a, target: b, reason: "cross-domain potential"}
    end
    {:ok, pairs}
  end

  def metrics(engine) do
    {:ok, %{edges: map_size(engine.collaboration_graph), proposals: length(engine.proposals)}}
  end
end
