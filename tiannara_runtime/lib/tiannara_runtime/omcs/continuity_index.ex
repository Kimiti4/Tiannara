defmodule TiannaraRuntime.OMCS.ContinuityIndex do
  @moduledoc """
  Ontological Memory Continuity System (OMCS) - Continuity Index.

  Maintains persistent semantic continuity, civilization identity lineages,
  and observer memory integrity across folding cycles, branches, and latent state merges.
  """

  use GenServer
  require Logger

  @min_continuity_threshold 0.85
  @history_limit 100

  # ==================== Public API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Record an identity lineage hash for a civilization or observer entity.
  """
  def record_lineage(entity_id, semantic_hash, metadata \\ %{}) do
    GenServer.cast(__MODULE__, {:record, entity_id, semantic_hash, metadata})
  end

  @doc """
  Get the historical continuity score (0.0 to 1.0) of an entity.
  """
  def get_continuity_score(entity_id) do
    GenServer.call(__MODULE__, {:get_score, entity_id})
  end

  @doc """
  Verify if a prospective fold or merge preserves meaning continuity within safety bounds.
  """
  def verify_continuity(entity_id, prospective_hash) do
    GenServer.call(__MODULE__, {:verify, entity_id, prospective_hash})
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    Logger.info("📚 [OMCS Continuity Index] Initialized")
    {:ok, initial_state()}
  end

  @impl true
  def handle_cast({:record, entity_id, hash, metadata}, state) do
    now = System.system_time(:millisecond)
    chain = Map.get(state.lineages, entity_id, [])

    # Keep a sliding window of historical lineage states
    new_chain = Enum.take([{hash, now, metadata} | chain], @history_limit)
    new_lineages = Map.put(state.lineages, entity_id, new_chain)

    {:noreply, %{state | lineages: new_lineages}}
  end

  @impl true
  def handle_call({:get_score, entity_id}, _from, state) do
    score = calculate_score(entity_id, state.lineages)
    {:reply, score, state}
  end

  @impl true
  def handle_call({:verify, entity_id, prospective_hash}, _from, state) do
    score = calculate_prospective_score(entity_id, prospective_hash, state.lineages)
    decision = if score >= @min_continuity_threshold, do: :ok, else: {:error, :excessive_identity_drift}
    {:reply, decision, state}
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    {:reply, :ok, initial_state()}
  end

  @impl true
  def handle_cast(:reset, _state) do
    {:noreply, initial_state()}
  end

  # ==================== Helper Functions ====================

  defp initial_state do
    %{
      lineages: %{}
    }
  end

  defp calculate_score(entity_id, lineages) do
    case Map.get(lineages, entity_id) do
      nil -> 1.0
      [] -> 1.0
      chain ->
        # Continuity is the similarity score across subsequent hash chain links
        hashes = Enum.map(chain, fn {h, _, _} -> h end)
        compute_chain_consistency(hashes)
    end
  end

  defp calculate_prospective_score(entity_id, prospective_hash, lineages) do
    case Map.get(lineages, entity_id) do
      nil -> 1.0
      [] -> 1.0
      chain ->
        hashes = [prospective_hash | Enum.map(chain, fn {h, _, _} -> h end)]
        compute_chain_consistency(hashes)
    end
  end

  defp compute_chain_consistency(hashes) do
    if length(hashes) < 2 do
      1.0
    else
      # Compute overlap percentage between subsequent string representations of hashes
      pairs = Enum.zip(hashes, tl(hashes))
      similarities = Enum.map(pairs, fn {h1, h2} -> string_similarity(h1, h2) end)
      Enum.sum(similarities) / length(similarities)
    end
  end

  defp string_similarity(s1, s2) when is_binary(s1) and is_binary(s2) do
    c1 = String.to_charlist(s1)
    c2 = String.to_charlist(s2)
    common = Enum.count(c1, fn char -> char in c2 end)
    total = max(length(c1), 1)
    common / total
  end

  defp string_similarity(_, _), do: 1.0
end
