defmodule Tiannara.CTL.CausalRegistry do
  @moduledoc """
  Canonical store for Causal Tensegrity Lattice branches.

  Single source of truth for branch identity, lineage, and measured causal
  stress. Merge validation (`Tiannara.Ctl.BranchValidator`) reads branch
  evidence exclusively from here and fails closed with a named reason when
  the registry is not running or a branch was never registered — there are
  no default branch values.

  Note on naming: this module is `Tiannara.CTL.*` (uppercase). A similarly
  cased explicit stub `Tiannara.Ctl.CausalRegistry` was deleted during
  remediation — on case-insensitive filesystems its beam file collided with
  this module's, so exactly one of the two survived each compile
  (capability ledger D-B).
  """
  use GenServer

  @type branch_id :: String.t()
  @type branch :: %{
          id: branch_id(),
          lineage: term(),
          stress: number(),
          registered_at: DateTime.t()
        }

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc """
  Registers a branch with its lineage and measured causal stress.

  `stress` must be a number in `0.0..1.0` supplied by the measuring
  subsystem. Out-of-range or non-numeric values are rejected — the registry
  never normalizes or fabricates measurements.
  """
  @spec register_branch(branch_id(), term(), number()) ::
          {:ok, branch()} | {:error, :invalid_branch_id | :invalid_stress | :already_registered}
  def register_branch(branch_id, lineage, stress)
      when is_binary(branch_id) and branch_id != "" and is_number(stress) and
             stress >= 0.0 and stress <= 1.0 do
    GenServer.call(__MODULE__, {:register, branch_id, lineage, stress})
  end

  def register_branch(branch_id, _lineage, _stress)
      when not is_binary(branch_id) or branch_id == "" do
    {:error, :invalid_branch_id}
  end

  def register_branch(_branch_id, _lineage, _stress), do: {:error, :invalid_stress}

  @doc """
  Retrieves a registered branch. Fails closed when the registry is not
  running instead of answering with placeholder evidence.
  """
  @spec get_branch(branch_id()) :: {:ok, branch()} | {:error, :not_found | :registry_unavailable}
  def get_branch(branch_id) do
    if Process.whereis(__MODULE__) do
      GenServer.call(__MODULE__, {:get, branch_id})
    else
      {:error, :registry_unavailable}
    end
  end

  @doc """
  Number of branches actually registered — measured state, not a
  placeholder (the former hardcoded `10_000 # Mock` was removed).
  """
  @spec get_active_branches() :: {:ok, non_neg_integer()} | {:error, :registry_unavailable}
  def get_active_branches do
    if Process.whereis(__MODULE__) do
      {:ok, GenServer.call(__MODULE__, :count)}
    else
      {:error, :registry_unavailable}
    end
  end

  @impl true
  def init(_opts), do: {:ok, %{branches: %{}}}

  @impl true
  def handle_call({:register, branch_id, lineage, stress}, _from, state) do
    if Map.has_key?(state.branches, branch_id) do
      {:reply, {:error, :already_registered}, state}
    else
      branch = %{
        id: branch_id,
        lineage: lineage,
        stress: stress,
        registered_at: DateTime.utc_now()
      }

      {:reply, {:ok, branch}, put_in(state, [:branches, branch_id], branch)}
    end
  end

  def handle_call({:get, branch_id}, _from, state) do
    reply =
      case Map.fetch(state.branches, branch_id) do
        {:ok, branch} -> {:ok, branch}
        :error -> {:error, :not_found}
      end

    {:reply, reply, state}
  end

  def handle_call(:count, _from, state), do: {:reply, map_size(state.branches), state}
end
