defmodule Tiannara.Principles.Analytics do
  @moduledoc """
  Calculates dynamic influence analytics of universal principles across the Knowledge Graph.
  """
  @derive Jason.Encoder
  defstruct [
    :principle_id,
    :domains_impacted,
    :discoveries_generated,
    :interventions_generated,
    :successful_outcomes,
    :transferability_score,
    :resilience_score
  ]

  alias Tiannara.KnowledgeGraph.Registry, as: KG

  @doc """
  Generates principle analytics for a given principle ID by traversing the knowledge graph.
  """
  def generate(principle_id) do
    nodes = KG.all()
    transfers = 
      try do
        Tiannara.Domains.TransferMatrix.all()
      rescue
        _ -> []
      end

    principle_id_str = to_string(principle_id)
    principle = Enum.find(nodes, &(&1.type == :principle and to_string(&1.id) == principle_id_str))

    if principle do
      # Traverse graph downstream to gather all children recursively
      downstream_nodes = collect_downstream(principle.id, nodes, [])
      
      discoveries = Enum.filter(downstream_nodes, &(&1.type == :discovery))
      interventions = Enum.filter(downstream_nodes, &(&1.type == :intervention))
      outcomes = Enum.filter(downstream_nodes, &(&1.type == :outcome))

      domains = 
        (principle.domains ++ Enum.flat_map(downstream_nodes, & &1.domains))
        |> Enum.uniq()

      # Filter transfers related to discoveries in this principle's subtree
      disc_ids = Enum.map(discoveries, &to_string(&1.id))
      relevant_transfers = Enum.filter(transfers, & (to_string(&1.discovery_id) in disc_ids))

      transferability =
        if Enum.empty?(relevant_transfers) do
          0.80 # default baseline
        else
          Enum.sum(Enum.map(relevant_transfers, & &1.transfer_success)) / Enum.count(relevant_transfers)
        end

      # Calculate resilience score based on outcome gains (e.g. sum of dvr_gain)
      resilience =
        if Enum.empty?(outcomes) do
          0.10 # default baseline
        else
          outcomes
          |> Enum.map(fn o -> (o.metadata[:dvr_gain] || o.metadata["dvr_gain"] || 0.0) end)
          |> Enum.sum()
        end

      %__MODULE__{
        principle_id: principle.id,
        domains_impacted: Enum.count(domains),
        discoveries_generated: Enum.count(discoveries),
        interventions_generated: Enum.count(interventions),
        successful_outcomes: Enum.count(outcomes),
        transferability_score: transferability,
        resilience_score: resilience
      }
    else
      nil
    end
  end

  defp collect_downstream(node_id, all_nodes, visited) do
    node_id_str = to_string(node_id)
    if node_id_str in visited do
      []
    else
      # Check parents of all nodes
      children = Enum.filter(all_nodes, fn n -> 
        parents_str = Enum.map(n.parents || [], &to_string/1)
        node_id_str in parents_str
      end)
      
      new_visited = [node_id_str | visited]
      children ++ Enum.flat_map(children, fn child -> collect_downstream(child.id, all_nodes, new_visited) end)
    end
  end
end
