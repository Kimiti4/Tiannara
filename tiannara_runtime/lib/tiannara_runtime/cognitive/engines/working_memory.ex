defmodule TiannaraRuntime.Cognitive.Engines.WorkingMemory do
  @moduledoc "Phase 18.3 — Constitutional Working Memory"

  alias TiannaraRuntime.Cognitive.WorkingMemory, as: WM

  def create(capacity \\ 1024) do
    %{store: %{}, capacity: capacity, usage: 0, version: 0, frames: [], snapshots: []}
  end

  def insert(state, key, value) do
    if state.usage >= state.capacity do
      evict(state)
    else
      store = Map.put(state.store, key, %{value: value, version: state.version + 1, inserted_at: :erlang.unique_integer([:positive])})
      {:ok, %{state | store: store, usage: state.usage + 1, version: state.version + 1}}
    end
  end

  def update(state, key, value) do
    case Map.fetch(state.store, key) do
      {:ok, entry} ->
        store = Map.put(state.store, key, %{value: value, version: state.version + 1, inserted_at: entry.inserted_at})
        {:ok, %{state | store: store, version: state.version + 1}}
      :error -> {:error, :not_found}
    end
  end

  def remove(state, key) do
    case Map.fetch(state.store, key) do
      {:ok, _} ->
        store = Map.delete(state.store, key)
        {:ok, %{state | store: store, usage: state.usage - 1, version: state.version + 1}}
      :error -> {:error, :not_found}
    end
  end

  def get(state, key) do
    case Map.fetch(state.store, key) do
      {:ok, entry} -> {:ok, entry.value}
      :error -> {:error, :not_found}
    end
  end

  def snapshot(state) do
    snapshot = %{
      store: state.store,
      usage: state.usage,
      version: state.version,
      captured_at: :erlang.unique_integer([:positive])
    }
    {:ok, %{state | snapshots: state.snapshots ++ [snapshot]}, snapshot}
  end

  def restore(state, snapshot) do
    {:ok, %{state | store: snapshot.store, usage: snapshot.usage, version: snapshot.version}}
  end

  def capacity(state), do: {:ok, state.capacity}

  def usage(state), do: {:ok, %{usage: state.usage, capacity: state.capacity, percent: if(state.capacity > 0, do: state.usage / state.capacity, else: 0.0)}}

  defp evict(state) do
    if map_size(state.store) == 0 do
      {:error, :at_capacity}
    else
      oldest = Enum.min_by(state.store, fn {_k, v} -> v.inserted_at end)
      {key, _} = oldest
      remove(state, key)
    end
  end
end
