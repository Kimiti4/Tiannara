defmodule Tiannara.REA.Epistemic.QuarantineManager do
  use GenServer

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  # --- PUBLIC API ---

  def quarantine_theory(theory_id, reason) do
    GenServer.call(__MODULE__, {:quarantine, :theory, theory_id, reason})
  end

  def quarantine_shard(shard_id, reason) do
    GenServer.call(__MODULE__, {:quarantine, :shard, shard_id, reason})
  end

  def quarantine_civilization(civ_id, reason) do
    GenServer.call(__MODULE__, {:quarantine, :civilization, civ_id, reason})
  end

  def lift_quarantine(entity_id) do
    GenServer.call(__MODULE__, {:lift_quarantine, entity_id})
  end

  def quarantined_theories do
    GenServer.call(__MODULE__, {:get_quarantined, :theory})
  end

  def quarantined_shards do
    GenServer.call(__MODULE__, {:get_quarantined, :shard})
  end

  def quarantined_civilizations do
    GenServer.call(__MODULE__, {:get_quarantined, :civilization})
  end

  def is_quarantined?(entity_id) do
    GenServer.call(__MODULE__, {:is_quarantined?, entity_id})
  end

  def get_quarantines do
    GenServer.call(__MODULE__, :get_quarantines)
  end

  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  # --- CALLBACKS ---

  @impl true
  def init(_opts) do
    {:ok, %{theories: %{}, shards: %{}, civilizations: %{}}}
  end

  @impl true
  def handle_call({:quarantine, type, id, reason}, _from, state) do
    key = type_to_key(type)
    new_map = Map.put(state[key], id, %{reason: reason, timestamp: System.system_time(:millisecond)})
    {:reply, :ok, Map.put(state, key, new_map)}
  end

  @impl true
  def handle_call({:lift_quarantine, id}, _from, state) do
    new_state =
      state
      |> Map.new(fn {key, map} ->
        {key, Map.delete(map, id)}
      end)

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:get_quarantined, type}, _from, state) do
    key = type_to_key(type)
    {:reply, Map.keys(state[key]), state}
  end

  @impl true
  def handle_call({:is_quarantined?, id}, _from, state) do
    result =
      Map.has_key?(state.theories, id) or
      Map.has_key?(state.shards, id) or
      Map.has_key?(state.civilizations, id)

    {:reply, result, state}
  end

  @impl true
  def handle_call(:get_quarantines, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    {:reply, :ok, %{theories: %{}, shards: %{}, civilizations: %{}}}
  end

  # --- PRIVATE HELPERS ---

  defp type_to_key(:theory), do: :theories
  defp type_to_key(:shard), do: :shards
  defp type_to_key(:civilization), do: :civilizations
end
