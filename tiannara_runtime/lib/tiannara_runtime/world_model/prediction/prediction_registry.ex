defmodule TiannaraRuntime.WorldModel.Prediction.PredictionRegistry do
  @moduledoc """
  Phase 17.4.9 — PredictionRegistry: ETS-backed registry for storing and
  retrieving predictions by ID and world model.
  """
  alias TiannaraRuntime.WorldModel.Prediction.Prediction

  @registry_table :prediction_store

  @spec store_prediction(Prediction.t()) :: {:ok, Prediction.t()}
  def store_prediction(%Prediction{} = prediction) do
    init_table()
    :ets.insert(@registry_table, {prediction.prediction_id, prediction})

    :ets.insert(@registry_table, {{:by_model, prediction.world_model_id}, prediction.prediction_id})
    {:ok, prediction}
  end

  @spec get_prediction(String.t()) :: {:ok, Prediction.t()} | {:error, :not_found}
  def get_prediction(prediction_id) do
    init_table()

    case :ets.lookup(@registry_table, prediction_id) do
      [{^prediction_id, prediction}] -> {:ok, prediction}
      [] -> {:error, :not_found}
    end
  end

  @spec list_by_model(String.t()) :: {:ok, [Prediction.t()]}
  def list_by_model(model_id) do
    init_table()

    ids =
      @registry_table
      |> :ets.tab2list()
      |> Enum.filter(fn {key, _} -> is_by_model_key?(key) and elem(key, 1) == model_id end)
      |> Enum.map(fn {_, pid} -> pid end)

    predictions =
      ids
      |> Enum.map(fn pid -> :ets.lookup(@registry_table, pid) end)
      |> Enum.filter(fn [{_, _}] -> true; _ -> false end)
      |> Enum.map(fn [{_, p}] -> p end)

    {:ok, predictions}
  end

  @spec get_latest_by_model(String.t()) :: {:ok, Prediction.t()} | {:error, :not_found}
  def get_latest_by_model(model_id) do
    with {:ok, predictions} <- list_by_model(model_id) do
      case Enum.sort_by(predictions, & &1.created_at, :desc) do
        [latest | _] -> {:ok, latest}
        [] -> {:error, :not_found}
      end
    end
  end

  @spec count() :: non_neg_integer()
  def count do
    init_table()

    @registry_table
    |> :ets.tab2list()
    |> Enum.count(fn {key, _} -> is_prediction_key?(key) end)
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

  defp is_prediction_key?(key) when is_binary(key), do: String.starts_with?(key, "pr_")
  defp is_prediction_key?(_), do: false

  defp is_by_model_key?({:by_model, _}), do: true
  defp is_by_model_key?(_), do: false
end
