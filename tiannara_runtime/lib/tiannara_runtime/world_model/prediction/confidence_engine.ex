defmodule TiannaraRuntime.WorldModel.Prediction.ConfidenceEngine do
  @moduledoc """
  Phase 17.4.3 — ConfidenceEngine: computes multi-dimensional confidence estimates
  for forecasts based on world model quality, evidence, and maturity.
  """
  @behaviour TiannaraRuntime.WorldModel.Prediction.Behaviours.ConfidenceBehaviour

  alias TiannaraRuntime.WorldModel.Ontology.WorldModel
  alias TiannaraRuntime.WorldModel.Prediction.{Forecast, ConfidenceEstimate}

  @impl true
  @spec compute(WorldModel.t(), Forecast.t(), keyword()) ::
    {:ok, ConfidenceEstimate.t()}
  def compute(%WorldModel{} = world_model, _forecast, opts \\ []) do
    eq = compute_evidence_quality(world_model)
    mm = compute_model_maturity(world_model.model_id, world_model.version)
    rs = compute_replay_stability(world_model)
    hp = compute_historical_perf(world_model)
    score = compute_overall_score(eq, mm, rs, hp)

    explanation = build_explanation(eq, mm, rs, hp)

    ConfidenceEstimate.new(
      score: score,
      evidence_quality: eq,
      model_maturity: mm,
      replay_stability: rs,
      historical_perf: hp,
      explanation: explanation,
      metadata: Keyword.get(opts, :metadata, %{})
    )
  end

  @spec compute_evidence_quality(WorldModel.t()) :: float()
  def compute_evidence_quality(%WorldModel{evidence_roots: roots, certificate: cert}) do
    evidence_score = min(length(roots) / 10.0, 1.0)

    cert_score =
      case cert do
        nil -> 0.0
        %{overall: :pass} -> 1.0
        %{overall: :fail} -> 0.3
        _ -> 0.0
      end

    (evidence_score * 0.4 + cert_score * 0.6) |> clamp()
  end

  @spec compute_model_maturity(String.t(), non_neg_integer()) :: float()
  def compute_model_maturity(_model_id, version) do
    min(version / 10.0, 1.0)
  end

  defp compute_replay_stability(%WorldModel{fingerprint: fp}) do
    case fp do
      nil -> 0.0
      _ -> 0.9
    end
  end

  defp compute_historical_perf(%WorldModel{certificate: cert}) do
    case cert do
      nil -> nil
      %{checks: checks} when is_list(checks) and checks != [] ->
        passed = Enum.count(checks, fn c -> c.status == :pass end)
        passed / length(checks)
      _ -> nil
    end
  end

  defp compute_overall_score(eq, mm, rs, hp) do
    base = eq * 0.3 + mm * 0.3 + rs * 0.2

    case hp do
      nil -> base * 1.2 |> clamp()
      hp_val -> base + hp_val * 0.2 |> clamp()
    end
  end

  defp build_explanation(eq, mm, rs, hp) do
    parts = [
      "evidence_quality: #{Float.round(eq, 3)}",
      "model_maturity: #{Float.round(mm, 3)}",
      "replay_stability: #{Float.round(rs, 3)}"
    ]

    parts =
      case hp do
        nil -> parts
        v -> parts ++ ["historical_perf: #{Float.round(v, 3)}"]
      end

    Enum.join(parts, ", ")
  end

  defp clamp(v) when v < 0.0, do: 0.0
  defp clamp(v) when v > 1.0, do: 1.0
  defp clamp(v), do: v
end
