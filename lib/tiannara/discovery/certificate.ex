defmodule Tiannara.Discovery.Certificate do
  @moduledoc """
  The pre-soak "Discovery Guarantee" certificate.

  States, with evidence, whether a fertile epistemic environment actually
  yields a validated discovery and whether the funnel is complete (no silent
  loss). This is the artifact that makes a future `0 discoveries` result
  interpretable.

  Constitutional basis: Verification First, Evidence Before Confidence.
  """

  alias Tiannara.Funnel.Integrity

  defstruct [
    :observations,
    :gaps,
    :hypotheses,
    :predictions,
    :experiments_proposed,
    :experiments_executed,
    :evidence,
    :knowledge_integrations,
    :discovery_candidates,
    :validated_discoveries,
    :funnel_completeness,
    :silent_losses,
    :verdict
  ]

  def issue(run) do
    integrity = Integrity.verify(run.events)
    s = integrity.stages

    created = fn stage -> (Map.get(s, stage) || %{created: 0}).created end

    total_created = s |> Map.values() |> Enum.map(& &1.created) |> Enum.sum()
    total_unexplained = s |> Map.values() |> Enum.map(& &1.unexplained) |> Enum.sum()

    completeness =
      if total_created == 0 do
        0.0
      else
        Float.round((total_created - total_unexplained) / total_created * 100, 1)
      end

    verdict =
      cond do
        total_unexplained > 0 -> :silent_loss
        integrity.diagnosis == :blocked -> :blocked
        created.(:validated_discoveries) > 0 -> :discovery_generated
        true -> :no_discovery
      end

    %__MODULE__{
      observations: created.(:observations),
      gaps: created.(:gaps),
      hypotheses: created.(:hypotheses),
      predictions: created.(:ranked_hypotheses),
      experiments_proposed: created.(:experiments_proposed),
      experiments_executed: created.(:experiments_completed),
      evidence: created.(:evidence_generated),
      knowledge_integrations: created.(:knowledge_integrated),
      discovery_candidates: created.(:discovery_candidates),
      validated_discoveries: created.(:validated_discoveries),
      funnel_completeness: completeness,
      silent_losses: total_unexplained,
      verdict: verdict
    }
  end

  def render(%__MODULE__{} = c) do
    """
    Observations             #{c.observations}
    Gaps                     #{c.gaps}
    Hypotheses               #{c.hypotheses}
    Predictions              #{c.predictions}
    Experiments proposed     #{c.experiments_proposed}
    Experiments executed     #{c.experiments_executed}
    Evidence                 #{c.evidence}
    Knowledge integrations   #{c.knowledge_integrations}
    Discovery candidates     #{c.discovery_candidates}
    Validated discoveries    #{c.validated_discoveries}

    Funnel completeness      #{c.funnel_completeness}%
    Silent losses            #{c.silent_losses}

    VERDICT: #{c.verdict}
    """
  end
end
