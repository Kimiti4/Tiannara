defmodule TiannaraRuntime.SelfCompilation.RuleExtractor do
  @moduledoc """
  Phase 5F.13: Rule Extractor - Extracts Current Rules from Subsystems

  Queries target subsystems to extract their current operational rules,
  parameters, and configuration for self-compilation analysis.

  Each subsystem exposes a rule extraction interface that returns
  its current state in a standardized format for mutation.
  """

  @doc """
  Extract current rules from specified subsystem.

  ## Parameters
  - subsystem: Target subsystem (:rrg | :omce | :olef | :opc)

  ## Returns
  List of rule structures representing current subsystem state
  """
  def extract(subsystem) do
    case subsystem do
      :rrg -> extract_rrg_rules()
      :omce -> extract_omce_rules()
      :olef -> extract_olef_rules()
      :opc -> extract_opc_rules()
    end
  end

  defp extract_rrg_rules do
    # Extract RRG operational parameters
    [
      %{
        type: :psi_threshold,
        value: 0.3,
        description: "Critical Ψ stability threshold"
      },
      %{
        type: :novelty_injection_max,
        value: 0.15,
        description: "Maximum novelty injection magnitude"
      },
      %{
        type: :recursion_regulation_threshold,
        value: 0.7,
        description: "Observer recursion regulation trigger"
      },
      %{
        type: :attractor_detection_sensitivity,
        value: 0.6,
        description: "Attractor detection sensitivity level"
      }
    ]
  end

  defp extract_omce_rules do
    # Extract OMCE compression strategies
    [
      %{
        type: :compression_ratio_aggressive,
        value: 0.4,
        description: "Aggressive compression retention ratio"
      },
      %{
        type: :compression_ratio_moderate,
        value: 0.7,
        description: "Moderate compression retention ratio"
      },
      %{
        type: :identity_merge_threshold,
        value: 0.85,
        description: "Identity merger similarity threshold"
      },
      %{
        type: :causal_prune_depth,
        value: 5,
        description: "Causal pruning depth limit"
      }
    ]
  end

  defp extract_olef_rules do
    # Extract OLEF load distribution parameters
    [
      %{
        type: :diffusion_rate,
        value: 0.1,
        description: "Load diffusion rate coefficient"
      },
      %{
        type: :pressure_equalization_speed,
        value: 0.05,
        description: "Pressure field equalization speed"
      },
      %{
        type: :node_capacity_threshold,
        value: 0.9,
        description: "Node capacity utilization threshold"
      },
      %{
        type: :load_balancing_interval,
        value: 1000,
        description: "Load balancing cycle interval (ms)"
      }
    ]
  end

  defp extract_opc_rules do
    # Extract OPC physics compilation heuristics
    [
      %{
        type: :ast_optimization_level,
        value: 2,
        description: "AST optimization aggressiveness (0-3)"
      },
      %{
        type: :shader_cache_ttl,
        value: 300,
        description: "Shader cache time-to-live (seconds)"
      },
      %{
        type: :compilation_timeout,
        value: 5000,
        description: "Compilation timeout (milliseconds)"
      },
      %{
        type: :parallel_compilation_limit,
        value: 4,
        description: "Maximum parallel compilations"
      },
      %{
        type: :epsilon_shim_budget,
        value: 0.5,
        description: "MSCL thermodynamic budget for epsilon shimming"
      }
    ]
  end
end
