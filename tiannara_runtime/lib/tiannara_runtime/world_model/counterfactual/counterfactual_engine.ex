defmodule TiannaraRuntime.WorldModel.Counterfactual.CounterfactualEngine do
  @moduledoc """
  Phase 17.5.9 — CounterfactualEngine: main orchestrator for the
  constitutional counterfactual pipeline. Delegates to InterventionExecutor,
  BranchGenerator, AlternativeTimelineBuilder, BranchComparator,
  CounterfactualReplay, CounterfactualValidation, CounterfactualArchaeology,
  and CounterfactualRegistry.
  """
  @behaviour TiannaraRuntime.WorldModel.Counterfactual.Behaviours.CounterfactualBehaviour

  alias TiannaraRuntime.WorldModel.ModelRegistry
  alias TiannaraRuntime.WorldModel.Prediction.ForecastGenerator
  alias TiannaraRuntime.WorldModel.Counterfactual.{
    CounterfactualWorld, Intervention,
    InterventionExecutor, BranchGenerator, AlternativeTimelineBuilder,
    CounterfactualReplay, CounterfactualArchaeology, CounterfactualRegistry
  }

  @impl true
  @spec create_counterfactual(String.t(), Intervention.t(), keyword()) ::
    {:ok, CounterfactualWorld.t()} | {:error, term()}
  def create_counterfactual(world_model_id, intervention, opts \\ []) do
    with {:ok, world_model} <- ModelRegistry.get_latest_model(world_model_id),
         {:ok, _executed} <- InterventionExecutor.execute(world_model, intervention),
         {:ok, branch, divergence} <- BranchGenerator.generate(world_model, intervention, opts),
         {:ok, timeline} <- AlternativeTimelineBuilder.construct(world_model, branch, divergence, opts),
         {:ok, outcomes} <- generate_outcomes(world_model, timeline, opts) do
      cf = %CounterfactualWorld{
        parent_model_id: world_model_id,
        parent_version: world_model.version,
        parent_fingerprint: world_model.fingerprint,
        intervention: intervention,
        divergence_point: divergence,
        timeline: timeline,
        outcomes: outcomes,
        assumptions: Keyword.get(opts, :assumptions, %{}),
        evidence_roots: world_model.evidence_roots || []
      }

      {:ok, validated_cf} = CounterfactualWorld.new(
        parent_model_id: cf.parent_model_id,
        parent_version: cf.parent_version,
        parent_fingerprint: cf.parent_fingerprint,
        intervention: cf.intervention,
        divergence_point: cf.divergence_point,
        timeline: cf.timeline,
        outcomes: cf.outcomes,
        assumptions: cf.assumptions,
        evidence_roots: cf.evidence_roots
      )

      fp = CounterfactualReplay.fingerprint(validated_cf)
      cf_with_fp = %{validated_cf | replay_fingerprint: fp}

      CounterfactualArchaeology.record_branch(cf_with_fp)
      CounterfactualRegistry.store(cf_with_fp)
    end
  end

  @spec get_counterfactual(String.t()) :: {:ok, CounterfactualWorld.t()} | {:error, :not_found}
  def get_counterfactual(counterfactual_id) do
    CounterfactualRegistry.get(counterfactual_id)
  end

  @spec replay_counterfactual(String.t()) :: {:ok, %{verified: boolean(), mismatches: [String.t()]}}
  def replay_counterfactual(counterfactual_id) do
    with {:ok, cf} <- CounterfactualRegistry.get(counterfactual_id) do
      {:ok, result} = CounterfactualReplay.verify(cf)

      CounterfactualArchaeology.record_replay(
        counterfactual_id,
        cf.replay_fingerprint,
        Map.get(result, :computed, cf.replay_fingerprint),
        result.verified
      )

      {:ok, result}
    end
  end

  defp generate_outcomes(world_model, _timeline, opts) do
    fv = %{name: "outcome", type: :continuous}

    case ForecastGenerator.generate(world_model, [fv], :short_term, opts) do
      {:ok, forecast} -> {:ok, [forecast]}
      {:error, _} -> {:ok, []}
    end
  end
end
