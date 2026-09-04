defmodule Tiannara.Forecasting.D5.Regime do
  @moduledoc """
  D5 Regime — "when are results invalid to aggregate?" (contract §8).

  Every analysis carries a RegimeTag. Each regime dimension is declared
  SENSITIVE or INVARIANT for the analysis template. Aggregating results whose
  RegimeTags differ on any SENSITIVE dimension is prohibited: aggregate =
  UNKNOWN and `REGIME_MISMATCH` is recorded. Robustness demonstrated in one
  regime never transfers to another.
  """

  @regime_dimensions [:temporal, :environmental, :domain, :population, :system_version, :model_version]

  @type regime_dimension :: atom()

  @doc "All regime dimensions."
  @spec dimensions() :: [:temporal | :environmental | :domain | :population | :system_version | :model_version]
  def dimensions, do: @regime_dimensions

  @doc "Build a RegimeTag."
  @spec tag(map()) :: map()
  def tag(attrs) when is_map(attrs) or is_list(attrs) do
    m = Map.new(attrs)

    %{
      temporal: Map.get(m, :temporal),
      environmental: Map.get(m, :environmental),
      domain: Map.get(m, :domain),
      population: Map.get(m, :population),
      system_version: Map.get(m, :system_version),
      model_version: Map.get(m, :model_version)
    }
  end

  @doc """
  Register which regime dimensions are SENSITIVE for an analysis template.
  Default: all are sensitive unless declared INVARIANT. Unknown names are
  ignored safely by list difference.
  """
  @spec sensitive_dimensions([atom()]) :: [atom()]
  def sensitive_dimensions(invariant_list \\ []) do
    @regime_dimensions -- invariant_list
  end

  @doc """
  Aggregate-safety check across multiple RegimeTags: results may be aggregated
  if no two tags differ on any SENSITIVE dimension for the given template.
  Otherwise the aggregate is UNKNOWN and `REGIME_MISMATCH` is recorded.
  """
  @spec aggregable?([map()], [atom()]) :: {:ok, map()} | {:error, :regime_mismatch}
  def aggregable?(tags, invariant_list \\ []) when is_list(tags) do
    if tags == [] do
      {:error, :regime_mismatch}
    else
      sens = sensitive_dimensions(invariant_list)
      mismatches = collect_mismatches(tags, sens)

      if mismatches == [] do
        {:ok, %{regime_consistent: true, sensitive_dimensions: sens}}
      else
        {:error, :regime_mismatch}
      end
    end
  end

  @doc """
  Cross-regime transfer is prohibited (§8.3): a tag proven robust in regime A
  never transfers to regime B. This predicate returns false unless the two tags
  fully agree on the template's sensitive dimensions.
  """
  @spec transferable?(map(), map(), [atom()]) :: boolean()
  def transferable?(from_tag, to_tag, invariant_list \\ []) do
    case aggregable?([from_tag, to_tag], invariant_list) do
      {:ok, _} -> true
      _ -> false
    end
  end

  @doc "Full mismatch report for audit completeness."
  @spec mismatch_report([map()], [atom()]) :: map()
  def mismatch_report(tags, invariant_list \\ []) do
    sens = sensitive_dimensions(invariant_list)

    %{
      tags: tags,
      sensitive_dimensions: sens,
      mismatches: collect_mismatches(tags, sens),
      verdict: if(collect_mismatches(tags, sens) == [], do: :aggregable, else: :regime_mismatch)
    }
  end

  # ------------------------------------------------------------------
  # Private
  # ------------------------------------------------------------------

  defp collect_mismatches(tags, sens) do
    Enum.reduce(sens, [], fn dim, acc ->
      values = Enum.map(tags, &Map.get(&1, dim))
      if length(Enum.uniq(values)) > 1, do: [dim | acc], else: acc
    end)
    |> Enum.uniq()
  end
end