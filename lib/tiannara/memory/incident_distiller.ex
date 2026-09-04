defmodule Tiannara.Memory.IncidentDistiller do
  @moduledoc """
  Distills a completed incident dossier into durable Tiannara knowledge by
  promoting it up the memory ladder — offline, evidence-gated, with lineage.

  Worked example for the corruption incident:

      Observation → Evidence → Cause → Intervention → Validation → Principle

  A single incident reaches :principle only when the dossier supplies each
  rung's evidence. Missing evidence halts promotion and names the gap — it
  never fabricates a principle.
  """

  alias Tiannara.Memory.{Artifact, PromotionPipeline}

  @doc """
  Dossier keys: :observation :context :evidence :cause :recurrence :mechanism
  :intervention :validation :principle :source
  """
  def distill(dossier, target \\ :principle) do
    initial =
      Artifact.new(:data, Map.get(dossier, :observation, ""),
        evidence: %{source: Map.get(dossier, :source, :incident_log)}
      )

    case PromotionPipeline.promote(initial, target, build_evidence(dossier)) do
      {:ok, artifact} -> {:ok, %{artifact | content: Map.get(dossier, target, dossier.observation)}}
      halted -> halted
    end
  end

  defp build_evidence(d) do
    %{
      information: %{
        source: Map.get(d, :source, :incident_log),
        context: Map.get(d, :context) || Map.get(d, :observation)
      },
      knowledge: %{corroboration: Map.get(d, :evidence), content: Map.get(d, :cause)},
      pattern: %{recurrence: Map.get(d, :recurrence)},
      model: %{mechanism: Map.get(d, :mechanism) || Map.get(d, :cause)},
      principle: %{
        generalization: Map.get(d, :principle),
        validation: Map.get(d, :validation),
        content: Map.get(d, :principle)
      }
    }
  end
end
