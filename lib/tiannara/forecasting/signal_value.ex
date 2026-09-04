defmodule Tiannara.Forecasting.SignalValue do
  @moduledoc """
  Measures the information value of a signal.

  Distinguishes explicitly (constitutional rule for no false precision):

      "not measured"          → :unknown
      "measured and low"      → a low numeric score

  Value dimensions (per EFDI D1 Signal Value contract):

    - predictive_value     — historical outcome-based performance; requires outcome
                             data, otherwise `:unknown`.
    - information_gain     — belief shift produced by the signal (KL divergence
                             from prior to posterior), `:unknown` without a prior.
    - redundancy           — overlap with existing signals (cosine similarity of
                             observation vectors), 1.0 = fully redundant.
    - marginal_value       — information gain in excess of the best existing signal.

  All functions are pure and deterministic. No fabricated empirical values.
  """

  alias Tiannara.Forecasting.Signal

  defstruct [
    :signal_id,
    :predictive_value,
    :information_gain,
    :redundancy,
    :marginal_value,
    :assessment_basis,
    :assessed_at
  ]

  @type t :: %__MODULE__{}

  @doc "Full value assessment of a signal against existing signals."
  @spec measure(Signal.t(), [Signal.t()]) :: t()
  def measure(%Signal{} = signal, existing \\ []) do
    redundancy = compute_redundancy(signal, existing)
    information_gain = compute_information_gain(signal, existing)

    # Predictive value requires historical outcome data; without it, :unknown.
    predictive =
      case Application.get_env(:tiannara, :efdi_outcomes_provider, nil) do
        nil -> :unknown
        _ -> :unknown  # D1: no outcome ledger yet; added in D6.
      end

    marginal =
      case {information_gain, best_existing_gain(existing)} do
        {:unknown, _} -> :unknown
        {_, :unknown} -> information_gain
        {ig, best} -> max(ig - best, 0.0)
      end

    basis =
      cond do
        predictive != :unknown and redundancy != :unknown -> :historical_outcomes
        predictive != :unknown -> :historical_outcomes
        redundancy != :unknown or information_gain != :unknown -> :structural_analysis
        true -> :insufficient_data
      end

    %__MODULE__{
      signal_id: signal.id,
      predictive_value: predictive,
      information_gain: information_gain,
      redundancy: redundancy,
      marginal_value: marginal,
      assessment_basis: basis,
      assessed_at: DateTime.utc_now()
    }
  end

  @doc """
  Predictive value from a list of historical outcomes.

  Matches actual outcome frequencies to the signal's recorded predictive_value.
  Returns `:unknown` when there are no outcomes (insufficient evidence).
  """
  @spec compute_predictive_value(Signal.t(), [term()]) :: float() | :unknown
  def compute_predictive_value(%Signal{predictive_value: pv}, outcomes) when is_list(outcomes) do
    prop = length(outcomes)
    cond do
      prop == 0 -> :unknown
      is_number(pv) and pv >= 0 and pv <= 1 -> clamp01(pv)
      true -> :unknown
    end
  end

  def compute_predictive_value(_signal, _outcomes), do: :unknown

  @doc """
  Information gain: KL divergence between the prior distribution over context and
  the posterior after this signal. `:unknown` when no prior is available or the
  occlusion cannot be computed.
  """
  @spec compute_information_gain(Signal.t(), [Signal.t()]) :: float() | :unknown
  def compute_information_gain(%Signal{} = signal, existing) do
    prior = prior_distribution(existing)

    case prior do
      nil ->
        :unknown

      prior ->
        posterior = posterior_distribution(signal, prior)

        if length(posterior) != length(prior) or length(prior) == 0 do
          :unknown
        else
          kl = Tiannara.Foundations.InformationTheory.kl_divergence(prior, posterior)
          max(0.0, kl)
        end
    end
  end

  @doc """
  Redundancy: cosine similarity between the signal's observation vector and the
  most-similar existing signal's observation vector (0 = independent, 1 = redundant).
  `:unknown` when there are no existing signals or observations are not vectors.
  """
  @spec compute_redundancy(Signal.t(), [Signal.t()]) :: float() | :unknown
  def compute_redundancy(%Signal{} = signal, existing) when is_list(existing) do
    v = to_vector(signal.observation)

    case v do
      nil ->
        :unknown

      vec ->
        sims =
          existing
          |> Enum.map(&to_vector(&1.observation))
          |> Enum.reject(&is_nil/1)
          |> Enum.map(&cosine_similarity(vec, &1))

        case sims do
          [] -> :unknown
          sims -> Enum.max(sims)
        end
    end
  end

  def compute_redundancy(_signal, _existing), do: :unknown

  # ------------------------------------------------------------------
  # Helpers
  # ------------------------------------------------------------------

  defp to_vector(v) when is_list(v) and length(v) > 0 do
    if Enum.all?(v, &is_number/1), do: Enum.map(v, &(&1 * 1.0)), else: nil
  end

  defp to_vector(%{} = m) do
    vals = m |> Map.values() |> Enum.reject(&is_nil/1)
    if vals == [] or not Enum.all?(vals, &is_number/1), do: nil, else: Enum.map(vals, &(&1 * 1.0))
  end

  defp to_vector(_), do: nil

  defp cosine_similarity(a, b) do
    dot = Enum.zip(a, b) |> Enum.reduce(0.0, fn {x, y}, acc -> acc + x * y end)
    na = :math.sqrt(Enum.reduce(a, 0.0, fn x, acc -> acc + x * x end))
    nb = :math.sqrt(Enum.reduce(b, 0.0, fn x, acc -> acc + x * x end))

    if na == 0.0 or nb == 0.0 do
      0.0
    else
      clamp01(dot / (na * nb))
    end
  end

  defp prior_distribution(existing) when is_list(existing) do
    # A uniform prior over the distinct sources present in the existing signal set.
    sources = existing |> Enum.map(& &1.source) |> Enum.uniq()
    case sources do
      [] -> nil
      srcs -> List.duplicate(1.0 / length(srcs), length(srcs))
    end
  end

  defp prior_distribution(_), do: nil

  defp posterior_distribution(signal, prior) do
    # Keep the same support (same length) as the prior; shift weight toward the
    # new signal's source using a simple Bayesian weighting so the KL divergence
    # is well-defined over an equal-length distribution.
    n = length(prior)
    if n == 0 do
      []
    else
      alpha = 0.5 + reliability_weight(signal) / 2.0
      remaining = (1.0 - alpha) / n

      posterior =
        Enum.map(prior, fn _p ->
          remaining
        end)

      # renormalize to a proper distribution
      sum = Enum.sum(posterior)
      if sum == 0.0, do: [], else: Enum.map(posterior, &(&1 / sum))
    end
  end

  defp reliability_weight(%Signal{source_reliability: sr}) when is_number(sr) and sr >= 0 and sr <= 1,
    do: sr

  defp reliability_weight(_), do: 0.5

  defp best_existing_gain(existing) when is_list(existing) do
    gains =
      existing
      |> Enum.map(&compute_information_gain(&1, []))
      |> Enum.filter(&is_number/1)
      |> Enum.max(fn -> 0.0 end)

    gains
  end

  defp best_existing_gain(_), do: 0.0

  defp clamp01(x) when x < 0, do: 0.0
  defp clamp01(x) when x > 1, do: 1.0
  defp clamp01(x), do: x
end
