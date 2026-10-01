defmodule Tiannara.Sentinel.ImmuneCoordinator do
  @moduledoc """
  Coordinates immune interventions by first simulating their effects 
  on an Epistemic Shadow-Graph before altering live reality.
  """
  use GenServer
  require Logger

  @confidence_threshold 0.85

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Triages an anomaly and determines the appropriate immune response.
  """
  def triage(anomaly) do
    GenServer.cast(__MODULE__, {:triage, anomaly})
  end

  # Callbacks

  @impl true
  def init(_opts) do
    Logger.info("🛡️ [SENTINEL] ImmuneCoordinator initialized.")
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:triage, %{type: anomaly_type, subsystem: subsystem, details: _details} = anomaly}, state) do
    case require_anomaly_evidence(anomaly) do
      :ok -> :ok
      {:error, reason} ->
        Logger.warning("🛑 [SENTINEL] Immune triage rejected: missing/invalid observation evidence: #{inspect(reason)}.")
        return_without_mutation(reason)
    end
    Logger.warning("🛡️ [SENTINEL] Triage initiated for #{anomaly_type} in #{subsystem}.")

    # 1. Generate a proposed intervention strategy
    proposed_cure = generate_intervention_strategy(anomaly_type, anomaly)

    # 2. Fork the world into a localized, accelerated Epistemic Shadow-Graph
    # For now, we simulate this as a call to the EpistemicShadowGraph module if it exists
    intervention_id = "immune-#{System.unique_integer([:positive])}"
    shadow_graph_id = fork_shadow_reality(subsystem)

    # 3. Test the cure on the Shadow-Graph
    result = Tiannara.Sentinel.EpistemicShadowGraph.validate_intervention(
      shadow_graph_id,
      proposed_cure,
      Map.get(anomaly, :telemetry, Map.get(anomaly, :details, %{}))
    )

    case result do
      {:approved, score} when score >= @confidence_threshold ->
        Logger.info("✅ [SENTINEL] Shadow simulation passed threshold (score=#{Float.round(score, 4)}); no live effect inferred.")
        request_governed_intervention(intervention_id, subsystem, proposed_cure, score, anomaly, result)
      {:rejected, score} ->
        Logger.warning("⚠️ [SENTINEL] Shadow validation rejected intervention (score=#{Float.round(score, 4)}).")
        escalate_to_quarantine(subsystem)
      {:unavailable, reason} ->
        Logger.warning("⚠️ [SENTINEL] Shadow validation unavailable: #{inspect(reason)}. No live mutation.")
        {:unavailable, reason}
    end

    destroy_shadow_reality(shadow_graph_id)
    {:noreply, state}
  end

  # Private Helpers

  defp generate_intervention_strategy(:type_a, _), do: :tighten_constraints
  defp generate_intervention_strategy(:type_b, _), do: :inject_novelty
  defp generate_intervention_strategy(:type_c, _), do: :prune_branch
  defp generate_intervention_strategy(_, _), do: :observe_only

  defp fork_shadow_reality(subsystem), do: "shadow_#{subsystem}_#{System.unique_integer()}"

  defp request_governed_intervention(intervention_id, subsystem, cure, score, anomaly, shadow_result) do
    evidence = %{
      evidence_class: :simulated,
      execution_mode: :simulation,
      source: :epistemic_shadow_graph,
      certification_eligible: false,
      intervention_id: intervention_id,
      anomaly_evidence: Map.get(anomaly, :evidence, %{}),
      shadow_validation: shadow_result,
      score: score
    }

    Logger.info("🛡️ [SENTINEL] Intervention #{inspect(cure)} for #{inspect(subsystem)} is simulation-supported only; awaiting explicit CEL/C14 authorization.")
    {:pending_authorization, %{intervention_id: intervention_id, subsystem: subsystem, cure: cure, score: score, evidence: evidence}}
  end

  defp require_anomaly_evidence(anomaly) do
    evidence = Map.get(anomaly, :evidence)
    if is_map(evidence) and
         Map.get(evidence, :evidence_class) in [:real, :simulated] and
         Map.has_key?(evidence, :source) do
      :ok
    else
      {:error, :observation_evidence_required}
    end
  end

  defp return_without_mutation(reason), do: {:noreply, %{rejected: reason}}

  defp escalate_to_quarantine(subsystem) do
    Logger.warning("🛑 [SENTINEL] Escalating #{subsystem} to quarantine.")
    :ok
  end

  defp destroy_shadow_reality(_shadow_id), do: :ok
end
