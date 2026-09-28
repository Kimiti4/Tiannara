defmodule Tiannara.CTL.CausalRegistry do
  @moduledoc """
  Persistent-in-process registry for causal branches and lineage metadata.

  Branch registration is explicit and content-addressable. The registry never
  invents branch counts and never reports synthetic capacity.
  """
  use GenServer

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def register_branch(branch_id, lineage, attrs \\ %{}), do: GenServer.call(__MODULE__, {:register, branch_id, lineage, attrs})
  def get_branch(branch_id), do: GenServer.call(__MODULE__, {:get, branch_id})
  def get_active_branches, do: GenServer.call(__MODULE__, :active)
  def deactivate(branch_id), do: GenServer.call(__MODULE__, {:deactivate, branch_id})
  def clear, do: GenServer.call(__MODULE__, :clear)

  @impl true
  def init(_), do: {:ok, %{branches: %{}}}

  @impl true
  def handle_call({:register, id, lineage, attrs}, _from, state) do
    if is_nil(id) or is_nil(lineage) do
      {:reply, {:error, :invalid_branch_identity}, state}
    else
      record = Map.merge(%{
        id: id, lineage: lineage, stress: 0.0, status: :active,
        registered_at: DateTime.utc_now(), revision: 1
      }, attrs)
      {:reply, {:ok, record}, %{state | branches: Map.put(state.branches, id, record)}}
    end
  end

  @impl true
  def handle_call({:get, id}, _from, state) do
    case Map.fetch(state.branches, id) do
      {:ok, branch} -> {:reply, {:ok, branch}, state}
      :error -> {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call(:active, _from, state) do
    branches = state.branches |> Map.values() |> Enum.filter(&(&1.status == :active))
    {:reply, branches, state}
  end

  @impl true
  def handle_call({:deactivate, id}, _from, state) do
    case Map.fetch(state.branches, id) do
      {:ok, branch} ->
        updated = %{branch | status: :inactive, revision: branch.revision + 1}
        {:reply, {:ok, updated}, %{state | branches: Map.put(state.branches, id, updated)}}
      :error -> {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call(:clear, _from, _state), do: {:reply, :ok, %{branches: %{}}}
end
