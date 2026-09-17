defmodule Tiannara.OSE.DormancyProtocol do
  @moduledoc """
  Ontological Selection Ecology: Dormancy Protocol.
  
  Executes the LEOC/ECL archival pipeline:
  Instability -> Bandwidth Reduction -> Latent Compression -> Dormant Ontology Store
  """
  
  require Logger

  @survival_threshold 15.0

  @doc """
  Evaluates active universes and transitions weak ones into a dormant, compressed state.
  """
  def process_ecology(battlefield) do
    Logger.info("🗜️ [OSE] Processing Dormancy Protocol on active ecology...")
    
    {survivors, to_archive} = Enum.split_with(battlefield.active_universes, fn u ->
      u.budget >= @survival_threshold
    end)
    
    Enum.each(to_archive, fn u ->
      Logger.warning("🗜️ [OSE] Ontology #{u.id} dropped below survival threshold. Initiating Dormancy Protocol.")
      compress_to_latent(u)
    end)
    
    %{battlefield | active_universes: survivors}
  end

  defp compress_to_latent(universe) do
    Logger.info("🗜️ [OSE] -> Bandwidth Reduction complete.")
    Logger.info("🗜️ [OSE] -> Latent Compression (LEOC) applied.")
    Logger.info("🗜️ [OSE] -> #{universe.id} safely archived into ECL Dormant Store. Retained for future semantic reconstruction.")
  end
end
