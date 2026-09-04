defmodule Tiannara.World.CanonicalWorldState do
  @moduledoc """
  Canonical World State Schema — the explicit data model of Tiannara's reality.

  Defines what "reality" contains: the domains, entity types, memory stages,
  and validation rules that every entity must conform to.
  """

  @domains [
    :environment,
    :resources,
    :knowledge,
    :agents,
    :civilizations,
    :experiments,
    :missions,
    :capabilities,
    :constraints,
    :observations,
    :predictions,
    :unknowns
  ]

  @doc "Returns the list of canonical domains."
  def domains, do: @domains

  @domain_entity_types %{
    environment: [:physical_object, :location, :ecosystem, :climate_state, :natural_resource],
    resources: [:compute, :memory, :energy, :budget, :material, :bandwidth, :lab_time],
    knowledge: [:fact, :evidence, :hypothesis, :theory, :principle, :discovery, :pattern, :model, :unknown],
    agents: [:human, :ai_system, :subsystem, :organization, :team],
    civilizations: [:society, :institution, :culture, :governance_structure],
    experiments: [:hypothesis_test, :simulation_run, :validation_trial, :replication_attempt],
    missions: [:mission, :program, :objective, :workflow, :task, :outcome],
    capabilities: [:service, :tool, :skill, :competency, :api],
    constraints: [:policy, :constitutional_rule, :invariant, :regulation, :quota],
    observations: [:measurement, :sensor_reading, :telemetry, :raw_data],
    predictions: [:forecast, :simulation_output, :counterfactual, :risk_estimate],
    unknowns: [:knowledge_gap, :unresolved_question, :missing_evidence, :contradiction]
  }

  @doc "Returns the full map of domain -> entity types."
  def domain_entity_types, do: @domain_entity_types

  @doc "Returns the canonical entity types for a given domain."
  def entity_types_for(domain) do
    Map.get(@domain_entity_types, domain, [])
  end

  @memory_stages [
    :data,
    :information,
    :knowledge,
    :pattern,
    :model,
    :principle,
    :generalized_understanding,
    :engineering_insight,
    :scientific_discovery
  ]

  @doc "Returns the canonical memory evolution stages."
  def memory_stages, do: @memory_stages

  @doc "Returns the next stage in the memory evolution chain."
  def next_stage(current_stage) do
    case Enum.find_index(@memory_stages, &(&1 == current_stage)) do
      nil -> nil
      idx when idx >= length(@memory_stages) - 1 -> nil
      idx -> Enum.at(@memory_stages, idx + 1)
    end
  end

  @doc "Returns the fields that every entity must have."
  def required_entity_fields do
    [
      :id, :domain, :type, :confidence, :uncertainty,
      :provenance, :owner_subsystem, :version,
      :created_at, :updated_at, :status
    ]
  end

  @doc "Validates an entity spec against the canonical schema."
  def validate_entity(spec) do
    with :ok <- validate_required_fields(spec),
         :ok <- validate_domain(spec.domain),
         :ok <- validate_entity_type(spec.domain, spec.type),
         :ok <- validate_confidence_uncertainty(spec),
         :ok <- validate_provenance(spec) do
      :ok
    end
  end

  defp validate_required_fields(spec) do
    missing = required_entity_fields() |> Enum.reject(&Map.has_key?(spec, &1))
    if missing == [], do: :ok, else: {:error, {:missing_fields, missing}}
  end

  defp validate_domain(domain) do
    if domain in @domains, do: :ok, else: {:error, {:invalid_domain, domain}}
  end

  defp validate_entity_type(domain, type) do
    valid_types = entity_types_for(domain)
    if type in valid_types, do: :ok, else: {:error, {:invalid_entity_type, domain, type}}
  end

  defp validate_confidence_uncertainty(spec) do
    conf = Map.get(spec, :confidence, 0.5)
    unc = Map.get(spec, :uncertainty, 0.5)

    cond do
      conf < 0.0 or conf > 1.0 -> {:error, :confidence_out_of_range}
      unc < 0.0 or unc > 1.0 -> {:error, :uncertainty_out_of_range}
      abs(conf + unc - 1.0) > 0.01 -> {:error, :confidence_uncertainty_mismatch}
      true -> :ok
    end
  end

  defp validate_provenance(spec) do
    prov = Map.get(spec, :provenance)

    cond do
      is_nil(prov) -> {:error, :missing_provenance}
      not is_map(prov) -> {:error, :invalid_provenance}
      not Map.has_key?(prov, :origin) -> {:error, {:missing_provenance_field, :origin}}
      not Map.has_key?(prov, :produced_by) -> {:error, {:missing_provenance_field, :produced_by}}
      not Map.has_key?(prov, :produced_at) -> {:error, {:missing_provenance_field, :produced_at}}
      true -> :ok
    end
  end
end
