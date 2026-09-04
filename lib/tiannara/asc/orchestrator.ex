defmodule Tiannara.ASC.Orchestrator do
  @moduledoc """
  Orchestrates the full civilizational pipeline:

    Discovery → Validation → Knowledge Asset → Capability Formation →
    Institution → Scientific Ecosystem → Civilizational Improvement

  Integrates with Sentinel (oversight), REA (evolution), and MetaGovernor (governance).
  """

  @doc """
  Processes a new discovery through the full civilizational pipeline.
  Returns a civilizational report for human review.
  """
  def process_discovery(discovery) do
    {:ok, knowledge_asset} = Tiannara.ASC.KnowledgeEconomy.ingest_discovery(
      :asc_knowledge_economy, discovery)

    evidence = Tiannara.Sentinel.Activation.CRAVController.validate_discovery(discovery)
    {:ok, validated_asset} = Tiannara.ASC.KnowledgeEconomy.validate_asset(
      :asc_knowledge_economy, knowledge_asset.id, evidence)

    {:ok, capability} = Tiannara.ASC.CapabilityEvolution.propose_capability(
      :asc_capability_evolution, %{
        name: "Capability derived from #{discovery.id}",
        domain: discovery.domain,
        innovation: 0.8, efficiency: 0.75, scalability: 0.7,
        civilizational_value: 0.85, cost: 0.4
      })

    Tiannara.ASC.CivilizationMemory.preserve(:asc_civilization_memory, %{
      type: :discovery, id: discovery.id, domain: discovery.domain,
      content: discovery.content, capability_id: capability.id
    })

    institution = if capability.fitness > 0.7 do
      {:ok, inst} = Tiannara.ASC.InstitutionEngine.propose_institution(
        :asc_institution_engine, %{
          name: "#{discovery.domain |> Atom.to_string() |> String.capitalize()} Institute",
          civilization_id: get_civilization_id(discovery.domain),
          purpose: "Steward #{discovery.domain} capabilities",
          capabilities: [capability.id],
          knowledge: [validated_asset.id],
          founding_discovery_id: discovery.id
        })
      {:ok, evaluated} = Tiannara.ASC.InstitutionEngine.evaluate_institution(
        :asc_institution_engine, inst.id)
      evaluated
    else
      nil
    end

    Tiannara.Sentinel.Activation.Dialogue.initiate(%{
      id: discovery.id, category: :scientific,
      observation: "Civilizational evolution: new capability #{capability.name}",
      interpretation: "Knowledge compounded into capability#{if institution, do: " and institution", else: ""}",
      confidence: capability.fitness, requires_human: true
    }, [])

    %{
      discovery_id: discovery.id,
      knowledge_asset: validated_asset,
      capability: capability,
      institution: institution,
      civilization_id: get_civilization_id(discovery.domain),
      metrics: Tiannara.ASC.CivilizationMetrics.measure(:asc_civilization_metrics)
    }
  end

  defp get_civilization_id(domain) do
    case Tiannara.ASC.CivilizationManager.get_civilization(:asc_civilization_manager, domain) do
      nil -> UUID.uuid4()
      civ -> civ.id
    end
  end
end
