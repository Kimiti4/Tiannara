defmodule TiannaraRuntime.Cognitive.Civilization.InstitutionManager do
  def create(civilization_id, name, domain) do
    institution = %{
      id: "inst_#{:erlang.unique_integer([:positive])}",
      civilization_id: civilization_id,
      name: name,
      domain: domain,
      programs: [],
      resources: %{budget: 1000, researchers: 0, equipment: []},
      metrics: %{productivity: 0.0, impact: 0.0, maturity: 0.0},
      status: :active
    }
    {:ok, institution}
  end

  def add_program(institution, program) do
    programs = Map.get(institution, :programs) ++ [program]
    {:ok, Map.put(institution, :programs, programs)}
  end

  def update_metrics(institution, metrics) do
    current = Map.get(institution, :metrics)
    updated_metrics = Map.merge(current, metrics)
    {:ok, Map.put(institution, :metrics, updated_metrics)}
  end

  def get_programs(institution) do
    {:ok, Map.get(institution, :programs)}
  end

  def summarize(institution) do
    summary = %{
      name: Map.get(institution, :name),
      domain: Map.get(institution, :domain),
      program_count: length(Map.get(institution, :programs)),
      status: Map.get(institution, :status),
      metrics: Map.get(institution, :metrics)
    }
    {:ok, summary}
  end
end
