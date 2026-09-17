defmodule TiannaraRuntime.Cognitive.Civilization.CollaborationEngine do
  def propose(civilization_id, source_inst, target_inst, domain_bridge) do
    collaboration = %{
      id: "col_#{:erlang.unique_integer([:positive])}",
      civilization_id: civilization_id,
      source_institution: source_inst,
      target_institution: target_inst,
      domain_bridge: domain_bridge,
      programs: [],
      status: :proposed,
      created_at: :erlang.unique_integer([:positive])
    }
    {:ok, collaboration}
  end

  def activate(collaboration) do
    {:ok, Map.put(collaboration, :status, :active)}
  end

  def complete(collaboration) do
    {:ok, Map.put(collaboration, :status, :completed)}
  end

  def find_potential(institutions) do
    pairs = for a <- institutions, b <- institutions, a != b, Map.get(a, :domain) != Map.get(b, :domain) do
      %{
        source: Map.get(a, :id),
        target: Map.get(b, :id),
        domain_bridge: "#{Map.get(a, :domain)}-#{Map.get(b, :domain)}"
      }
    end
    proposed = Enum.map(pairs, fn pair ->
      {:ok, collab} = propose(nil, Map.get(pair, :source), Map.get(pair, :target), Map.get(pair, :domain_bridge))
      collab
    end)
    {:ok, proposed}
  end

  def summarize(collaboration) do
    summary = %{
      source: Map.get(collaboration, :source_institution),
      target: Map.get(collaboration, :target_institution),
      domain_bridge: Map.get(collaboration, :domain_bridge),
      status: Map.get(collaboration, :status)
    }
    {:ok, summary}
  end
end
