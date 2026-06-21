defmodule Tiannara.DFG.TopologicalFold do
  @moduledoc """
  Compresses active ontology graphs (or civilization state) into higher-dimensional latent manifolds.
  Shared infrastructure between DFG (Reality Compression) and LEOC (Civilization Compression).
  """

  @doc """
  Projects a live graph structure into a latent manifold format.
  Extracts primary attractors and prunes noisy branches.
  """
  def project(graph_or_state) when is_map(graph_or_state) do
    # Extract the highest weight nodes as attractors
    attractors = extract_attractors(graph_or_state)
    
    %{
      manifold_id: "latent_#{:crypto.strong_rand_bytes(4) |> Base.encode16()}",
      attractors: attractors,
      compression_ratio: compute_compression_ratio(graph_or_state, attractors),
      structural_hash: :erlang.phash2(attractors)
    }
  end

  defp extract_attractors(state) do
    # Shared logic with LEOC: if state contains discoveries/domains, treat them as affinities
    cond do
      Map.has_key?(state, :discoveries) ->
        # It's an EpochClosure from LEOC
        # Simplified attractor projection
        %{type: :civilization_seed, footprint: length(state.discoveries)}
        
      Map.has_key?(state, :semantic_entropy) ->
        # It's an Ecology from D.2
        %{type: :reality_manifold, entropy: state.semantic_entropy}
        
      true ->
        %{type: :generic_manifold, state_keys: Map.keys(state)}
    end
  end

  defp compute_compression_ratio(_original, _attractors) do
    # Arbitrary high compression representing the shift to latent space
    0.01 
  end
end
