defmodule Tiannara.REL.CivilizationFitness do
  @moduledoc """
  Calculates objective civilizational fitness.
  Fitness = 0.30(survival) + 0.25(discoveries) + 0.20(predictive_accuracy) + 0.15(lineage_persistence) + 0.10(resource_efficiency)
  """

  alias Tiannara.REL.EconomyEngine
  alias Tiannara.REL.DiscoveryLedger
  alias Tiannara.OMCS.Engine, as: OMCSEngine

  @doc "Calculate fitness score [0.0, 1.0] for a civilization."
  def calculate(civ_id) do
    survival_score = get_survival_score(civ_id)
    discovery_score = get_discovery_score(civ_id)
    predictive_score = get_predictive_score(civ_id) # Mocked for now, needs WorldModel metrics
    lineage_score = get_lineage_score(civ_id)
    efficiency_score = get_efficiency_score(civ_id)

    fitness = (0.30 * survival_score) +
              (0.25 * discovery_score) +
              (0.20 * predictive_score) +
              (0.15 * lineage_score) +
              (0.10 * efficiency_score)

    max(0.0, min(1.0, fitness))
  end

  defp get_survival_score(civ_id) do
    case EconomyEngine.get_budget(civ_id) do
      nil -> 0.0
      %{state: :dormant} -> 0.0
      %{state: :starving} -> 0.2
      %{state: :active, energy: e} -> min(1.0, e / 2000.0) # Normalizing 2000 energy as 1.0 survival
    end
  end

  defp get_discovery_score(civ_id) do
    discoveries = DiscoveryLedger.get_known_discoveries(civ_id)
    # 5 discoveries of moderate complexity might yield 1.0
    count_score = min(1.0, length(discoveries) / 10.0)
    count_score
  end

  defp get_predictive_score(_civ_id) do
    state =
      case Process.whereis(TiannaraOS.CivilizationKernel) do
        nil -> nil
        pid ->
          if Process.alive?(pid) do
            TiannaraOS.CivilizationKernel.get_state()
          else
            nil
          end
      end

    if state do
      theories = Enum.filter(Map.values(state.evidence_graph), &(&1.type == :theory))
      evidences = Enum.filter(Map.values(state.evidence_graph), &(&1.type == :evidence))

      if length(theories) > 0 and length(evidences) > 0 do
        avg_theory = Enum.sum(Enum.map(theories, &(&1.value || 0.5))) / length(theories)
        avg_evidence = Enum.sum(Enum.map(evidences, &(&1.value || 0.5))) / length(evidences)
        error = abs(avg_theory - avg_evidence)
        1.0 - error
      else
        0.5
      end
    else
      0.5
    end
  end

  defp get_lineage_score(civ_id) do
    # How many children / fissions / migrations?
    # Query OMCS for out-edges
    try do
      graph = :sys.get_state(Tiannara.OMCS.Engine).graph
      out_edges = Graph.out_edges(graph, civ_id)
      min(1.0, length(out_edges) / 5.0)
    catch
      _, _ -> 0.0
    end
  end

  defp get_efficiency_score(civ_id) do
    case EconomyEngine.get_budget(civ_id) do
      nil -> 0.0
      %{energy: e, ontological_capital: oc} ->
        if oc == 0, do: 0.5, else: min(1.0, e / (oc * 10.0))
    end
  end
end
