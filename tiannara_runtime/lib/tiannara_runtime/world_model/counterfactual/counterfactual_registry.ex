defmodule TiannaraRuntime.WorldModel.Counterfactual.CounterfactualRegistry do
  @moduledoc """
  Phase 17.5.9 — CounterfactualRegistry: ETS-backed registry for storing
  and retrieving counterfactual worlds and branch nodes.
  """
  alias TiannaraRuntime.WorldModel.Counterfactual.CounterfactualWorld

  @registry_table :counterfactual_store

  @spec store(CounterfactualWorld.t()) :: {:ok, CounterfactualWorld.t()}
  def store(%CounterfactualWorld{} = cf) do
    init_table()
    :ets.insert(@registry_table, {cf.counterfactual_id, cf})
    :ets.insert(@registry_table, {{:by_model, cf.parent_model_id}, cf.counterfactual_id})
    {:ok, cf}
  end

  @spec get(String.t()) :: {:ok, CounterfactualWorld.t()} | {:error, :not_found}
  def get(counterfactual_id) do
    init_table()
    case :ets.lookup(@registry_table, counterfactual_id) do
      [{^counterfactual_id, cf}] -> {:ok, cf}
      [] -> {:error, :not_found}
    end
  end

  @spec list_by_model(String.t()) :: {:ok, [CounterfactualWorld.t()]}
  def list_by_model(model_id) do
    init_table()

    ids =
      @registry_table
      |> :ets.tab2list()
      |> Enum.filter(fn {key, _} -> match?({:by_model, _}, key) and elem(key, 1) == model_id end)
      |> Enum.map(fn {_, id} -> id end)

    cfs =
      ids
      |> Enum.map(fn id -> :ets.lookup(@registry_table, id) end)
      |> Enum.filter(fn [{_, _}] -> true; _ -> false end)
      |> Enum.map(fn [{_, cf}] -> cf end)

    {:ok, cfs}
  end

  @spec count() :: non_neg_integer()
  def count do
    init_table()
    @registry_table
    |> :ets.tab2list()
    |> Enum.count(fn {key, _} -> is_binary(key) and String.starts_with?(key, "cf_") end)
  end

  def init_table do
    if :ets.info(@registry_table) == :undefined do
      :ets.new(@registry_table, [:set, :public, :named_table, read_concurrency: true])
    end
    :ok
  end

  def reset_table do
    if :ets.info(@registry_table) != :undefined do
      :ets.delete(@registry_table)
    end
    init_table()
    :ok
  end
end
