defmodule Tiannara.Forecasting.D5.Thresholds do
  @moduledoc """
  D5 Thresholds — the single authoritative source of every quantitative
  threshold in the EFDI D5 contract (v1.0.0, §14 anti-threshold-laundering).

  Constitutional guarantees:
    - These constants live HERE, nowhere else. Foregoing modules and any
      analysis code READ them; none may redefine them.
    - Thresholds are frozen at contract authorization time. Changing any
      threshold requires a new D5 contract version plus a new authorization.
    - Every classification must cite `threshold_version/0` (the contract
      version) and `threshold_set_hash/0` so the independent verifier can
      recompute against the cited set and detect post-hoc substitution.

  Values mirror EFDI_D5_CONTRACT.md v1.0.0:
    §4  repetition tiers (n bounds + n=32 TIER-2 justification)
    §6  noise class bands (applied to the estimator CI)
    §7  materiality (ε_material as fraction of decision-relevant range)
    §10 budgets (MAX_RUNS etc.)
    §11 aggregation method set
  """

  @contract_version "1.0.0"

  # ------------------------------------------------------------------
  # §4 — Repetition tiers
  # ------------------------------------------------------------------

  @tier0_max 5
  @tier1_min 5
  @tier1_max 31
  @tier2_min 32

  # recorded justification for n = 32 (contract §4.2)
  @tier2_justification """
  For a standard-deviation estimator under a documented normality assumption,
  the 95% CI relative half-width ≈ 1.96/sqrt(2(n-1)) ≈ 25% at n = 32. Below
  this a noise classification would rest on an estimate whose own uncertainty
  exceeds the classification granularity.
  """

  # ------------------------------------------------------------------
  # §6 — Noise class bands (applied to the estimator CI)
  # ------------------------------------------------------------------
  # Bands interpret the estimator's confidence interval span (or point
  # estimate scaled form) to separate NEGLIGIBLE/LOW/MODERATE/HIGH/UNKNOWN.

  @noise_negligible_ci_width 0.05
  @noise_low_ci_width 0.10
  @noise_moderate_ci_width 0.25

  # ------------------------------------------------------------------
  # §7 — Sensitivity materiality
  # ------------------------------------------------------------------
  # ε_material default = 10% of the declared decision-relevant range.

  @epsilon_material_fraction 0.10

  # ------------------------------------------------------------------
  # §10 — Computational budgets (enforced pre-execution)
  # ------------------------------------------------------------------

  @max_runs_per_analysis 512
  @max_variants_per_dimension 8
  @max_models_per_analysis 6
  @max_evaluators_per_analysis 6
  @max_perturbation_dimensions 5

  # ------------------------------------------------------------------
  # §11 — Permitted aggregation methods (closed set)
  # ------------------------------------------------------------------

  @aggregation_methods [:median, :trimmed_mean, :linear_pool, :rank_aggregation]

  # ------------------------------------------------------------------
  # API
  # ------------------------------------------------------------------

  @spec contract_version() :: String.t()
  def contract_version, do: @contract_version

  @spec threshold_set_hash() :: String.t()
  def threshold_set_hash do
    # Stable content hash of the frozen threshold tuple. Changing any frozen
    # constant changes this hash, making post-hoc substitution detectable by
    # the independent verifier.
    content =
      :erlang.term_to_binary(
        {@tier0_max, @tier1_min, @tier1_max, @tier2_min,
         @noise_negligible_ci_width, @noise_low_ci_width, @noise_moderate_ci_width,
         @epsilon_material_fraction,
         @max_runs_per_analysis, @max_variants_per_dimension, @max_models_per_analysis,
         @max_evaluators_per_analysis, @max_perturbation_dimensions,
         @aggregation_methods}
      )

    Base.encode16(:erlang.md5(content))
  end

  @spec tier(integer()) :: :tier0 | :tier1 | :tier2
  def tier(n) when is_integer(n) and n < @tier0_max, do: :tier0
  def tier(n) when is_integer(n) and n < @tier2_min, do: :tier1
  def tier(n) when is_integer(n), do: :tier2

  @spec tier0_max() :: integer()
  def tier0_max, do: @tier0_max
  @spec tier1_min() :: integer()
  def tier1_min, do: @tier1_min
  @spec tier1_max() :: integer()
  def tier1_max, do: @tier1_max
  @spec tier2_min() :: integer()
  def tier2_min, do: @tier2_min
  @spec tier2_justification() :: String.t()
  def tier2_justification, do: @tier2_justification

  @spec noise_negligible_ci_width() :: float()
  def noise_negligible_ci_width, do: @noise_negligible_ci_width
  @spec noise_low_ci_width() :: float()
  def noise_low_ci_width, do: @noise_low_ci_width
  @spec noise_moderate_ci_width() :: float()
  def noise_moderate_ci_width, do: @noise_moderate_ci_width

  @spec epsilon_material_fraction() :: float()
  def epsilon_material_fraction, do: @epsilon_material_fraction

  @spec max_runs_per_analysis() :: integer()
  def max_runs_per_analysis, do: @max_runs_per_analysis
  @spec max_variants_per_dimension() :: integer()
  def max_variants_per_dimension, do: @max_variants_per_dimension
  @spec max_models_per_analysis() :: integer()
  def max_models_per_analysis, do: @max_models_per_analysis
  @spec max_evaluators_per_analysis() :: integer()
  def max_evaluators_per_analysis, do: @max_evaluators_per_analysis
  @spec max_perturbation_dimensions() :: integer()
  def max_perturbation_dimensions, do: @max_perturbation_dimensions

  @spec aggregation_methods() :: [atom()]
  def aggregation_methods, do: @aggregation_methods

  @spec permitted_aggregation?(atom()) :: boolean()
  def permitted_aggregation?(method), do: method in @aggregation_methods

  @doc "Deterministic threshold set descriptor for citations."
  @spec set_descriptor() :: map()
  def set_descriptor do
    %{
      contract_version: @contract_version,
      threshold_set_hash: threshold_set_hash(),
      tier: %{tier0_max: @tier0_max, tier1_min: @tier1_min, tier1_max: @tier1_max, tier2_min: @tier2_min},
      noise_ci_widths: %{
        negligible: @noise_negligible_ci_width,
        low: @noise_low_ci_width,
        moderate: @noise_moderate_ci_width
      },
      epsilon_material_fraction: @epsilon_material_fraction,
      budgets: %{
        max_runs_per_analysis: @max_runs_per_analysis,
        max_variants_per_dimension: @max_variants_per_dimension,
        max_models_per_analysis: @max_models_per_analysis,
        max_evaluators_per_analysis: @max_evaluators_per_analysis,
        max_perturbation_dimensions: @max_perturbation_dimensions
      },
      aggregation_methods: @aggregation_methods
    }
  end
end
