defmodule Tiannara.Forecasting.D5.Noise do
  @moduledoc """
  D5 Noise — "when is variability legitimately noise?" (contract §6).

  Central epistemic rule (enforced here structurally):
    - Noise is unwanted variability under IRRELEVANT perturbation.
    - Sensitivity is variability under RELEVANT perturbation.
    They are distinguished by the plan's legitimacy declaration (§6.1), not by
    the measured variance. VARIANCE ≠ NOISE is enforced, not asserted.

  Identifiability gate (§6.2): a source estimate exists ONLY if the crossing
  structure isolates it. An unisolated source's field is UNKNOWN — no
  borrowing, no imputation. Bias (§6.4) is separate and requires a directional
  reference (D2 calibration at portfolio scale, or a declared reference class);
  without one, BIAS_STATUS = UNKNOWN.

  All dispersion reuses the canonical `Tiannara.Numerics` substrate and
  `Tiannara.Foundations.InformationTheory`. No new statistics here.
  """

  alias Tiannara.Forecasting.D5.{Repetition, Thresholds}

  @doc """
  Classify a noise magnitude from the (normalized) confidence-interval width of
  the estimator, applying the frozen §6.3 bands. The band is applied to a CI
  width, never to a bare point estimate.
  """
  @spec classify(pos_integer(), float() | nil) :: atom()
  def classify(n, ci_width) do
    case Repetition.tier_for(n) do
      {:ok, :tier0} ->
        :unknown

      {:ok, :tier1} ->
        # Provisional only; NO classification permitted.
        :unknown

      {:ok, :tier2} when is_number(ci_width) ->
        band(ci_width)

      _ ->
        :unknown
    end
  end

  @doc """
  Identify the attributable source from a crossing structure (§6.2). Returns
  `{:ok, source}` if exactly one source is isolated and repeated enough, else
  `{:error, :not_identified}` (field must be UNKNOWN).
  """
  @spec identify_source(map()) :: {:ok, atom()} | {:error, atom()}
  def identify_source(%{crossing: crossing, n: n}) do
    with {:ok, :tier2} <- Repetition.tier_for(n),
         {:ok, source} <- isolate(crossing) do
      {:ok, source}
    else
      _ -> {:error, :not_identified}
    end
  end

  @doc """
  Isolate a single attributable source from a crossing structure. Exactly one
  declaration key with a fixed-other design isolates it; multi-source or
  non-orthogonal crossings fail.
  """
  @spec isolate(map() | list()) :: {:ok, atom()} | {:error, :not_identified | :invalid}
  def isolate(%{} = crossing) do
    isolate(Map.to_list(crossing))
  end

  def isolate(list) when is_list(list) do
    varying =
      Enum.filter(list, fn {_k, v} ->
        v != [] and is_list(v)
      end)

    case varying do
      [{dim, _}] -> {:ok, dim}
      _ -> {:error, :not_identified}
    end
  end

  def isolate(_), do: {:error, :invalid}

  @doc """
  Model-consensus integrity (§6.5). Consensus strength is reported with lineage
  metadata. If ANY model has unknown lineage → MODEL_CONSENSUS_STRENGTH =
  UNKNOWN (no numeric effective count may be emitted).
  """
  @spec consensus(integer(), [boolean()]) :: map()
  def consensus(model_count, lineage_known_list) do
    if model_count <= 1 do
      %{consensus_strength: :unknown, reason: :single_model,
        effective_independent_count: :unknown}
    else
      all_known = Enum.all?(lineage_known_list, &(&1 == true))

      if all_known do
        %{consensus_strength: consensus_strength(model_count),
          effective_independent_count: model_count,
          lineage: :all_known}
      else
        %{consensus_strength: :unknown, reason: :unknown_lineage,
          effective_independent_count: :unknown}
      end
    end
  end

  @doc """
  Bias vs noise separation (§6.4). Bias requires a directional reference (mean
  or base-rate). Without one, BIAS_STATUS = UNKNOWN. With one, reports Cohen's d
  magnitude (canonical Numerics) and flags consistent directional deviation.
  """
  @spec bias_separation([number()], number() | nil, map() | nil) :: map()
  def bias_separation(values, reference_mean, opts \\ nil) do
    n = length(values)

    case Repetition.tier_for(n) do
      {:ok, :tier2} when is_number(reference_mean) ->
        sample_mean = Enum.sum(values) / n
        d = cohens_d_one_sample(values, reference_mean)
        direction = cond do
          d > 0.2 -> :positive_deviation
          d < -0.2 -> :negative_deviation
          true -> :centered
        end

        %{
          bias_status: :measured,
          cohens_d: d,
          sample_mean: sample_mean,
          reference_mean: reference_mean,
          direction: direction,
          reference_type: Map.get(opts || %{}, :reference_type, :declared_base_rate),
          n: n
        }

      _ ->
        %{
          bias_status: :unknown,
          reference_mean: reference_mean,
          reason: if(is_number(reference_mean), do: :insufficient_samples, else: :no_directional_reference),
          n: n
        }
    end
  end

  @doc """
  Distributional shift between baseline and perturbed output distributions via
  canonical KL divergence (InformationTheory). Returns `{:ok, kl, n}` or
  `{:error, :insufficient_samples}` below TIER-2 (per §3 / §12, metric is
  UNKNOWN below minimum sample).
  """
  @spec distributional_shift([float()], [float()]) :: {:ok, %{kl: float(), n: integer()}} | {:error, atom()}
  def distributional_shift(p, q) do
    n = length(p)

    case Repetition.tier_for(n) do
      {:ok, :tier2} ->
        kl = Tiannara.Foundations.InformationTheory.kl_divergence(p, q)
        {:ok, %{kl: kl, n: n}}

      {:ok, :tier1} ->
        {:error, :insufficient_samples}

      _ ->
        {:error, :insufficient_samples}
    end
  end

  @doc """
  Categorical dispersion of outcome/opinion labels via canonical Shannon
  entropy (InformationTheory). Below TIER-2 returns `{:error, :insufficient_samples}`.
  """
  @spec categorical_dispersion([term()]) :: {:ok, %{entropy: float(), n: integer()}} | {:error, atom()}
  def categorical_dispersion(labels) do
    n = length(labels)

    case Repetition.tier_for(n) do
      {:ok, :tier2} ->
        counts = Enum.frequencies(labels)
        probs = Enum.map(Map.values(counts), fn c -> c / n end)
        entropy = Tiannara.Foundations.InformationTheory.shannon_entropy(probs)
        {:ok, %{entropy: entropy, n: n}}

      _ ->
        {:error, :insufficient_samples}
    end
  end

  @doc """
  A synthetic end-to-end noise analysis for one source given a set of
  identical-rerun numeric outputs (occasion/sampling variability, §6.2
  "identical reruns"), returning a full finding with forced UNKNOWN states for
  unisolated/under-powered sources.

  Options:
    - `:source`     the isolated source (e.g. :evaluator, :model, :evidence_order)
    - `:reference_mean` for bias separation (optional)
  """
  @spec analyze(atom(), [number()], map()) :: map()
  def analyze(source, values, opts \\ %{}) do
    n = length(values)
    tier = case Repetition.tier_for(n) do
      {:ok, t} -> t
      _ -> :tier0
    end

    dispersion =
      case Repetition.dispersion(values) do
        {:ok, d} -> d
        _ -> nil
      end

    # Normalized CI width of the std-dev estimator (relative), from §4.2.
    mean =
      case dispersion do
        %{n: n} when is_integer(n) and n > 0 -> Enum.sum(values) / n
        _ -> nil
      end

    ci_width =
      case {dispersion, mean} do
        {%{std_dev: sd}, m} when is_number(sd) and is_number(m) and m > 0 and sd >= 0 ->
          sd / m * 1.96 / :math.sqrt(2 * (n - 1))

        _ ->
          nil
      end

    noise_class = classify(n, ci_width)

    %{
      source: source,
      n: n,
      tier: tier,
      classifiable: tier == :tier2,
      noise_class: noise_class,
      ci_width: ci_width,
      dispersion: dispersion,
      bias: bias_separation(values, Map.get(opts, :reference_mean)),
      contract_version: Thresholds.contract_version(),
      threshold_set_hash: Thresholds.threshold_set_hash()
    }
  end

  # ------------------------------------------------------------------
  # Private
  # ------------------------------------------------------------------

  defp band(ci_width) do
    cond do
      ci_width <= Thresholds.noise_negligible_ci_width() -> :negligible
      ci_width <= Thresholds.noise_low_ci_width() -> :low
      ci_width <= Thresholds.noise_moderate_ci_width() -> :moderate
      true -> :high
    end
  end

  defp consensus_strength(count) when count >= 5, do: :strong
  defp consensus_strength(count) when count >= 3, do: :moderate
  defp consensus_strength(_), do: :weak

  defp cohens_d_one_sample(values, mu) do
    n = length(values)
    mean = Enum.sum(values) / n
    sd =
      case Tiannara.Numerics.std_dev(values) do
        {:ok, s} -> s
        _ -> 0.0
      end

    if sd > 0 do
      (mean - mu) / sd
    else
      0.0
    end
  end
end
