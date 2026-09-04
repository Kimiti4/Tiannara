defmodule Tiannara.Forecasting.D5.Repetition do
  @moduledoc """
  D5 Repetition — "what constitutes sufficient repetition?" (contract §4).

  Repeated-judgment mechanics: a RunSet of identical reruns measures
  occasion/sampling variability. Repetition DEPTH (identical reruns) and
  REPEATED_EVIDENCE state are tracked here; source attribution (breadth) is the
  province of D5.Noise.

  Epistemic rules enforced:
    - n = 1 NEVER supports any noise, stability, or robustness claim.
    - TIER-0  n < 5   → no estimate permitted; all noise fields UNKNOWN.
    - TIER-1  5 ≤ n < 32 → PROVISIONAL estimate only; NO classification.
    - TIER-2  n ≥ 32   → classifiable.
  The n = 32 justification lives in D5.Thresholds (frozen, §14).
  """

  alias Tiannara.Forecasting.D5.Thresholds

  @type tier :: :tier0 | :tier1 | :tier2

  @spec tier_for(integer()) :: {:ok, tier()} | {:error, atom()}
  def tier_for(n) when is_integer(n) and n >= 0, do: {:ok, Thresholds.tier(n)}
  def tier_for(_), do: {:error, :invalid_n}

  @doc """
  Whether an estimate may be *classified* (as opposed to barely reported).
  Only TIER-2 permits classification.
  """
  @spec classifiable?(integer()) :: boolean()
  def classifiable?(n), do: Thresholds.tier(n) == :tier2

  @doc """
  Whether an estimate may be *reported* at all. TIER-1 reports a PROVISIONAL
  estimate but forbids classification; TIER-0 reports nothing.
  """
  @spec reportable?(integer()) :: boolean()
  def reportable?(n) when is_integer(n), do: Thresholds.tier(n) in [:tier1, :tier2]
  def reportable?(_), do: false

  @doc """
  Repetition state for a RunSet (R3 §2). Returns a map describing whether the
  evidence is repeated, the tier, and the forced noise/propagation fields.
  """
  @spec describe(pos_integer()) :: map()
  def describe(n) when is_integer(n) and n >= 0 do
    tier = Thresholds.tier(n)

    %{
      n: n,
      repeated: n > 1,
      single_observation: n <= 1,
      tier: tier,
      classifiable: tier == :tier2,
      provisional: tier == :tier1,
      estimate_permitted: tier in [:tier1, :tier2],
      forced_state: forced_state(tier)
    }
  end

  defp forced_state(:tier0), do: :no_estimate_permitted
  defp forced_state(:tier1), do: :provisional_only_no_classification
  defp forced_state(:tier2), do: :classifiable

  @doc """
  Sample variance and standard deviation of a set of identical-rerun numeric
  outputs, using ONLY the canonical `Tiannara.Numerics` substrate (variance
  n-1, std_dev). Returns `{:error, :insufficient_samples}` for n < 2 per the
  substrate. All D5 dispersion must route through this.
  """
  @spec dispersion([number()]) :: {:ok, %{variance: number(), std_dev: number(), n: integer()}}
          | {:error, atom()}
  def dispersion(values) when is_list(values) and length(values) < 2,
    do: {:error, :insufficient_samples}

  def dispersion(values) when is_list(values) do
    with {:ok, var} <- Tiannara.Numerics.variance(values),
         {:ok, sd} <- Tiannara.Numerics.std_dev(values) do
      {:ok, %{variance: var, std_dev: sd, n: length(values)}}
    end
  end

  def dispersion(_), do: {:error, :invalid_input}
end
