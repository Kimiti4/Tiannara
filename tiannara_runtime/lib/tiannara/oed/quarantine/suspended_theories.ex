defmodule Tiannara.OED.Quarantine.SuspendedTheories do
  @moduledoc """
  🗃️ Quarantine Subsystem Suspended Theories Store.

  Provides secure in-memory storage for raw rule configurations that are quarantined,
  ensuring they are never read by the hot-swap deployment orchestrator.
  """

  use Agent
  require Logger

  def start_link(_opts \\ []) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc """
  Saves the raw rule body in suspended storage.
  """
  @spec store(id :: atom(), body :: any()) :: :ok
  def store(id, body) do
    Agent.update(__MODULE__, &Map.put(&1, id, body))
  end

  @doc """
  Retrieves a suspended rule body.
  """
  @spec fetch(id :: atom()) :: {:ok, any()} | :error
  def fetch(id) do
    Agent.get(__MODULE__, fn state ->
      Map.fetch(state, id)
    end)
  end

  @doc """
  Purges a rule from the suspended store.
  """
  @spec delete(id :: atom()) :: :ok
  def delete(id) do
    Agent.update(__MODULE__, &Map.delete(&1, id))
  end
end
