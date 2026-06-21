defmodule Tiannara.ASC.Engineering.ProjectSynthesizer do
  @moduledoc """
  Phase 8A: Translates high-fitness Research Genomes into actionable 
  Engineering Projects. This is the bridge between pure science and applied engineering.
  """
  
  alias Tiannara.ASC.MetaScience.ResearchGenome
  alias Tiannara.ASC.Engineering.EngineeringProject
  require Logger

  def synthesize(%ResearchGenome{} = genome) do
    # Domain is dynamically retrieved based on what the genome focuses on
    domain = get_primary_domain(genome)
    methodology = get_primary_methodology(genome)
    project_name = generate_project_name(domain, methodology)
    
    spec = %{
      domain: domain,
      methodology: methodology,
      architectural_pattern: select_architecture(domain, methodology, genome),
      risk_tolerance: genome.exploration_bias,
      optimization_target: if(genome.exploitation_bias > 0.6, do: :efficiency, else: :resilience)
    }
    
    %EngineeringProject{
      id: "proj_#{:erlang.unique_integer([:positive])}",
      name: project_name,
      source_genome_id: genome.id,
      spec: spec
    }
  end

  defp get_primary_domain(genome) do
    if Enum.empty?(genome.domain_weights) do
      :unknown
    else
      {domain, _weight} = Enum.max_by(genome.domain_weights, fn {_k, v} -> v end)
      domain
    end
  end

  defp get_primary_methodology(genome) do
    if Enum.empty?(genome.methodology_blend) do
      :unknown
    else
      {method, _weight} = Enum.max_by(genome.methodology_blend, fn {_k, v} -> v end)
      method
    end
  end

  defp generate_project_name(domain, methodology) do
    domain_str = Atom.to_string(domain) |> String.replace("_", " ") |> String.capitalize()
    method_str = Atom.to_string(methodology) |> String.replace("_", " ") |> String.capitalize()
    "Autonomous #{domain_str} System via #{method_str}"
  end

  defp select_architecture(domain, methodology, genome) do
    cond do
      domain == :repair_ecology and genome.exploration_bias > 0.7 -> :self_healing_mesh
      domain == :architecture_evolution -> :event_sourced_cqrs
      Atom.to_string(methodology) =~ "hybrid" -> :polyglot_microservices
      true -> :monolithic_modular
    end
  end
end
