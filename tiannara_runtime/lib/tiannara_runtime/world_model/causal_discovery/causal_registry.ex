defmodule TiannaraRuntime.CausalDiscovery.CausalRegistry do
  @moduledoc """
  Phase 17.3 — CausalRegistry: ETS-backed registry for causal discovery artifacts.
  """
  @independence_table :causal_independence
  @skeleton_table :causal_skeleton
  @candidates_table :causal_candidates
  @archaeology_table :causal_archaeology
  @interventions_table :causal_interventions
  @validation_table :causal_validation
  @certificates_table :causal_certificates
  @branches_table :causal_branches

  @spec init() :: :ok
  def init do
    create_table(@independence_table)
    create_table(@skeleton_table)
    create_table(@candidates_table)
    create_table(@archaeology_table)
    create_table(@interventions_table)
    create_table(@validation_table)
    create_table(@certificates_table)
    create_table(@branches_table)
    :ok
  end

  defp create_table(name) do
    if :ets.info(name) == :undefined do
      :ets.new(name, [:set, :public, :named_table, read_concurrency: true])
    end
    :ok
  end

  @spec register(atom(), {String.t(), struct()}) :: :ok
  def register(table, {key, value}) do
    init()
    :ets.insert(table, {key, value})
    :ok
  end

  @spec lookup(atom(), String.t()) :: {:ok, struct()} | {:error, :not_found}
  def lookup(table, key) do
    init()
    case :ets.lookup(table, key) do
      [{^key, value}] -> {:ok, value}
      [] -> {:error, :not_found}
    end
  end

  @spec all(atom()) :: [struct()]
  def all(table) do
    init()
    table
    |> :ets.tab2list()
    |> Enum.map(fn {_key, value} -> value end)
  end

  @spec delete(atom(), String.t()) :: :ok
  def delete(table, key) do
    init()
    :ets.delete(table, key)
    :ok
  end
end
