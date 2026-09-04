defmodule TiannaraOS.DomainProfile do
  @moduledoc """
  Domain-Specific Institutional Configuration Profiles.
  
  This module defines the schema and loading mechanism for domain profiles
  that customize institutional behavior without modifying constitutional infrastructure.
  
  ## Constitutional Properties
  
  - Profiles are configuration, not architecture
  - All institutions execute identical ResearchCycleResult flow
  - Domain differences only in thresholds, policies, ontologies
  - Same constitutional services composed identically across domains
  - Inter-institution exchange works regardless of domain profile
  
  ## Profile Schema
  
  Each domain profile defines:
  
  ```yaml
  institution:
    domain: Medicine
    mission: "Advance medical science through evidence-based research"
    
  research_style:
    hypothesis_generation: conservative  # or exploratory, balanced
    evidence_threshold: 0.90            # minimum confidence for publication
    replication_required: true          # require independent replication
    risk_tolerance: low                 # low, medium, high
    
  tools:
    - simulation
    - literature_review
    - clinical_trial
    - statistical_analysis
    
  ontology:
    knowledge_graph: :medical_ontology
    vocabulary: [:icd10, :snomed_ct, :umls]
    
  publication_policy:
    peer_review_required: true
    minimum_confidence: 0.85
    defer_on_contradiction: true
    
  economic_model:
    experiment_cost_multiplier: 2.5
    replication_budget_factor: 1.5
    publication_value: 50.0
    
  governance:
    approval_threshold: 0.80
    ethical_review_required: true
    safety_constraints: [:patient_safety, :data_privacy]
  ```
  
  ## Usage
  
  Load profile:
  ```elixir
  profile = DomainProfile.load(:medicine)
  ```
  
  Apply to institution:
  ```elixir
  institution = DomainProfile.apply(institution, profile)
  ```
  
  Get domain-specific threshold:
  ```elixir
  threshold = DomainProfile.evidence_threshold(profile)
  ```
  """
  
  require Logger
  
  # ==================== Public API ====================
  
  @doc """
  Load a domain profile by domain name.
  
  Returns a structured profile map with all configuration parameters.
  """
  def load(domain_name) when is_atom(domain_name) do
    Logger.info("[DomainProfile] Loading profile for domain: #{domain_name}")
    
    profile = case domain_name do
      :engineering -> engineering_profile()
      :medicine -> medicine_profile()
      :governance -> governance_profile()
      :computation -> computation_profile()
      :agriculture -> agriculture_profile()
      :energy -> energy_profile()
      :logistics -> logistics_profile()
      :cognition -> cognition_profile()
      :materials -> materials_profile()
      :robotics -> robotics_profile()
      :economics -> economics_profile()
      :philosophy -> philosophy_profile()
      :sociology -> sociology_profile()
      :linguistics -> linguistics_profile()
      :aerospace -> aerospace_profile()
      :ecology -> ecology_profile()
      :cybernetics -> cybernetics_profile()
      :architecture -> architecture_profile()
      _ -> default_profile(domain_name)
    end
    
    Logger.info("[DomainProfile] ✓ Loaded profile for #{domain_name}")
    {:ok, profile}
  end
  
  @doc """
  Apply a domain profile to an institution state.
  
  Configures the institution's behavioral parameters while preserving
  constitutional infrastructure.
  """
  def apply(institution, {:ok, profile}) do
    Logger.info("[DomainProfile] Applying profile to institution: #{institution.id}")
    
    # Update institution constitution and identity with domain-specific configuration
    updated_constitution = %{institution.constitution |
      mission: profile.institution.mission,
      research_rules: %{institution.constitution.research_rules |
        validation_standards: case profile.research_style.hypothesis_generation do
          :conservative -> :rigorous
          :exploratory -> :flexible
          _ -> :balanced
        end,
        replication_requirements: if(profile.research_style.replication_required, do: 2, else: 1),
        evidence_thresholds: %{
          minimum_confidence: profile.research_style.evidence_threshold
        }
      },
      publication_rules: %{institution.constitution.publication_rules |
        peer_review_required: profile.publication_policy.peer_review_required
      },
      governance_rules: %{institution.constitution.governance_rules |
        voting_threshold: profile.governance.approval_threshold
      }
    }
    
    updated_identity = %{institution.identity |
      mission: profile.institution.mission,
      research_philosophy: profile.research_style.hypothesis_generation,
      core_competencies: profile.tools,
      scientific_domain_vector: %{profile.institution.domain => 1.0}
    }
    
    updated_institution = %{institution |
      constitution: updated_constitution,
      identity: updated_identity,
      domain_profile: profile
    }
    
    Logger.info("[DomainProfile] ✓ Profile applied - domain: #{profile.institution.domain}")
    updated_institution
  end
  
  @doc """
  Get evidence threshold for a domain profile.
  
  Different domains require different confidence levels for publication.
  """
  def evidence_threshold(profile) do
    Map.get(profile.research_style, :evidence_threshold, 0.70)
  end
  
  @doc """
  Check if replication is required for a domain.
  
  Some domains (medicine, aerospace) require independent replication.
  """
  def replication_required?(profile) do
    Map.get(profile.research_style, :replication_required, false)
  end
  
  @doc """
  Get experiment cost multiplier for a domain.
  
  Adjusts economic ledger calculations based on domain complexity.
  """
  def experiment_cost_multiplier(profile) do
    Map.get(profile.economic_model, :experiment_cost_multiplier, 1.0)
  end
  
  @doc """
  Get governance approval threshold for a domain.
  
  Determines minimum confidence required for governance approval.
  """
  def governance_approval_threshold(profile) do
    Map.get(profile.governance, :approval_threshold, 0.70)
  end
  
  @doc """
  Check if ethical review is required for a domain.
  
  Domains like medicine, governance require additional ethical oversight.
  """
  def ethical_review_required?(profile) do
    Map.get(profile.governance, :ethical_review_required, false)
  end
  
  @doc """
  Get publication minimum confidence for a domain.
  
  Overrides default publication decision logic with domain-specific standards.
  """
  def publication_minimum_confidence(profile) do
    Map.get(profile.publication_policy, :minimum_confidence, 0.70)
  end
  
  @doc """
  Check if peer review is required before publication.
  
  Some domains mandate external peer review.
  """
  def peer_review_required?(profile) do
    Map.get(profile.publication_policy, :peer_review_required, false)
  end
  
  @doc """
  List available tools for a domain.
  
  Returns domain-specific experimental and analytical capabilities.
  """
  def available_tools(profile) do
    Map.get(profile, :tools, [])
  end
  
  @doc """
  Get domain ontology configuration.
  
  Returns knowledge graph initialization parameters and vocabulary.
  """
  def domain_ontology(profile) do
    Map.get(profile, :ontology, %{knowledge_graph: :default_ontology})
  end
  
  # ==================== Domain Profile Definitions ====================
  
  defp engineering_profile do
    %{
      institution: %{
        domain: :engineering,
        mission: "Design and validate engineered systems through empirical testing"
      },
      research_style: %{
        hypothesis_generation: :exploratory,
        evidence_threshold: 0.70,
        replication_required: false,
        risk_tolerance: :medium
      },
      tools: [:cad, :simulation, :optimization, :manufacturing, :testing],
      ontology: %{
        knowledge_graph: :engineering_ontology,
        vocabulary: [:iso_standards, :design_patterns, :failure_modes]
      },
      publication_policy: %{
        peer_review_required: false,
        minimum_confidence: 0.65,
        defer_on_contradiction: true
      },
      economic_model: %{
        experiment_cost_multiplier: 1.5,
        replication_budget_factor: 1.2,
        publication_value: 30.0
      },
      governance: %{
        approval_threshold: 0.65,
        ethical_review_required: false,
        safety_constraints: [:structural_integrity, :operational_safety]
      }
    }
  end
  
  defp medicine_profile do
    %{
      institution: %{
        domain: :medicine,
        mission: "Advance medical science through rigorous evidence-based research"
      },
      research_style: %{
        hypothesis_generation: :conservative,
        evidence_threshold: 0.90,
        replication_required: true,
        risk_tolerance: :low
      },
      tools: [:simulation, :literature_review, :clinical_trial, :statistical_analysis, :meta_analysis],
      ontology: %{
        knowledge_graph: :medical_ontology,
        vocabulary: [:icd10, :snomed_ct, :umls, :mesh]
      },
      publication_policy: %{
        peer_review_required: true,
        minimum_confidence: 0.85,
        defer_on_contradiction: true
      },
      economic_model: %{
        experiment_cost_multiplier: 2.5,
        replication_budget_factor: 1.5,
        publication_value: 50.0
      },
      governance: %{
        approval_threshold: 0.80,
        ethical_review_required: true,
        safety_constraints: [:patient_safety, :data_privacy, :informed_consent]
      }
    }
  end
  
  defp governance_profile do
    %{
      institution: %{
        domain: :governance,
        mission: "Study institutional design and policy effectiveness"
      },
      research_style: %{
        hypothesis_generation: :balanced,
        evidence_threshold: 0.80,
        replication_required: true,
        risk_tolerance: :low
      },
      tools: [:case_study, :comparative_analysis, :policy_simulation, :stakeholder_analysis],
      ontology: %{
        knowledge_graph: :governance_ontology,
        vocabulary: [:policy_frameworks, :institutional_design, :regulatory_theory]
      },
      publication_policy: %{
        peer_review_required: true,
        minimum_confidence: 0.75,
        defer_on_contradiction: true
      },
      economic_model: %{
        experiment_cost_multiplier: 1.8,
        replication_budget_factor: 1.3,
        publication_value: 40.0
      },
      governance: %{
        approval_threshold: 0.75,
        ethical_review_required: true,
        safety_constraints: [:social_impact, :equity_considerations]
      }
    }
  end
  
  defp computation_profile do
    %{
      institution: %{
        domain: :computation,
        mission: "Advance computational theory and algorithmic efficiency"
      },
      research_style: %{
        hypothesis_generation: :exploratory,
        evidence_threshold: 0.75,
        replication_required: false,
        risk_tolerance: :high
      },
      tools: [:algorithm_analysis, :complexity_theory, :benchmarking, :formal_verification],
      ontology: %{
        knowledge_graph: :computation_ontology,
        vocabulary: [:complexity_classes, :algorithm_families, :computability]
      },
      publication_policy: %{
        peer_review_required: false,
        minimum_confidence: 0.70,
        defer_on_contradiction: false
      },
      economic_model: %{
        experiment_cost_multiplier: 1.0,
        replication_budget_factor: 1.0,
        publication_value: 25.0
      },
      governance: %{
        approval_threshold: 0.65,
        ethical_review_required: false,
        safety_constraints: [:computational_resources]
      }
    }
  end
  
  defp science_profile do
    %{
      institution: %{
        domain: :engineering,
        mission: "Discover fundamental natural laws through empirical investigation"
      },
      research_style: %{
        hypothesis_generation: :balanced,
        evidence_threshold: 0.85,
        replication_required: true,
        risk_tolerance: :medium
      },
      tools: [:experimentation, :observation, :measurement, :statistical_inference, :modeling],
      ontology: %{
        knowledge_graph: :scientific_ontology,
        vocabulary: [:physical_laws, :natural_phenomena, :experimental_methods]
      },
      publication_policy: %{
        peer_review_required: true,
        minimum_confidence: 0.80,
        defer_on_contradiction: true
      },
      economic_model: %{
        experiment_cost_multiplier: 2.0,
        replication_budget_factor: 1.4,
        publication_value: 45.0
      },
      governance: %{
        approval_threshold: 0.75,
        ethical_review_required: false,
        safety_constraints: [:environmental_impact, :resource_sustainability]
      }
    }
  end
  
  defp agriculture_profile do
    %{
      institution: %{
        domain: :agriculture,
        mission: "Improve agricultural productivity and sustainability"
      },
      research_style: %{
        hypothesis_generation: :balanced,
        evidence_threshold: 0.75,
        replication_required: true,
        risk_tolerance: :medium
      },
      tools: [:field_trials, :crop_modeling, :soil_analysis, :climate_simulation],
      ontology: %{
        knowledge_graph: :agriculture_ontology,
        vocabulary: [:crop_science, :soil_health, :pest_management, :irrigation]
      },
      publication_policy: %{
        peer_review_required: false,
        minimum_confidence: 0.70,
        defer_on_contradiction: true
      },
      economic_model: %{
        experiment_cost_multiplier: 1.6,
        replication_budget_factor: 1.3,
        publication_value: 35.0
      },
      governance: %{
        approval_threshold: 0.70,
        ethical_review_required: false,
        safety_constraints: [:environmental_safety, :food_security]
      }
    }
  end
  
  defp energy_profile do
    %{
      institution: %{
        domain: :energy,
        mission: "Develop sustainable energy systems and improve efficiency"
      },
      research_style: %{
        hypothesis_generation: :exploratory,
        evidence_threshold: 0.80,
        replication_required: true,
        risk_tolerance: :medium
      },
      tools: [:system_modeling, :efficiency_analysis, :grid_simulation, :lifecycle_assessment],
      ontology: %{
        knowledge_graph: :energy_ontology,
        vocabulary: [:energy_sources, :conversion_efficiency, :grid_stability]
      },
      publication_policy: %{
        peer_review_required: true,
        minimum_confidence: 0.75,
        defer_on_contradiction: true
      },
      economic_model: %{
        experiment_cost_multiplier: 2.2,
        replication_budget_factor: 1.4,
        publication_value: 40.0
      },
      governance: %{
        approval_threshold: 0.75,
        ethical_review_required: false,
        safety_constraints: [:environmental_impact, :grid_reliability]
      }
    }
  end
  
  defp logistics_profile do
    %{
      institution: %{
        domain: :logistics,
        mission: "Optimize supply chain efficiency and resilience"
      },
      research_style: %{
        hypothesis_generation: :exploratory,
        evidence_threshold: 0.70,
        replication_required: false,
        risk_tolerance: :medium
      },
      tools: [:optimization, :simulation, :network_analysis, :demand_forecasting],
      ontology: %{
        knowledge_graph: :logistics_ontology,
        vocabulary: [:supply_chain, :inventory_management, :transportation]
      },
      publication_policy: %{
        peer_review_required: false,
        minimum_confidence: 0.65,
        defer_on_contradiction: false
      },
      economic_model: %{
        experiment_cost_multiplier: 1.3,
        replication_budget_factor: 1.1,
        publication_value: 30.0
      },
      governance: %{
        approval_threshold: 0.65,
        ethical_review_required: false,
        safety_constraints: [:operational_continuity]
      }
    }
  end
  
  defp cognition_profile do
    %{
      institution: %{
        domain: :cognition,
        mission: "Understand cognitive processes and intelligence mechanisms"
      },
      research_style: %{
        hypothesis_generation: :exploratory,
        evidence_threshold: 0.75,
        replication_required: true,
        risk_tolerance: :high
      },
      tools: [:neural_modeling, :behavioral_experiment, :cognitive_architecture, :learning_analysis],
      ontology: %{
        knowledge_graph: :cognition_ontology,
        vocabulary: [:cognitive_processes, :learning_mechanisms, :intelligence_types]
      },
      publication_policy: %{
        peer_review_required: true,
        minimum_confidence: 0.70,
        defer_on_contradiction: true
      },
      economic_model: %{
        experiment_cost_multiplier: 1.5,
        replication_budget_factor: 1.2,
        publication_value: 35.0
      },
      governance: %{
        approval_threshold: 0.70,
        ethical_review_required: true,
        safety_constraints: [:cognitive_safety, :alignment_verification]
      }
    }
  end
  
  defp materials_profile do
    %{
      institution: %{
        domain: :materials,
        mission: "Discover and characterize novel materials with desired properties"
      },
      research_style: %{
        hypothesis_generation: :exploratory,
        evidence_threshold: 0.80,
        replication_required: true,
        risk_tolerance: :medium
      },
      tools: [:molecular_dynamics, :quantum_chemistry, :material_synthesis, :characterization],
      ontology: %{
        knowledge_graph: :materials_ontology,
        vocabulary: [:material_properties, :crystal_structures, :phase_diagrams]
      },
      publication_policy: %{
        peer_review_required: true,
        minimum_confidence: 0.75,
        defer_on_contradiction: true
      },
      economic_model: %{
        experiment_cost_multiplier: 2.0,
        replication_budget_factor: 1.3,
        publication_value: 40.0
      },
      governance: %{
        approval_threshold: 0.70,
        ethical_review_required: false,
        safety_constraints: [:material_safety, :environmental_impact]
      }
    }
  end
  
  defp robotics_profile do
    %{
      institution: %{
        domain: :robotics,
        mission: "Design autonomous robotic systems for real-world tasks"
      },
      research_style: %{
        hypothesis_generation: :exploratory,
        evidence_threshold: 0.75,
        replication_required: false,
        risk_tolerance: :medium
      },
      tools: [:kinematic_modeling, :control_systems, :perception_algorithms, :hardware_integration],
      ontology: %{
        knowledge_graph: :robotics_ontology,
        vocabulary: [:robot_kinematics, :sensor_fusion, :motion_planning]
      },
      publication_policy: %{
        peer_review_required: false,
        minimum_confidence: 0.70,
        defer_on_contradiction: true
      },
      economic_model: %{
        experiment_cost_multiplier: 1.8,
        replication_budget_factor: 1.2,
        publication_value: 35.0
      },
      governance: %{
        approval_threshold: 0.70,
        ethical_review_required: false,
        safety_constraints: [:operational_safety, :human_robot_interaction]
      }
    }
  end
  
  defp economics_profile do
    %{
      institution: %{
        domain: :economics,
        mission: "Model economic systems and predict market behaviors"
      },
      research_style: %{
        hypothesis_generation: :balanced,
        evidence_threshold: 0.80,
        replication_required: true,
        risk_tolerance: :medium
      },
      tools: [:econometric_modeling, :game_theory, :market_simulation, :empirical_analysis],
      ontology: %{
        knowledge_graph: :economics_ontology,
        vocabulary: [:market_dynamics, :economic_indicators, :policy_effects]
      },
      publication_policy: %{
        peer_review_required: true,
        minimum_confidence: 0.75,
        defer_on_contradiction: true
      },
      economic_model: %{
        experiment_cost_multiplier: 1.5,
        replication_budget_factor: 1.2,
        publication_value: 35.0
      },
      governance: %{
        approval_threshold: 0.75,
        ethical_review_required: false,
        safety_constraints: [:model_validity, :prediction_reliability]
      }
    }
  end
  
  defp philosophy_profile do
    %{
      institution: %{
        domain: :philosophy,
        mission: "Analyze fundamental questions of existence, knowledge, and ethics"
      },
      research_style: %{
        hypothesis_generation: :exploratory,
        evidence_threshold: 0.70,
        replication_required: false,
        risk_tolerance: :high
      },
      tools: [:logical_analysis, :conceptual_clarification, :thought_experiment, :dialectical_reasoning],
      ontology: %{
        knowledge_graph: :philosophy_ontology,
        vocabulary: [:metaphysics, :epistemology, :ethics, :logic]
      },
      publication_policy: %{
        peer_review_required: true,
        minimum_confidence: 0.65,
        defer_on_contradiction: false
      },
      economic_model: %{
        experiment_cost_multiplier: 1.0,
        replication_budget_factor: 1.0,
        publication_value: 20.0
      },
      governance: %{
        approval_threshold: 0.60,
        ethical_review_required: false,
        safety_constraints: [:logical_consistency]
      }
    }
  end
  
  defp sociology_profile do
    %{
      institution: %{
        domain: :sociology,
        mission: "Study social structures, relationships, and collective behavior"
      },
      research_style: %{
        hypothesis_generation: :balanced,
        evidence_threshold: 0.75,
        replication_required: true,
        risk_tolerance: :medium
      },
      tools: [:survey_analysis, :ethnography, :social_network_analysis, :qualitative_methods],
      ontology: %{
        knowledge_graph: :sociology_ontology,
        vocabulary: [:social_structures, :group_dynamics, :cultural_patterns]
      },
      publication_policy: %{
        peer_review_required: true,
        minimum_confidence: 0.70,
        defer_on_contradiction: true
      },
      economic_model: %{
        experiment_cost_multiplier: 1.4,
        replication_budget_factor: 1.2,
        publication_value: 30.0
      },
      governance: %{
        approval_threshold: 0.70,
        ethical_review_required: true,
        safety_constraints: [:participant_privacy, :social_impact]
      }
    }
  end
  
  defp linguistics_profile do
    %{
      institution: %{
        domain: :linguistics,
        mission: "Analyze language structure, acquisition, and evolution"
      },
      research_style: %{
        hypothesis_generation: :balanced,
        evidence_threshold: 0.75,
        replication_required: false,
        risk_tolerance: :medium
      },
      tools: [:corpus_analysis, :phonetic_analysis, :syntactic_parsing, :semantic_modeling],
      ontology: %{
        knowledge_graph: :linguistics_ontology,
        vocabulary: [:syntax, :semantics, :phonology, :pragmatics]
      },
      publication_policy: %{
        peer_review_required: true,
        minimum_confidence: 0.70,
        defer_on_contradiction: true
      },
      economic_model: %{
        experiment_cost_multiplier: 1.2,
        replication_budget_factor: 1.1,
        publication_value: 25.0
      },
      governance: %{
        approval_threshold: 0.65,
        ethical_review_required: false,
        safety_constraints: [:data_privacy]
      }
    }
  end
  
  defp aerospace_profile do
    %{
      institution: %{
        domain: :aerospace,
        mission: "Design and validate aerospace systems for flight and space exploration"
      },
      research_style: %{
        hypothesis_generation: :conservative,
        evidence_threshold: 0.90,
        replication_required: true,
        risk_tolerance: :low
      },
      tools: [:aerodynamic_simulation, :structural_analysis, :orbital_mechanics, :flight_testing],
      ontology: %{
        knowledge_graph: :aerospace_ontology,
        vocabulary: [:aerodynamics, :propulsion, :avionics, :space_systems]
      },
      publication_policy: %{
        peer_review_required: true,
        minimum_confidence: 0.85,
        defer_on_contradiction: true
      },
      economic_model: %{
        experiment_cost_multiplier: 3.0,
        replication_budget_factor: 1.6,
        publication_value: 60.0
      },
      governance: %{
        approval_threshold: 0.85,
        ethical_review_required: false,
        safety_constraints: [:flight_safety, :mission_criticality, :human_spaceflight]
      }
    }
  end
  
  defp ecology_profile do
    %{
      institution: %{
        domain: :ecology,
        mission: "Study ecosystems and environmental interactions"
      },
      research_style: %{
        hypothesis_generation: :balanced,
        evidence_threshold: 0.80,
        replication_required: true,
        risk_tolerance: :medium
      },
      tools: [:field_observation, :ecosystem_modeling, :biodiversity_assessment, :climate_impact_analysis],
      ontology: %{
        knowledge_graph: :ecology_ontology,
        vocabulary: [:ecosystems, :species_interactions, :biogeochemical_cycles]
      },
      publication_policy: %{
        peer_review_required: true,
        minimum_confidence: 0.75,
        defer_on_contradiction: true
      },
      economic_model: %{
        experiment_cost_multiplier: 1.7,
        replication_budget_factor: 1.3,
        publication_value: 35.0
      },
      governance: %{
        approval_threshold: 0.75,
        ethical_review_required: false,
        safety_constraints: [:environmental_protection, :biodiversity_preservation]
      }
    }
  end
  
  defp cybernetics_profile do
    %{
      institution: %{
        domain: :cybernetics,
        mission: "Study control and communication in complex adaptive systems"
      },
      research_style: %{
        hypothesis_generation: :exploratory,
        evidence_threshold: 0.75,
        replication_required: false,
        risk_tolerance: :high
      },
      tools: [:system_modeling, :feedback_analysis, :adaptive_control, :information_theory],
      ontology: %{
        knowledge_graph: :cybernetics_ontology,
        vocabulary: [:feedback_loops, :control_systems, :adaptation_mechanisms]
      },
      publication_policy: %{
        peer_review_required: false,
        minimum_confidence: 0.70,
        defer_on_contradiction: false
      },
      economic_model: %{
        experiment_cost_multiplier: 1.4,
        replication_budget_factor: 1.2,
        publication_value: 30.0
      },
      governance: %{
        approval_threshold: 0.70,
        ethical_review_required: false,
        safety_constraints: [:system_stability, :control_safety]
      }
    }
  end
  
  defp architecture_profile do
    %{
      institution: %{
        domain: :architecture,
        mission: "Design built environments balancing aesthetics, function, and sustainability"
      },
      research_style: %{
        hypothesis_generation: :exploratory,
        evidence_threshold: 0.70,
        replication_required: false,
        risk_tolerance: :medium
      },
      tools: [:architectural_modeling, :structural_analysis, :environmental_simulation, :user_experience],
      ontology: %{
        knowledge_graph: :architecture_ontology,
        vocabulary: [:spatial_design, :building_systems, :urban_planning]
      },
      publication_policy: %{
        peer_review_required: false,
        minimum_confidence: 0.65,
        defer_on_contradiction: true
      },
      economic_model: %{
        experiment_cost_multiplier: 1.6,
        replication_budget_factor: 1.2,
        publication_value: 30.0
      },
      governance: %{
        approval_threshold: 0.65,
        ethical_review_required: false,
        safety_constraints: [:structural_safety, :accessibility, :sustainability]
      }
    }
  end
  
  defp mathematics_profile do
    %{
      institution: %{
        domain: :computation,
        mission: "Prove mathematical truths and develop abstract structures"
      },
      research_style: %{
        hypothesis_generation: :conservative,
        evidence_threshold: 1.0,  # Mathematical proof requires certainty
        replication_required: false,
        risk_tolerance: :low
      },
      tools: [:formal_proof, :theorem_proving, :abstract_algebra, :topological_analysis],
      ontology: %{
        knowledge_graph: :mathematics_ontology,
        vocabulary: [:axioms, :theorems, :proofs, :mathematical_structures]
      },
      publication_policy: %{
        peer_review_required: true,
        minimum_confidence: 0.95,
        defer_on_contradiction: true
      },
      economic_model: %{
        experiment_cost_multiplier: 1.0,
        replication_budget_factor: 1.0,
        publication_value: 40.0
      },
      governance: %{
        approval_threshold: 0.90,
        ethical_review_required: false,
        safety_constraints: [:logical_consistency, :proof_validity]
      }
    }
  end
  
  defp default_profile(domain_name) do
    %{
      institution: %{
        domain: domain_name,
        mission: "Conduct research in #{domain_name}"
      },
      research_style: %{
        hypothesis_generation: :balanced,
        evidence_threshold: 0.75,
        replication_required: false,
        risk_tolerance: :medium
      },
      tools: [:general_analysis, :modeling, :simulation],
      ontology: %{
        knowledge_graph: :default_ontology,
        vocabulary: []
      },
      publication_policy: %{
        peer_review_required: false,
        minimum_confidence: 0.70,
        defer_on_contradiction: true
      },
      economic_model: %{
        experiment_cost_multiplier: 1.0,
        replication_budget_factor: 1.0,
        publication_value: 25.0
      },
      governance: %{
        approval_threshold: 0.70,
        ethical_review_required: false,
        safety_constraints: []
      }
    }
  end
end
