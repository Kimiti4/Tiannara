defmodule Tiannara.ASC.Reality.Artifact do
  @moduledoc """
  Minimal deployment-artifact contract at the Director boundary.

  Producers vary in how much epistemic metadata they carry:

    * load-spike / stub harness -> %{name, version, payload: %{data: ...}}
    * Phase-8 delivery          -> %{name, version, payload: %{...}, uncertainty_level: :low}
    * manual deploys            -> arbitrary maps

  Consumers (RiskAssessment, Safety, Compliance, Rollout) must not crash on
  absent fields. Normalize ONCE at the boundary so every downstream consumer
  sees a consistent artifact.

  Missing uncertainty is a neutral prior 0.5 ("unknown") — absence surfaced as
  agnostic, never as certainty.
  """

  @defaults %{uncertainty_level: 0.5, real_world_interaction: false, metadata: %{}}

  @doc """
  Fills absent contract fields with neutral defaults.

  Accepts either a bare `%{name, version, payload}` (the load-spike shape) or
  a richer artifact. Never raises.
  """
  def normalize(artifact) when is_map(artifact) do
    Enum.reduce(@defaults, artifact, fn {key, default}, acc ->
      case Map.get(acc, key) do
        nil -> Map.put(acc, key, default)
        other -> acc
      end
    end)
  end

  def normalize(other) when is_binary(other) do
    normalize(%{name: "unwrapped", version: "0", payload: %{data: other}})
  end

  def normalize(other) when is_list(other) do
    normalize(%{name: "bulk", version: "0", payload: %{items: other}})
  end
end
