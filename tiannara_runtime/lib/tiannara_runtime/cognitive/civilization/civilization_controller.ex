defmodule TiannaraRuntime.Cognitive.Civilization.CivilizationController do
  def initialize(name, config) do
    id = "civ_#{:erlang.unique_integer([:positive])}"
    civilization = %{
      id: id,
      name: name,
      institutions: [],
      programs: [],
      portfolios: [],
      economy: %{},
      collaborations: [],
      knowledge_graph: %{},
      status: :initialized,
      created_at: :erlang.unique_integer([:positive])
    }
    {:ok, civilization}
  end

  def register_institution(civilization, institution) do
    institutions = Map.get(civilization, :institutions) ++ [institution]
    {:ok, Map.put(civilization, :institutions, institutions)}
  end

  def register_program(civilization, program) do
    programs = Map.get(civilization, :programs) ++ [program]
    {:ok, Map.put(civilization, :programs, programs)}
  end

  def register_portfolio(civilization, portfolio) do
    portfolios = Map.get(civilization, :portfolios) ++ [portfolio]
    {:ok, Map.put(civilization, :portfolios, portfolios)}
  end

  def add_collaboration(civilization, collab) do
    collaborations = Map.get(civilization, :collaborations) ++ [collab]
    {:ok, Map.put(civilization, :collaborations, collaborations)}
  end

  def get_status(civilization) do
    {:ok, Map.get(civilization, :status)}
  end

  def summarize(civilization) do
    economy = Map.get(civilization, :economy)
    total_discoveries = Map.get(economy, :discoveries_count, 0) + Map.get(economy, :proofs_count, 0) + Map.get(economy, :datasets_count, 0) + Map.get(economy, :software_count, 0)
    summary = %{
      institutions_count: length(Map.get(civilization, :institutions)),
      programs_count: length(Map.get(civilization, :programs)),
      portfolios_count: length(Map.get(civilization, :portfolios)),
      collaborations_count: length(Map.get(civilization, :collaborations)),
      total_discoveries: total_discoveries
    }
    {:ok, summary}
  end
end
