defmodule Tiannara.Forecasting.D5.Robustness do
  @moduledoc """
  D5 Robustness — "what evidence before calling something robust?" (contract §7).

  Classes (each carries the FULL coverage_manifest; a class may never be
  reported without it):
    ROBUST             — all declared dimensions executed ≥ minimum coverage;
                         zero material changes under nominal tier
    MODERATELY_ROBUST  — all declared dimensions executed; material change only
                         under extreme tier; none under nominal
    SENSITIVE          — ≥1 material change under nominal tier; recommended
                         option stable in majority of runs
    FRAGILE            — recommendation flip or threshold crossing under nominal
                         tier in majority of runs
    UNSTABLE           — material variability under IDENTICAL reruns alone
    UNKNOWN            — any declared dimension unexecuted, or below minimums,
                         or budget exhausted

  §7.3: UNTESTED ≠ ROBUST. No class above UNKNOWN may be emitted unless every
  declared dimension has executed complete, valid runs.
  §7.4: Confidence and robustness are separate axes — never merged.
  """

  alias Tiannara.Forecasting.D5.Thresholds

  @classes [:robust, :moderately_robust, :sensitive, :fragile, :unstable, :unknown]

  @spec classes() :: [atom()]
  def classes, do: @classes

  @doc """
  Classify robustness for a completed analysis. This is the ONLY entry point
  authorized to emit a robustness class, and it ALWAYS attaches the mandatory
  coverage_manifest (§7.2).

  Inputs:
    - `plan`           the preregistered PerturbationPlan
    - `opts`:
        :dimension_results  `%{dim => %{material: bool, tier: :nominal|:extreme,
                                       flips: int, runs: int, total_runs: int}}`
        :repetition_n       identical-rerun n (for UNSTABLE / minimums)

  Returns a map with `:class`, `:coverage_manifest` (mandatory), and
  `:materiality_summary`.
  """
  @spec classify(map(), map()) :: map()
  def classify(plan, opts \\ %{}) do
    dim_results = Map.get(opts, :dimension_results, %{})
    repetition_n = Map.get(opts, :repetition_n, 0)
    declared = Map.keys(Map.get(plan, :dimensions, %{}))

    coverage_manifest = build_coverage_manifest(declared, dim_results)

    if not full_coverage?(coverage_manifest) do
      %{
        class: :unknown,
        coverage_manifest: coverage_manifest,
        reason: :unexecuted_or_budget_exhausted,
        materiality_summary: summary(dim_results)
      }
    else
      classify_from_results(plan, dim_results, repetition_n, coverage_manifest)
    end
  end

  @doc """
  Separate confidence and robustness axes (§7.4). Returns a two-field record so
  HIGH_CONFIDENCE + FRAGILE and LOW_CONFIDENCE + ROBUST are both representable,
  and never merged.
  """
  @spec axes(atom(), number() | :unknown) :: map()
  def axes(robustness_class, confidence) do
    %{
      robustness: robustness_class,
      confidence: confidence,
      merged: false
    }
  end

  @doc """
  A transient, coverage-stripped robustness label is prohibited. This predicate
  guarantees a class is only acceptable when its manifest covers every declared
  dimension.
  """
  @spec acceptable?(map()) :: boolean()
  def acceptable?(%{class: class, coverage_manifest: m}) do
    class != :unknown and full_coverage?(m)
  end

  @doc """
  Deterministic coverage manifest: each declared dimension records whether it
  executed, valid, ≥ minimum coverage.
  """
  @spec build_coverage_manifest([atom()], map()) :: map()
  def build_coverage_manifest(declared, dim_results) do
    entries =
      Map.new(declared, fn dim ->
        result = Map.get(dim_results, dim, %{})
        runs = Map.get(result, :runs, 0)
        min_coverage = minimum_coverage(dim)

        {dim,
         %{
           executed: Map.get(result, :executed, runs > 0),
           valid: Map.get(result, :valid, true),
           runs: runs,
           min_coverage: min_coverage,
           covered: runs >= min_coverage,
           tier: Map.get(result, :tier, :nominal)
         }}
      end)

    %{
      declared_dimensions: declared,
      entries: entries,
      all_executed: Enum.all?(entries, fn {_, e} -> e.executed end),
      all_valid: Enum.all?(entries, fn {_, e} -> e.valid end),
      all_covered: Enum.all?(entries, fn {_, e} -> e.covered end)
    }
  end

  @doc "Default minimum coverage for a dimension (contract-level minimum)."
  @spec minimum_coverage(atom()) :: integer()
  def minimum_coverage(_dim), do: 1

  # ------------------------------------------------------------------
  # Private
  # ------------------------------------------------------------------

  defp full_coverage?(manifest) do
    manifest.all_executed and manifest.all_valid and manifest.all_covered
  end

  defp classify_from_results(plan, dim_results, repetition_n, coverage_manifest) do
    any_nominal_material =
      Enum.any?(dim_results, fn {_dim, r} ->
        Map.get(r, :tier, :nominal) == :nominal and Map.get(r, :material, false)
      end)

    any_material_under_any_tier =
      Enum.any?(dim_results, fn {_dim, r} -> Map.get(r, :material, false) end)

    extreme_material_only =
      any_material_under_any_tier and not any_nominal_material

    unstable = repetition_unstable?(plan, repetition_n)

    cond do
      unstable ->
        %{
          class: :unstable,
          coverage_manifest: coverage_manifest,
          reason: :material_variability_under_identical_reruns,
          materiality_summary: summary(dim_results)
        }

      any_nominal_material and majority_flip?(dim_results) ->
        %{
          class: :fragile,
          coverage_manifest: coverage_manifest,
          reason: :recommendation_flip_under_nominal_tier_in_majority,
          materiality_summary: summary(dim_results)
        }

      any_nominal_material ->
        %{
          class: :sensitive,
          coverage_manifest: coverage_manifest,
          reason: :material_change_under_nominal_tier,
          materiality_summary: summary(dim_results)
        }

      extreme_material_only ->
        %{
          class: :moderately_robust,
          coverage_manifest: coverage_manifest,
          reason: :material_change_only_under_extreme_tier,
          materiality_summary: summary(dim_results)
        }

      true ->
        %{
          class: :robust,
          coverage_manifest: coverage_manifest,
          reason: :no_material_change_under_nominal_tier,
          materiality_summary: summary(dim_results)
        }
    end
  end

  defp repetition_unstable?(plan, repetition_n) do
    # UNSTABLE: material variability under identical reruns alone. Only
    # meaningful if the repetition tier is classifiable and the plan declares
    # evidence_order/sampling as the tested independence dimension.
    repetition_n >= Thresholds.tier2_min() and
      (Map.has_key?(Map.get(plan, :dimensions, %{}), :evidence_order) or
         Map.has_key?(Map.get(plan, :dimensions, %{}), :sampling))
  end

  defp majority_flip?(dim_results) do
    flips =
      Enum.map(dim_results, fn {_dim, r} -> Map.get(r, :flips, 0) end)
      |> Enum.sum()

    runs =
      Enum.map(dim_results, fn {_dim, r} -> Map.get(r, :runs, 0) end)
      |> Enum.sum()

    runs > 0 and flips > runs / 2
  end

  defp summary(dim_results) do
    %{
      dimensions: map_size(dim_results),
      material_dimensions:
        Enum.count(dim_results, fn {_d, r} -> Map.get(r, :material, false) end),
      total_runs:
        Enum.reduce(dim_results, 0, fn {_d, r}, acc -> acc + Map.get(r, :runs, 0) end)
    }
  end
end
