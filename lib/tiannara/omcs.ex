defmodule Tiannara.OMCS do
  @moduledoc """
  Ontological Memory Continuity System (OMCS) public API.
  Handles identity capture and restoration, supporting LEOC and Reality Multiplication.
  """

  alias Tiannara.OMCS.IdentitySeed
  alias Tiannara.OMCS.Engine
  alias Tiannara.OMCS.ContinuityScorer
  alias Tiannara.ROS.ShardManager
  
  # For fetching ontology fingerprint from WorldModel
  alias Tiannara.Core.WorldModel.BeliefSystem

  @doc """
  Captures the identity of a civilization running in a specific shard.
  Returns an %IdentitySeed{} that can be safely compressed by LEOC.
  """
  def capture_identity(shard_id, civ_id) do
    {:ok, lineage} = Engine.get_lineage(civ_id)
    {:ok, causal} = Engine.get_causal_graph(civ_id)
    {:ok, narrative} = Engine.get_narrative(civ_id)
    
    # Query the shard's BeliefSystem to construct the ontology fingerprint
    ontology_fingerprint = fetch_ontology_fingerprint(shard_id)

    %IdentitySeed{
      civilization_id: civ_id,
      lineage_graph: lineage,
      causal_graph: causal,
      narrative_graph: narrative,
      ontology_fingerprint: ontology_fingerprint,
      captured_at: DateTime.utc_now()
    }
  end

  @doc """
  Restores a civilization into a new shard from an IdentitySeed.
  Returns {:ok, %ContinuityVector{}} measuring how much identity survived.
  """
  def restore_identity(target_shard_id, %IdentitySeed{} = seed) do
    # 1. Register civilization in OMCS (if not already)
    # The restored civilization is a continuation, but we register the ID 
    # to continue appending to it.
    _ = Engine.register_civilization(seed.civilization_id)

    # 2. Inject state into the new shard
    # This involves injecting beliefs into the target shard's BeliefSystem
    inject_ontology(target_shard_id, seed.ontology_fingerprint)
    
    # 3. Capture the restored identity to measure continuity
    restored_seed = capture_identity(target_shard_id, seed.civilization_id)
    
    # 4. Score continuity between original and restored seeds
    continuity_vector = ContinuityScorer.score(seed, restored_seed)
    
    {:ok, continuity_vector}
  end

  defp fetch_ontology_fingerprint(shard_id) do
    # Fetch beliefs from the shard's isolated BeliefSystem
    name = Tiannara.ROS.Registry.via(BeliefSystem, shard_id)
    
    try do
      {:ok, beliefs} = GenServer.call(name, :list_beliefs)
      # Extract themes (keywords or domains) as fingerprint
      Enum.map(beliefs, & &1.statement)
    catch
      :exit, _ -> [] # If shard is dead or belief system is down
    end
  end

  defp inject_ontology(shard_id, fingerprint) do
    name = Tiannara.ROS.Registry.via(BeliefSystem, shard_id)
    
    Enum.each(fingerprint || [], fn statement ->
      try do
        GenServer.call(name, {:add_belief, %{
          id: "restored:#{:crypto.strong_rand_bytes(4) |> Base.encode16()}",
          statement: statement,
          confidence: 0.9,
          source: "omcs_restoration",
          evidence: [],
          created_at: DateTime.utc_now(),
          last_verified: DateTime.utc_now()
        }})
      catch
        :exit, _ -> :ok
      end
    end)
  end
end
