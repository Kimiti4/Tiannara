defmodule Tiannara.Ctl.CausalRegistry do
  @moduledoc """
  Central registry for tracking causal relationships, branch histories, and their metadata.
  This module maintains the authoritative record of all causal branches and their states.
  """

  @telemetry_prefix "tiannara.ctl.causal_registry"

  use GenServer

  @type branch_id :: String.t()
  @type branch_state :: :active | :isolated | :reconciled | :archived
  @type branch_record :: %{
          id: branch_id(),
          parent_id: branch_id() | nil,
          state: branch_state(),
          divergence: non_neg_integer(),
          sync_capacity: non_neg_integer(),
          stress: float(),
          created_at: DateTime.t(),
          updated_at: DateTime.t(),
          metadata: map()
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec register_branch(branch_record()) :: {:ok, branch_id()} | {:error, term()}
  def register_branch(branch) do
    GenServer.call(__MODULE__, {:register_branch, branch})
  end

  @spec get_branch(branch_id()) :: {:ok, branch_record()} | {:error, :not_found}
  def get_branch(branch_id) do
    GenServer.call(__MODULE__, {:get_branch, branch_id})
  end

  @spec update_branch_state(branch_id(), branch_state()) :: :ok | {:error, term()}
  def update_branch_state(branch_id, state) do
    GenServer.call(__MODULE__, {:update_branch_state, branch_id, state})
  end

  @spec list_branches() :: {:ok, [branch_record()]}
  def list_branches() do
    GenServer.call(__MODULE__, :list_branches)
  end

  @spec get_divergent_branches() :: {:ok, [branch_record()]}
  def get_divergent_branches() do
    GenServer.call(__MODULE__, :get_divergent_branches)
  end

  @impl true
  def init(_opts) do
    {:ok, %{branches: %{}}}
  end

  @impl true
  def handle_call({:register_branch, branch}, _from, state) do
    branch_id = branch.id
    new_state = Map.put(state.branches, branch_id, branch)
    {:reply, {:ok, branch_id}, %{state | branches: new_state}}
  end

  @impl true
  def handle_call({:get_branch, branch_id}, _from, state) do
    case Map.get(state.branches, branch_id) do
      nil -> {:reply, {:error, :not_found}, state}
      branch -> {:reply, {:ok, branch}, state}
    end
  end

  @impl true
  def handle_call({:update_branch_state, branch_id, new_state}, _from, state) do
    case Map.get(state.branches, branch_id) do
      nil -> {:reply, {:error, :not_found}, state}
      branch ->
        updated_branch = %{branch | state: new_state, updated_at: DateTime.utc_now()}
        new_branches = Map.put(state.branches, branch_id, updated_branch)
        {:reply, :ok, %{state | branches: new_branches}}
    end
  end

  @impl true
  def handle_call(:list_branches, _from, state) do
    {:reply, {:ok, Map.values(state.branches)}, state}
  end

  @impl true
  def handle_call(:get_divergent_branches, _from, state) do
    divergent = 
      state.branches
      |> Map.values()
      |> Enum.filter(fn b -> b.divergence > 0 end)
    {:reply, {:ok, divergent}, state}
  end
end
