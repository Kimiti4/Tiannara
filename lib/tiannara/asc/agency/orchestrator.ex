defmodule Tiannara.ASC.Agency.Orchestrator do
  require Logger

  @moduledoc """
  Evidence-bound research-cycle orchestrator.

  This module does not manufacture observations, hypotheses, experiments, or
  results. A cycle can only run when real observation and experiment providers
  are supplied by the caller/runtime.
  """

  def request_cycle(context, reason) do
    Task.Supervisor.start_child(Tiannara.ExtrusionTaskSupervisor, fn ->
      run_cycle(context, reason)
    end)
  end

  def run_cycle(context, reason) do
    with {:ok, observations} <- observe(context),
         {:ok, hypotheses} <- hypothesize(observations, context),
         {:ok, results} <- run_experiments(hypotheses, context),
         {:ok, integrated} <- integrate(results, context) do
      Logger.info("[Orchestrator] Evidence-bound cycle complete: #{inspect(reason)}")
      {:ok, %{reason: reason, observations: observations, hypotheses: hypotheses,
              results: results, integration: integrated}}
    else
      {:error, _} = error -> error
    end
  end

  defp observe(context) do
    case Map.get(context, :observation_provider) do
      provider when is_function(provider, 1) ->
        case provider.(context) do
          {:ok, observations} when is_list(observations) and observations != [] ->
            {:ok, observations}
          {:ok, []} -> {:error, :no_observations}
          other -> {:error, {:invalid_observation_provider_result, other}}
        end
      _ ->
        {:error, :observation_backend_unavailable}
    end
  end

  defp hypothesize(observations, context) do
    case Map.get(context, :hypothesis_provider) do
      provider when is_function(provider, 2) ->
        case provider.(observations, context) do
          {:ok, hypotheses} when is_list(hypotheses) and hypotheses != [] ->
            {:ok, hypotheses}
          {:ok, []} -> {:error, :no_hypotheses}
          other -> {:error, {:invalid_hypothesis_provider_result, other}}
        end
      _ ->
        {:error, :hypothesis_backend_unavailable}
    end
  end

  defp run_experiments(hypotheses, context) do
    case Map.get(context, :experiment_provider) do
      provider when is_function(provider, 2) ->
        Enum.reduce_while(hypotheses, {:ok, []}, fn hypothesis, {:ok, acc} ->
          case provider.(hypothesis, context) do
            {:ok, result} -> {:cont, {:ok, [result | acc]}}
            {:error, reason} -> {:halt, {:error, {:experiment_failed, hypothesis, reason}}}
            other -> {:halt, {:error, {:invalid_experiment_result, other}}}
          end
        end)
        |> case do
          {:ok, results} when results != [] -> {:ok, Enum.reverse(results)}
          {:ok, []} -> {:error, :no_experiment_results}
          error -> error
        end
      _ ->
        {:error, :experiment_backend_unavailable}
    end
  end

  defp integrate(results, context) do
    case Map.get(context, :integration_provider) do
      provider when is_function(provider, 2) ->
        case provider.(results, context) do
          {:ok, value} -> {:ok, value}
          {:error, reason} -> {:error, {:integration_failed, reason}}
          other -> {:error, {:invalid_integration_result, other}}
        end
      _ ->
        {:error, :knowledge_integration_backend_unavailable}
    end
  end
end
