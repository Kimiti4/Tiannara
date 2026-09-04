defmodule Tiannara.CEL.Services.Priority.LearningModel do
  @num_features 5

  defstruct mean: List.duplicate(0.5, @num_features),
            variance: List.duplicate(1.0, @num_features),
            noise_variance: 0.1,
            n: 0

  def init_weights do
    %__MODULE__{}
  end

  def update_weights(weights, feature_vector, target) do
    pred = predict(weights.mean, feature_vector)
    error = target - pred
    noise_v = weights.noise_variance

    updates =
      [weights.mean, weights.variance, feature_vector]
      |> Enum.zip()
      |> Enum.map(fn {m, v, x} ->
        gain = v * x / (v * x * x + noise_v + 1.0e-10)
        new_m = m + gain * error
        new_v = (1.0 - gain * x) * v + 1.0e-8
        {new_m, new_v}
      end)

    {new_mean, new_variance} = Enum.unzip(updates)

    %{weights | mean: new_mean, variance: new_variance, n: weights.n + 1}
  end

  def predict_with_uncertainty(weights, feature_vector) do
    pred = predict(weights.mean, feature_vector)

    var =
      Enum.zip_with(weights.variance, feature_vector, fn v, x -> v * x * x end)
      |> Enum.sum()
      |> Kernel.+(weights.noise_variance)

    std_dev = :math.sqrt(var)
    {pred, pred - 1.96 * std_dev, pred + 1.96 * std_dev}
  end

  def calibration_score(weights, calibration_data) do
    case calibration_data do
      [] -> 1.0
      data ->
        errors =
          Enum.map(data, fn {fv, target} ->
            {pred, _lo, _hi} = predict_with_uncertainty(weights, fv)
            abs(pred - target)
          end)

        mae = Enum.sum(errors) / length(errors)
        1.0 - min(mae, 1.0)
    end
  end

  def extract_features(signal) do
    [
      signal.confidence,
      signal.evidence_count / max(1, signal.evidence_count + 1),
      1.0 / (1.0 + (avg_duration(signal.durations) / 1000.0)),
      if(signal.outcome == :success, do: 1.0, else: 0.0),
      length(Enum.uniq(signal.step_types)) / max(1, length(signal.step_types) + 1)
    ]
  end

  defp predict(mean, features) do
    Enum.zip_with(mean, features, fn w, x -> w * x end) |> Enum.sum()
  end

  defp learning_rate(n), do: 1.0 / (1.0 + n)
  defp avg_duration([]), do: 0
  defp avg_duration(durs), do: Enum.sum(durs) / length(durs)
end
