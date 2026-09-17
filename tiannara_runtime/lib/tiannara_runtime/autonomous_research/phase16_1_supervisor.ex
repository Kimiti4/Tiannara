defmodule TiannaraRuntime.AutonomousResearch.Phase16_1.Supervisor do
  @moduledoc """
  Phase 16.1 — Autonomous Constitutional Research Runtime Supervisor
  """

  @doc "Initialize all Phase 16.1 tables"
  def init_all_tables do
    init_ets(:observation_registry)
    init_ets(:knowledge_gaps)
    init_ets(:research_questions)
    init_ets(:research_priorities)
    init_ets(:question_archive)
    init_ets(:hypotheses)
    init_ets(:experiments)
    init_ets(:theories)
    init_ets(:research_programs)
    init_ets(:kg_nodes)
    init_ets(:kg_edges)
    init_ets(:discovery_lineage)
    init_ets(:scientific_capital)
    init_ets(:archaeology_records)
    :ok
  end

  defp init_ets(name) when is_atom(name) do
    if :ets.info(name) == :undefined do
      :ets.new(name, [:set, :public, :named_table])
    end
  end
end