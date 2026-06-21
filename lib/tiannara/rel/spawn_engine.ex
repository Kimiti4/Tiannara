defmodule Tiannara.REL.SpawnEngine do
  @moduledoc """
  Handles procedural re-emergence by applying latent affinities from LEOC's LatentVault
  to newly spawned civilizations.
  """
  
  require Logger

  @doc """
  Samples the LatentVault for compressed EigenSeeds and probabilistically
  applies their domain affinities to the new civilization's epistemic genome.
  """
  def apply_latent_inheritance(new_civ_id, shard_id) do
    # Fetch all latent seeds
    latent_pool = Tiannara.LEOC.LatentVault.get_all()
    
    # 70% random emergence vs 30% EigenSeed influence
    is_latent = :rand.uniform() <= 0.30
    
    if is_latent and length(latent_pool) > 0 do
      # Probabilistically sample one EigenSeed based on re-emergence affinity
      # (Mocked selection logic for now)
      selected_eigen = Enum.random(latent_pool)

      Logger.info("🌱 [SpawnEngine] #{new_civ_id} inherited affinities from extinct civilization (EigenSeed: #{selected_eigen.id}).")
      
      # Extract affinities
      affinity_bonuses = selected_eigen.domain_affinities
      historical_disease_resistance = selected_eigen.historical_disease_resistance

      case Tiannara.Core.WorldModel.EntityRegistry.get_entity(new_civ_id, shard_id) do
        {:ok, ent} ->
          new_attrs = ent.attributes
          |> Map.put(:domain_affinities, affinity_bonuses)
          |> Map.put(:historical_disease_resistance, historical_disease_resistance)

          Tiannara.Core.WorldModel.EntityRegistry.update_entity(new_civ_id, %{attributes: new_attrs}, shard_id)
        _ -> :ok
      end
    else
      Logger.info("🌱 [SpawnEngine] #{new_civ_id} emerged via spontaneous generation (random).")
    end
  end
end
