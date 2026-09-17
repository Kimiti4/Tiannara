defmodule TiannaraRuntime.WorldModel.Pipeline.ModelValidation do
  @moduledoc """
  Phase 17.2 — Model Validation (Pipeline Stage 7).

  Validates a world model against held-out evidence by computing
  prediction accuracy metrics.
  """

  @behaviour TiannaraRuntime.WorldModel.Behaviours.Pipeline

  alias TiannaraRuntime.WorldModel.ModelRegistry
  alias TiannaraRuntime.WorldModel.Ontology.{
    WorldModel,
    Evidence,
    ValidationEvidence
  }

  @impl true
  @spec validate_model(WorldModel.t(), map()) :: {:ok, [ValidationEvidence.t()]} | {:error, String.t()}
  def validate_model(%WorldModel{model_id: mid, version: ver} = model, evidence_set) do
    observations = extract_observations(evidence_set)
    var_map = build_variable_map(model)

    rmse = compute_rmse(var_map, observations)
    log_likelihood = compute_log_likelihood(var_map, observations)
    coverage = compute_coverage(var_map, observations)

    now = DateTime.utc_now() |> DateTime.to_iso8601()

    metrics = [
      %ValidationEvidence{
        validation_id: "val_" <> (:crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)),
        model_id: mid,
        model_version: ver,
        metric: :rmse,
        value: rmse,
        threshold: 1.0,
        passed: rmse <= 1.0,
        created_at: now
      },
      %ValidationEvidence{
        validation_id: "val_" <> (:crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)),
        model_id: mid,
        model_version: ver,
        metric: :log_likelihood,
        value: log_likelihood,
        threshold: -1.0,
        passed: log_likelihood >= -1.0,
        created_at: now
      },
      %ValidationEvidence{
        validation_id: "val_" <> (:crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)),
        model_id: mid,
        model_version: ver,
        metric: :coverage,
        value: coverage,
        threshold: 0.9,
        passed: coverage >= 0.9,
        created_at: now
      }
    ]

    ModelRegistry.transition_status(mid, ver, :validated)

    {:ok, metrics}
  end

  defp extract_observations(%Evidence{observations: obs}) when is_list(obs), do: obs
  defp extract_observations(%{observations: obs}) when is_list(obs), do: obs
  defp extract_observations(_), do: []

  defp build_variable_map(%WorldModel{variables: vars, parameters: params}) do
    param_map =
      Enum.reduce(params, %{}, fn p, acc ->
        Map.put(acc, p.name, %{predicted: p.value, bounds: p.bounds})
      end)

    Enum.reduce(vars, param_map, fn v, acc ->
      if Map.has_key?(acc, v.name) do
        acc
      else
        predicted = predict_from_domain(v)
        Map.put(acc, v.name, %{predicted: predicted, bounds: v.domain})
      end
    end)
  end

  defp predict_from_domain(%{type: :continuous, domain: {lo, hi}}) when is_number(lo) and is_number(hi),
    do: (lo + hi) / 2.0
  defp predict_from_domain(%{type: :discrete, domain: {lo, hi}}) when is_number(lo) and is_number(hi),
    do: div(floor((lo + hi) / 2.0), 1)
  defp predict_from_domain(%{type: :categorical, domain: [first | _]}), do: first
  defp predict_from_domain(_), do: 0.0

  defp compute_rmse(var_map, observations) when observations == [], do: 0.0
  defp compute_rmse(var_map, observations) do
    squared_errors =
      observations
      |> Enum.flat_map(fn obs ->
        var_map
        |> Enum.filter(fn {vname, _} -> is_map_key(obs, vname) end)
        |> Enum.map(fn {vname, %{predicted: pred}} ->
          actual = Map.get(obs, vname)
          if is_number(actual) and is_number(pred) do
            (pred - actual) * (pred - actual)
          end
        end)
      end)
      |> Enum.reject(&is_nil/1)

    case squared_errors do
      [] -> 0.0
      errs -> :math.sqrt(Enum.sum(errs) / length(errs))
    end
  end

  defp compute_log_likelihood(var_map, observations) when observations == [], do: 0.0
  defp compute_log_likelihood(var_map, observations) do
    likelihoods =
      observations
      |> Enum.flat_map(fn obs ->
        var_map
        |> Enum.filter(fn {vname, _} -> is_map_key(obs, vname) end)
        |> Enum.map(fn {vname, %{predicted: pred, bounds: bounds}} ->
          actual = Map.get(obs, vname)
          if is_number(actual) and is_number(pred) do
            sigma = infer_sigma(bounds)
            -0.5 * :math.log(2.0 * :math.pi()) - :math.log(sigma) -
              0.5 * ((actual - pred) / sigma) * ((actual - pred) / sigma)
          end
        end)
      end)
      |> Enum.reject(&is_nil/1)

    case likelihoods do
      [] -> 0.0
      lls -> Enum.sum(lls) / length(lls)
    end
  end

  defp infer_sigma(nil), do: 1.0
  defp infer_sigma({lo, hi}) when is_number(lo) and is_number(hi) and hi > lo,
    do: (hi - lo) / 6.0
  defp infer_sigma(_), do: 1.0

  defp compute_coverage(_var_map, observations) when observations == [], do: 1.0
  defp compute_coverage(var_map, observations) do
    results =
      observations
      |> Enum.flat_map(fn obs ->
        var_map
        |> Enum.filter(fn {vname, _} -> is_map_key(obs, vname) end)
        |> Enum.map(fn {vname, %{predicted: pred, bounds: bounds}} ->
          actual = Map.get(obs, vname)
          if is_number(actual) and is_number(pred) do
            covered?(actual, bounds)
          end
        end)
      end)
      |> Enum.reject(&is_nil/1)

    case results do
      [] -> 1.0
      bools ->
        covered_count = Enum.count(bools, & &1)
        covered_count / length(bools)
    end
  end

  defp covered?(_actual, nil), do: true
  defp covered?(actual, {lo, hi}) when is_number(lo) and is_number(hi),
    do: actual >= lo and actual <= hi
  defp covered?(_actual, _), do: true
end
