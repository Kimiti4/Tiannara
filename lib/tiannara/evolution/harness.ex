defmodule Tiannara.Evolution.Harness do
  @moduledoc """
  The Ω-Horizon validation layer. Orchestrates repeated evolutionary cycles,
  enforcing the drift audit and preserving lineage.

  It evaluates proposed improvements against a baseline state, applies the
  Ω Capstone validation, performs the four-dimensional drift audit, and
  yields a lineage of accepted and rejected cycles.

  Constitutional basis: Evolution Framework, "Every architectural decision
  should remain traceable", Verification First, "Capability must never outpace
  verification."
  """

  alias Tiannara.Evolution.{Cycle, Metrics, DriftAudit}

  @doc """
  Runs a sequence of proposed improvements against a baseline state.
  Returns the lineage of cycles (accepted and rejected).
  """
  def run_cycles(initial_state, proposals, opts \\ []) do
    initial_metrics = Keyword.get(opts, :initial_metrics, %Metrics{})
    initial_version = Keyword.get(opts, :system_version, "0.0.0")

    {lineage, _current_state, _current_metrics, _current_version} =
      Enum.reduce(proposals, {[], initial_state, initial_metrics, initial_version}, fn
        proposal, {acc, state, metrics, version} ->
          cycle = evaluate_proposal(proposal, state, metrics, version, length(acc))

          # Only advance state/metrics/version if the cycle was accepted
          new_state = if cycle.decision == :accepted, do: proposal.next_state, else: state
          new_metrics = if cycle.decision == :accepted, do: cycle.metrics_after, else: metrics
          new_version = if cycle.decision == :accepted, do: proposal.new_version, else: version

          {acc ++ [cycle], new_state, new_metrics, new_version}
      end)

    lineage
  end

  defp evaluate_proposal(proposal, current_state, current_metrics, current_version, index) do
    # 1. Run the Ω Capstone (simulated here via proposal.capstone_result)
    capstone = proposal.capstone_result

    # 2. Measure the new state
    after_metrics = proposal.metrics_after

    # 3. Perform the drift audit
    audit_result = DriftAudit.audit(current_metrics, after_metrics, Map.get(proposal, :audit_opts, []))

    # 4. Synthesize the final decision (Capstone + Drift Audit must both pass)
    {decision, drift_metrics, reasons} =
      case audit_result do
        {:accepted, drift} ->
          if capstone.certified? do
            {:accepted, drift, []}
          else
            {:rejected, drift, [:capstone_not_certified]}
          end

        {:rejected, %{reasons: r, drift: d}} ->
          {:rejected, d, r}
      end

    %Cycle{
      cycle_id: :"cycle_#{index + 1}",
      parent_cycle_id: if(index == 0, do: nil, else: :"cycle_#{index}"),
      system_version: current_version,
      constitutional_version: proposal.constitutional_version,
      experiment_id: proposal.experiment_id,
      hypothesis_id: proposal.hypothesis_id,
      proposal_id: proposal.id,
      patch_id: proposal.patch_id,
      evidence_ids: proposal.evidence_ids,
      test_results: capstone.test_results,
      certification_result: capstone.certification_result,
      decision: decision,
      metrics_before: current_metrics,
      metrics_after: after_metrics,
      drift_metrics: drift_metrics,
      rejection_reasons: reasons,
      rejected_alternatives: proposal.rejected_alternatives,
      rollback_state: current_state,
      timestamp: System.system_time(:second)
    }
  end
end