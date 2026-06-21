defmodule Tiannara.OMCS.ContinuityIndex do
  use GenServer
  require Logger

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def init(_) do
    {:ok, %{
      continuity_anchors: %{},
      semantic_lineages: %{},
      identity_hashes: %{},
      config: %{hash_chain_depth: 50}
    }}
  end

  def register_civilization(civ_id, initial_state) do
    GenServer.cast(__MODULE__, {:register_civ, civ_id, initial_state})
  end

  def record_semantic_state(entity_id, semantic_snapshot) do
    GenServer.cast(__MODULE__, {:record_semantic, entity_id, semantic_snapshot})
  end

  def verify_identity_continuity(entity_id) do
    GenServer.call(__MODULE__, {:verify_identity, entity_id})
  end

  def handle_cast({:register_civ, civ_id, initial_state}, state) do
    anchor = %{civ_id: civ_id, semantic_state: initial_state, timestamp: System.monotonic_time(:millisecond)}
    new_anchors = Map.put(state.continuity_anchors, civ_id, anchor)
    new_lineages = Map.put(state.semantic_lineages, civ_id, [initial_state])
    new_hashes = Map.put(state.identity_hashes, civ_id, [compute_hash(initial_state)])
    Logger.info("OMCS: Registered civilization #{civ_id}")
    {:noreply, %{state | continuity_anchors: new_anchors, semantic_lineages: new_lineages, identity_hashes: new_hashes}}
  end

  def handle_cast({:record_semantic, entity_id, semantic_snapshot}, state) do
    current_lineage = Map.get(state.semantic_lineages, entity_id, [])
    new_lineage = [semantic_snapshot | Enum.take(current_lineage, state.config.hash_chain_depth - 1)]
    new_hash = compute_hash(semantic_snapshot)
    current_hashes = Map.get(state.identity_hashes, entity_id, [])
    new_hashes_list = [new_hash | Enum.take(current_hashes, state.config.hash_chain_depth - 1)]
    {:noreply, %{state | semantic_lineages: Map.put(state.semantic_lineages, entity_id, new_lineage), identity_hashes: Map.put(state.identity_hashes, entity_id, new_hashes_list)}}
  end

  def handle_call({:verify_identity, entity_id}, _from, state) do
    hashes = Map.get(state.identity_hashes, entity_id, [])
    if Enum.empty?(hashes) do
      {:reply, {:error, :no_identity_history}, state}
    else
      continuity_score = 1.0 - calculate_entropy(hashes)
      result = %{entity_id: entity_id, continuity_score: continuity_score, history_depth: length(hashes)}
      {:reply, {:ok, result}, state}
    end
  end

  defp compute_hash(data), do: :erlang.phash2(inspect(data)) |> Integer.to_string(16)
  defp calculate_entropy([]), do: 0.0
  defp calculate_entropy(hashes) do
    min(1.0, Enum.uniq(hashes) |> length() |> then(&(1.0 - &1/length(hashes))))
  end
end
