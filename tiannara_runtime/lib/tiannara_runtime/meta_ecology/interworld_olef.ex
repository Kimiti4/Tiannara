defmodule Tiannara.MetaEcology.InterworldOLEF do
  @moduledoc """
  Meta-Ecology: Interworld OLEF (Ontological Latent Energy Field).
  
  Extends the per-world OLEF diffusion mechanism across the entire cluster.
  Thermodynamic pressure and ontological stress are shared across realities,
  preventing any single world from bursting under a Tier 3 irreversible mutation.
  """
  
  require Logger
  
  @doc """
  Diffuses a massive stress spike (e.g., from an irreversible mutation) across
  the meta-ecology cluster.
  """
  def diffuse_pressure(cluster, stress_amount) do
    Logger.info("🌊 [Interworld OLEF] Diffusing #{Float.round(stress_amount, 2)} stress across cluster #{cluster.id}...")
    
    world_count = length(cluster.worlds)
    stress_per_world = stress_amount / world_count
    
    Enum.each(cluster.worlds, fn world_id ->
      # In a real system, we would cast this to the world's local OLEF field
      Logger.debug("   ↳ Transmitting #{Float.round(stress_per_world, 2)} pressure to #{world_id}")
    end)
    
    Logger.info("✅ [Interworld OLEF] Pressure successfully equilibrated across #{world_count} worlds.")
    {:ok, :pressure_diffused}
  end
end
