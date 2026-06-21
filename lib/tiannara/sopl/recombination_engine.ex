defmodule Tiannara.SOPL.ProtoLaw do
  @moduledoc """
  SOPL-3: ProtoLaw
  
  The output of Fragment Recombination. Must survive the Compatibility Matrix
  and Shadow Validation to become a fully deployed LawGenome.
  """
  defstruct [
    :id,
    :fragment_ancestry,      # List of fragment IDs used to build this
    :synthesized_parameters, # The merged map of law configuration
    :synergy_score           # Evaluated by the Compatibility Matrix
  ]
end

defmodule Tiannara.SOPL.RecombinationEngine do
  @moduledoc """
  SOPL-3: Recombination Engine
  
  Fuses LawFragments together to synthesize ProtoLaws. Routes them through
  the Compatibility Matrix and Shadow Validator before deployment.
  """
  require Logger
  alias Tiannara.SOPL.{ProtoLaw, FragmentCompatibilityMatrix, ShadowValidator, LawGenome}

  @doc """
  Attempts to synthesize a new ProtoLaw from a set of LawFragments.
  Returns `{:ok, deployed_law}` or `{:failed, reason}`.
  """
  def synthesize_and_deploy(fragments) do
    Logger.info("🌌 [SOPL-3] Attempting synthesis of #{length(fragments)} fragments...")

    # 1. Compatibility Check
    case FragmentCompatibilityMatrix.evaluate_synthesis(fragments) do
      {:toxic, reason} ->
        Logger.warning("❌ [SOPL-3] Synthesis aborted by Matrix: #{reason}")
        {:failed, reason}
        
      {:ok, synergy} ->
        # 2. Recombination -> ProtoLaw
        proto = build_proto_law(fragments, synergy)
        
        # Convert ProtoLaw to temporary LawGenome for Shadow Validation
        temp_law = convert_to_genome(proto)
        
        # 3. Shadow Validation
        case ShadowValidator.validate([temp_law]) do
          [] ->
            Logger.warning("❌ [SOPL-3] ProtoLaw #{proto.id} failed Shadow Validation.")
            {:failed, :shadow_validation_failed}
            
          [{:ok, validated_law, _pressure}] ->
            # 4. Deployment (Graduation)
            Logger.info("✅ [SOPL-3] ProtoLaw #{proto.id} survived. Graduating to live LawGenome.")
            {:ok, validated_law}
        end
    end
  end

  defp build_proto_law(fragments, synergy) do
    ancestry = Enum.map(fragments, & &1.id)
    
    # Merge parameters. Conflicts (if any) are overwritten by the latter fragment.
    # In a full simulation, a more complex genomic weave would occur.
    synthesized = Enum.reduce(fragments, %{}, fn frag, acc ->
      Map.merge(acc, frag.parameters)
    end)
    
    %ProtoLaw{
      id: "proto_#{:crypto.strong_rand_bytes(4) |> Base.encode16()}",
      fragment_ancestry: ancestry,
      synthesized_parameters: synthesized,
      synergy_score: synergy
    }
  end

  defp convert_to_genome(proto) do
    # Fill in the blanks with defaults for parameters not provided by fragments
    base = LawGenome.generate(%{})
    
    # Simple direct mapping for the core variables
    %{base | 
      id: proto.id,
      mutation_pressure: Map.get(proto.synthesized_parameters, :mutation_pressure, base.mutation_pressure),
      diversity_floor: Map.get(proto.synthesized_parameters, :diversity_floor, base.diversity_floor),
      novelty_reward: Map.get(proto.synthesized_parameters, :novelty_reward, base.novelty_reward)
    }
  end
end
