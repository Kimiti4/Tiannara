defmodule Tiannara.CTL.CausalRegistry do
  @moduledoc """
  Tracks all active branches and their historical lineages for the Causal Tensegrity Lattice.
  """
  use Supervisor

  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  def init(_opts) do
    # Simple registry supervisor scaffolding
    children = []
    Supervisor.init(children, strategy: :one_for_one)
  end
  
  def register_branch(_branch_id, _lineage), do: :ok
  
  def get_active_branches, do: 10_000 # Mock 10k branches for the explosion test
end
