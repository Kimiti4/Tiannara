defmodule Tiannara.Forecasting.D5.Disagreement do
  @moduledoc """
  D5 Disagreement — preservation and measured disagreement (contract §11, §15.1).

  Principles:
    - Individual judgments are PRIMARY, append-only, content-addressed, and
      permanently recoverable (extends the DistributedValidationResult
      minority-position precedent to model/evaluator/perturbation analysis).
    - Aggregates are DERIVED records: method + version + input hashes recorded,
      so an independent verifier can recompute every aggregate.
    - No aggregate deletes, overwrites, or shadows an individual judgment.
    - Disagreement is preserved BEFORE aggregation and is never averaged away.
    - Agreement ≠ correctness, disagreement ≠ error (contract §16).

  Disagreement metrics reuse canonical mathematics only: Numerics.variance /
  std_dev for dispersion and InformationTheory.shannon_entropy for categorical
  spread. No new machinery here.
  """

  alias Tiannara.Forecasting.D5.{Repetition, Thresholds}
  alias Tiannara.Forecasting.Contracts.Forecast
  alias Tiannara.Forecasting.Forecast, as: ForecastEngine

  @type judgment :: %{
          entity: term(),
          kind: atom(),
          position: term(),
          confidence: number() | nil,
          lineage_known: boolean(),
          content_hash: String.t()
        }

  @doc """
  Build an individual judgment record (primary unit of preservation).
  Content-addressed via `content_hash` so individuals are permanently
  recoverable and independently recomputable.
  """
  @spec judgment(map()) :: {:ok, judgment()} | {:error, term()}
  def judgment(attrs) when is_map(attrs) or is_list(attrs) do
    m = Map.new(attrs)

    cond do
      is_nil(Map.get(m, :entity)) -> {:error, :missing_entity}
      is_nil(Map.get(m, :position)) -> {:error, :missing_position}
      true ->
        content =
          :erlang.term_to_binary(
            {Map.get(m, :entity), Map.get(m, :kind), Map.get(m, :position),
             Map.get(m, :confidence)}
          )

        j = %{
          entity: Map.get(m, :entity),
          kind: Map.get(m, :kind),
          position: Map.get(m, :position),
          confidence: Map.get(m, :confidence),
          lineage_known: Map.get(m, :lineage_known, true),
          content_hash: Base.encode16(:erlang.md5(content))
        }

        {:ok, j}
    end
  end

  @doc """
  Numeric spread across individual numeric positions/opinions (canonical
  Numerics variance/std_dev). Returns `{:error, :insufficient_samples}` when
  below what dispersion can support (n < 2).
  """
  @spec numeric_dispersion([number()]) :: {:ok, map()} | {:error, atom()}
  def numeric_dispersion(values) do
    case Repetition.dispersion(values) do
      {:ok, d} ->
        {:ok, %{variance: d.variance, std_dev: d.std_dev, n: d.n}}

      err ->
        err
    end
  end

  @doc """
  Categorical disagreement spread via Shannon entropy (canonical
  InformationTheory). Higher entropy ⇒ more categorical disagreement. Below
  TIER-2 returns `{:error, :insufficient_samples}` (per §12, UNKNOWN).
  """
  @spec categorical_spread([term()]) :: {:ok, map()} | {:error, atom()}
  def categorical_spread(labels) do
    n = length(labels)

    case Repetition.tier_for(n) do
      {:ok, :tier2} ->
        counts = Enum.frequencies(labels)
        probs = Enum.map(Map.values(counts), fn c -> c / n end)
        {:ok, %{entropy: Tiannara.Foundations.InformationTheory.shannon_entropy(probs), n: n}}

      _ ->
        {:error, :insufficient_samples}
    end
  end

  @doc """
  Count disagreement: how many individual positions differ from a reference
  (e.g. the aggregate majority or a recommended option). Returns count and
  minority membership, preserving all individuals.
  """
  @spec disagreement_count([term()], term()) :: %{count: integer(), fraction: float(), total: integer()}
  def disagreement_count(positions, reference) do
    count = Enum.count(positions, &(&1 != reference))
    total = length(positions)
    %{count: count, fraction: if(total > 0, do: count / total, else: 0.0), total: total}
  end

  @doc """
  Build a DERIVED DisagreementRecord over individual judgments. This is the
  aggregation step: it records method + version + input hashes so an
  independent verifier can recompute the aggregate from the individuals.
  Individuals are NEVER modified or removed.

  Options (`method` must be a permitted §11 method):
    - :numeric_metric   :dispersion | :entropy | nil
    - reference value for counting.
  """
  @spec aggregate([judgment()], map()) :: {:ok, map()} | {:error, term()}
  def aggregate(judgments, opts \\ %{}) when is_list(judgments) do
    if judgments == [] do
      {:error, :no_judgments}
    else
      numeric = Enum.map(judgments, &numeric_position(&1))
      labels = Enum.map(judgments, &(&1.position))
      hashes = Enum.map(judgments, & &1.content_hash)

      reference = Map.get(opts, :reference)
      count =
        if reference != nil, do: disagreement_count(labels, reference), else: nil

      record = %{
        method: Map.get(opts, :method, :median),
        version: "1",
        input_hashes: hashes,
        n: length(judgments),
        numeric_aggregate: aggregate_numeric(numeric, Map.get(opts, :method, :median)),
        dispersion: aggregate_dispersion(numeric),
        disagreement_count: count,
        minority_preserved: true,
        individuals_recoverable: true
      }

      case validate_method(record) do
        :ok -> {:ok, record}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Activate the reserved D2 `Forecast.disagreement` extension point via the
  ONLY sanctioned append-only write path (contract §15.1):
    Forecast.version/2 → ForecastRegistry.register/1

  This produces a NEW immutable D2 Forecast version whose lineage records the
  prior forecast and whose `forecast_version` bumps. The original forecast is
  never rewritten.
  """
  @spec activate_disagreement(Forecast.t(), map()) :: {:ok, Forecast.t()} | {:error, term()}
  def activate_disagreement(%Forecast{} = base, disagreement) do
    new_version =
      ForecastEngine.version(base, %{
        disagreement: disagreement
      })

    case Tiannara.Forecasting.ForecastRegistry.register(new_version) do
      {:ok, registered} -> {:ok, registered}
      {:error, reason} -> {:error, reason}
    end
  end

  # ------------------------------------------------------------------
  # Private
  # ------------------------------------------------------------------

  defp numeric_position(%{position: p}) when is_number(p), do: p
  defp numeric_position(_), do: nil

  defp aggregate_numeric(numeric, :median) do
    nums = Enum.reject(numeric, &is_nil/1)
    if nums == [], do: :unknown, else: median(nums)
  end

  defp aggregate_numeric(_, _), do: :unknown

  defp aggregate_dispersion(numeric) do
    nums = Enum.reject(numeric, &is_nil/1)

    case Repetition.dispersion(nums) do
      {:ok, d} -> %{std_dev: d.std_dev, variance: d.variance, n: d.n}
      _ -> :unknown
    end
  end

  defp median(nums) do
    sorted = Enum.sort(nums)
    len = length(sorted)
    mid = div(len, 2)

    if rem(len, 2) == 0 do
      (Enum.at(sorted, mid - 1) + Enum.at(sorted, mid)) / 2
    else
      Enum.at(sorted, mid)
    end
  end

  defp validate_method(%{method: method}) do
    if Thresholds.permitted_aggregation?(method),
      do: :ok,
      else: {:error, :invalid_aggregation_method}
  end
end
