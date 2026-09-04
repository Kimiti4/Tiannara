defmodule Tiannara.Forecasting.D5 do
  @moduledoc """
  D5 — Noise, Judgment Variability, Robustness & Sensitivity Intelligence.

  Operational layer over the certified D1–D4 substrate. D5 introduces NO new
  mathematics/engines; it composes canonical `Tiannara.Numerics`,
  `InformationTheory`, `Calibration`, and the reserved D2 `:disagreement`
  extension point. This facade is the public D5 API.

  Phase 3 implementation under EFDI_D5_CONTRACT v1.0.0 (authorized
  PHASE_3_AUTHORIZED). D5 remains strictly analytical:
    - Council authorizes, AEO executes.
    - D6 is untouched.
    - No historical D1–D4 record is modified (except the single sanctioned,
      append-only `Forecast.version/2 → register/1` path for activating
      `:disagreement`, §15.1).
  """

  alias Tiannara.Forecasting.D5.{
    Thresholds, Repetition, Budget, Perturbation, Sensitivity,
    Noise, Robustness, Regime, Temporal, Disagreement
  }

  @type d5_verdict ::
          :d5_certified_bounded | :d5_qualified_partial | :d5_not_certified

  @doc "Contract/threshold provenance for the current D5 build."
  @spec provenance() :: map()
  def provenance do
    %{
      contract_version: Thresholds.contract_version(),
      threshold_set_hash: Thresholds.threshold_set_hash(),
      thresholds: Thresholds.set_descriptor()
    }
  end

  @doc "D5 package health/status."
  @spec status() :: map()
  def status do
    %{
      package: :d5_noise_robustness_sensitivity_intelligence,
      contract_version: Thresholds.contract_version(),
      implemented: [
        :thresholds, :repetition, :budget, :perturbation, :sensitivity,
        :noise, :robustness, :regime, :temporal, :disagreement
      ],
      deferred: [:institutional_lessons]
    }
  end

  @doc "The D5 certification verdict (three-valued, never collapsed to boolean)."
  @spec verdict() :: d5_verdict()
  def verdict, do: :d5_certified_bounded

  # ------------------------------------------------------------------
  # Thresholds / provenance (single source, §14)
  # ------------------------------------------------------------------

  defdelegate contract_version(), to: Thresholds
  defdelegate threshold_set_hash(), to: Thresholds

  # ------------------------------------------------------------------
  # Repetition (§4)
  # ------------------------------------------------------------------

  defdelegate repetition(n), to: Repetition
  defdelegate repetition_classifiable?(n), to: Repetition, as: :classifiable?
  defdelegate repeat_dispersion(values), to: Repetition, as: :dispersion

  # ------------------------------------------------------------------
  # Budget (§10)
  # ------------------------------------------------------------------

  defdelegate budget_evaluate(opts), to: Budget, as: :evaluate
  defdelegate budget_allowed?(opts), to: Budget, as: :allowed?
  defdelegate closed_dimensions(), to: Budget

  # ------------------------------------------------------------------
  # Perturbation (§5)
  # ------------------------------------------------------------------

  defdelegate register_plan(attrs), to: Perturbation, as: :register
  defdelegate register_late_added_plan(attrs), to: Perturbation, as: :register_late_added
  defdelegate classify_perturbation(plan, obs), to: Perturbation, as: :classify
  defdelegate classification_eligible?(plan), to: Perturbation, as: :classification_eligible?
  defdelegate complete_plan(plan), to: Perturbation, as: :complete

  # ------------------------------------------------------------------
  # Sensitivity (§7.1)
  # ------------------------------------------------------------------

  defdelegate sensitivity(plan, opts), to: Robustness, as: :classify
  defdelegate material_delta(baseline, perturbed), to: Sensitivity, as: :delta
  defdelegate material?(baseline, perturbed, range, epsilon), to: Sensitivity
  defdelegate recommendation_flip?(base, pert), to: Sensitivity, as: :flip?

  # ------------------------------------------------------------------
  # Noise (§6)
  # ------------------------------------------------------------------

  defdelegate classify_noise(n, ci_width), to: Noise, as: :classify
  defdelegate analyze_noise(source, values, opts), to: Noise, as: :analyze
  defdelegate identify_noise_source(crossing), to: Noise, as: :identify_source
  defdelegate isolate_noise_source(crossing), to: Noise, as: :isolate
  defdelegate model_consensus(count, lineage_known), to: Noise, as: :consensus
  defdelegate bias_separation(values, reference_mean, opts), to: Noise

  # ------------------------------------------------------------------
  # Robustness (§7)
  # ------------------------------------------------------------------

  defdelegate robustness(plan, opts), to: Robustness, as: :classify
  defdelegate robustness_axes(class, confidence), to: Robustness, as: :axes
  defdelegate robustness_acceptable?(result), to: Robustness, as: :acceptable?

  # ------------------------------------------------------------------
  # Regime (§8)
  # ------------------------------------------------------------------

  defdelegate regime_tag(attrs), to: Regime, as: :tag
  defdelegate regime_aggregable?(tags, invariant), to: Regime, as: :aggregable?
  defdelegate regime_report(tags, invariant), to: Regime, as: :mismatch_report

  # ------------------------------------------------------------------
  # Temporal (§9)
  # ------------------------------------------------------------------

  defdelegate temporal_label(decision_ts, inputs), to: Temporal, as: :compute
  defdelegate temporal_write_guard(label, field), to: Temporal, as: :guarantee_write_guard

  # ------------------------------------------------------------------
  # Disagreement (§11, §15.1)
  # ------------------------------------------------------------------

  defdelegate disagreement_judgment(attrs), to: Disagreement, as: :judgment
  defdelegate disagreement_aggregate(judgments, opts), to: Disagreement, as: :aggregate
  defdelegate disagreement_count(positions, reference), to: Disagreement
  defdelegate activate_disagreement(forecast, disagreement), to: Disagreement
end