defmodule Tiannara.Evolution.LongHorizon do
  @moduledoc """
  Closed-loop, multi-cycle evolutionary validation harness.

  Repeatedly runs the governed improvement pipeline across N generations,
  applying accepted improvements forward and rejecting the rest, while
  preserving full lineage. This answers the question a single DryRun cannot:

      "Does Tiannara continue producing net validated improvement across many
       generations, or does optimization eventually produce stagnation,
       monoculture, regressions, epistemic drift, or governance degradation?"

  The `generator` is injectable (Replaceability): in production it is wired to
  the real Ω.2/Ω.4 pipeline; in validation it is a deterministic function that
  models improving, stagnating, or degrading behavior.

  Constitutional basis: Evolution Framework, Verification First, "Capability
  must never outpace verification", "Every architectural decision should remain
  traceable", Continuous Self-Evaluation.
  """

  alias Tiannara.Evolution.{Cycle, Metrics, DriftAudit, Trajectory}

  @doc """
  Runs `cycles` generations. `generator.(state, index)` must return a proposal
  map with `:metrics_after`, `:capstone_result`, and lineage fields. Returns
  `%{lineage: [Cycle.t()], trajectory: map}`.
  """
  def run(initial_state, opts) do
    cycles = Keyword.get(opts, :cycles, 10)
    generator = Keyword.fetch!(opts, :generator)
    initial_metrics = Keyword.get(opts, :initial_metrics, %Metrics{})
    initial_version = Keyword.get(opts, :system_version, "0.0.0")
    audit_opts = Keyword.get(opts, :audit_opts, [])

    {lineage, _final} =
      Enum.reduce(1..cycles, {[], %{state: initial_state, metrics: initial_metrics, version: initial_version}}, fn
        index, {acc, cur} ->
          proposal = generator.(cur.state, index)
          parent_id = parent_cycle_id(acc)

          cycle =
            evaluate_cycle(proposal, cur, index, parent_id, audit_opts)

          cur = advance_state(cur, cycle, proposal)
          {acc ++ [cycle], cur}
      end)

    %{lineage: lineage, trajectory: Trajectory.analyze(lineage)}
  end

  # --- internals ----------------------------------------------------------

  defp parent_cycle_id([]), do: nil
  defp parent_cycle_id(acc), do: List.last(acc).cycle_id

  defp evaluate_cycle(proposal, cur, index, parent_id, audit_opts) do
    capstone = proposal.capstone_result
    audit_result = DriftAudit.audit(cur.metrics, proposal.metrics_after, audit_opts)

    {decision, drift_metrics, reasons} =
      case audit_result do
        {:accepted, drift} ->
          if capstone.certified?,
            do: {:accepted, drift, []},
            else: {:rejected, drift, [:capstone_not_certified]}


        {:rejected, %{reasons: r, drift: d}} ->
          {:rejected, d, r}
      end

    %Cycle{
      cycle_id: :"cycle-#{index}",
      parent_cycle_id: parent_id,
      system_version: cur.version,
      constitutional_version: Map.get(proposal, :constitutional_version, "1.0.0"),
      experiment_id: Map.get(proposal, :experiment_id),
      hypothesis_id: Map.get(proposal, :hypothesis_id),
      proposal_id: Map.get(proposal, :id),
      patch_id: Map.get(proposal, :patch_id),
      evidence_ids: Map.get(proposal, :evidence_ids, []),
      test_results: capstone.test_results,
      certification_result: capstone.certification_result,
      decision: decision,
      metrics_before: cur.metrics,
      metrics_after: proposal.metrics_after,
      drift_metrics: drift_metrics,
      rejection_reasons: reasons,
      rejected_alternatives: Map.get(proposal, :rejected_alternatives, []),
      rollback_state: cur.state,
      timestamp: System.system_time(:second)
    }
  end

  # Only accepted cycles advance state/metrics/version.
  defp advance_state(cur, %Cycle{decision: :accepted}, proposal) do
    %{
      state: Map.get(proposal, :next_state, cur.state),
      metrics: proposal.metrics_after,
      version: Map.get(proposal, :new_version, cur.version)
    }
  end

  defp advance_state(cur, %Cycle{decision: :rejected}, _proposal), do: cur
end