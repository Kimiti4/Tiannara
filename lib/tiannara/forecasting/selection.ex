defmodule Tiannara.Forecasting.Selection do
  @moduledoc """
  D4 survivorship / selection analysis.

  Analyzes how a population of candidates was reduced to a sample and records
  the denominator status. When the denominator is unknown, the selection effect
  is first-class `:unknown` and generalization scope is capped to the observed
  population — a report can never silently generalize over an unknown
  denominator.

  Constitutional rules:
    - `:unknown` denominator is distinct from zero observed loss; both are
      reported, never collapsed.
    - a survivorship flag raises the selection mechanism to `:survivorship`
      even when observation was nominally random.
  """

  alias Tiannara.Forecasting.Contracts.SelectionEffectReport

  @mechanisms [
    :random,
    :selected,
    :self_selected,
    :survivorship,
    :availability,
    :publication,
    :unknown
  ]

  @type t :: SelectionEffectReport.t()

  @doc """
  Analyzes a candidate population.

  `population` is a list of candidate maps:
      %{id: term(), admitted?: boolean(), mechanism: atom() | nil}

  or a single map:
      %{population_size: non_neg_integer(), sample_size: non_neg_integer(), mechanism: atom() | nil}

  opts:
    - `:evidence_flags`  additional detection_flags (e.g. attribution samples)
    - `:scope`           forced generalization scope override
  """
  @spec analyze(list() | map(), map() | Keyword.t()) :: SelectionEffectReport.t()
  def analyze(population, opts \\ []) when is_map(opts) or is_list(opts) do
    o = Map.new(opts)

    case population do
      %{population_size: ps, sample_size: ss} ->
        {ds, scope} = generalize(ps, ss)

        build(%{
          mechanism: Map.get(population, :mechanism, :unknown),
          denominator_status: ds,
          population_size: ps,
          sample_size: ss,
          flags: scope_flags(scope, ds),
          scope: Map.get(o, :scope, scope)
        })

      list when is_list(list) ->
        {mechanism, flags} = detect_from_candidates(list)
        ps = length(list)
        ss = Enum.count(list, &Map.get(&1, :admitted?, false))
        {ds, scope} = generalize(ps, ss)

        build(%{
          mechanism: method(mechanism, flags),
          denominator_status: ds,
          population_size: ps,
          sample_size: ss,
          flags: flags,
          scope: Map.get(o, :scope, scope)
        })

      _ ->
        build(%{
          mechanism: :unknown,
          denominator_status: :unknown,
          population_size: :unknown,
          sample_size: :unknown,
          flags: [:malformed_population],
          scope: :unknown
        })
    end
  end

  @doc """
  Raised selection effect for analyses that compare a surviving sample against
  a self-reported denominator: scope is capped and the mechanism is at best
  `:selected`.
  """
  @spec raise_survivorship(SelectionEffectReport.t()) :: SelectionEffectReport.t()
  def raise_survivorship(%SelectionEffectReport{denominator_status: :unknown} = r) do
    %{r | mechanism: :survivorship, generalization_scope: :unknown}
  end

  def raise_survivorship(%SelectionEffectReport{} = r), do: r

  @doc """
  Selecting from an unknown-denominator report returns `{:error,
  :denominator_unknown}` rather than silently generalizing.
  """
  @spec select_from(SelectionEffectReport.t()) :: {:ok, map()} | {:error, term()}
  def select_from(%SelectionEffectReport{denominator_status: :unknown}) do
    {:error, :denominator_unknown}
  end

  def select_from(%SelectionEffectReport{} = r) do
    {:ok, %{sample_size: r.sample_size, population_size: r.population_size}}
  end

  @doc false
  def mechanisms, do: @mechanisms

  # ------------------------------------------------------------------
  # Helpers
  # ------------------------------------------------------------------

  defp build(m) do
    %SelectionEffectReport{
      report_id: "sel_" <> Tiannara.Executive.Types.new_id(),
      selection_mechanism: m.mechanism,
      denominator_status: m.denominator_status,
      population_size: m.population_size,
      sample_size: m.sample_size,
      generalization_scope: m.scope,
      detection_flags: m.flags,
      created_at: DateTime.utc_now()
    }
  end

  defp detect_from_candidates(list) do
    mechanisms =
      Enum.flat_map(list, fn c ->
        case Map.get(c, :mechanism) do
          m when m in [:survivorship, :availability, :publication, :self_selected] -> [m]
          _ -> []
        end
      end)
      |> Enum.uniq()

    present =
      Enum.count(list, fn c ->
        Map.get(c, :present?, Map.get(c, :admitted?, nil))
      end)

    absent = length(list) - present
    flags = mechanisms ++ if(absent > 0 and present > 0, do: [:observed_attrition], else: [])

    mechanism =
      cond do
        :survivorship in mechanisms -> :survivorship
        mechanisms != [] -> hd(mechanisms)
        absent > 0 -> :selected
        true -> :random
      end

    {mechanism, flags}
  end

  defp denominator_status(:unknown, _ss), do: :unknown

  defp denominator_status(ps, ss) when is_number(ps) and is_number(ss) and ps >= ss and ss > 0,
    do: :known

  defp denominator_status(_ps, ss) when not is_number(ss) and ss != :unknown, do: :unknown
  defp denominator_status(ps, ss) when is_number(ps) and is_number(ss) and ss > ps, do: :partial
  defp denominator_status(ps, ss) when is_number(ps) and is_number(ss) and ps > 0 and ss == 0,
    do: :known

  defp denominator_status(_ps, _ss), do: :unknown

  defp generalization_scope(ps, ss) when is_number(ps) and is_number(ss) and ps >= ss and ss > 0,
    do: :observed_population

  defp generalization_scope(_ps, _ss), do: :unknown

  defp generalize(:unknown, _ss), do: {:unknown, :flagged}

  defp generalize(ps, ss) when is_number(ps) and is_number(ss) and ss > ps,
    do: {:partial, :flagged}

  defp generalize(ps, ss) when is_number(ps) and is_number(ss) and ss >= 0, do: {:known, :observed_population}
  defp generalize(_ps, _ss), do: {:unknown, :flagged}

  defp method(:unknown, []), do: :unknown
  defp method(m, _flags) when m != :unknown and m != :random, do: m
  defp method(:random, [_ | _]), do: :selected
  defp method(:random, []), do: :random
  defp method(:unknown, flags), do: hd(flags)

  defp scope_flags(:flagged, _ds), do: [:flagged]
  defp scope_flags(_scope, _ds), do: []
end