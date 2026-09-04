defmodule Tiannara.Omega.CapabilityAudit do
  @moduledoc """
  Read-only JARVIS capability audit.

  Derives the emergent-capability audit (P0/P1/P2 traits + meta-metrics) from
  DISK ARTIFACTS ONLY: hourly ControlCenter operations reports, the hash-chained
  lineage store, and constitutional-persistence checkpoint presence. It never
  attaches to the running node, never extends the EventBus, never starts a
  process.

  Anything not derivable from artifacts is reported :not_measured; uncertainty
  is never hidden.

  Constitutional basis: Observability; Continuous Self-Evaluation; "Never
  optimize for appearing correct. Optimize for being correct."; "Uncertainty
  should never be hidden."
  """

  alias Tiannara.Lineage.Store

  defstruct capabilities: %{}, meta_metrics: %{}, synthesis: [], not_measured: []

  @doc """
  artifacts:
    * :operations_reports - parsed hourly ControlCenter report maps
    * :lineage_entries    - [%Tiannara.Lineage.Entry{}]
    * :cpl_checkpoints    - integer count of constitutional checkpoints on disk
  """
  def audit(artifacts) do
    reports = Map.get(artifacts, :operations_reports, [])
    lineage = Map.get(artifacts, :lineage_entries, [])
    cpl = Map.get(artifacts, :cpl_checkpoints, 0)

    caps = %{
      situational_awareness: situational_awareness(reports, lineage),
      goal_persistence: goal_persistence(reports),
      recovery: recovery(reports, cpl),
      constitutional_restraint: constitutional_restraint(lineage),
      learning: learning(reports),
      continuity: continuity(lineage)
    }

    meta = %{
      agency_yield: :not_measured,
      surprise_to_usefulness: :not_measured,
      failure_recurrence: failure_recurrence(reports)
    }

    %__MODULE__{
      capabilities: caps,
      meta_metrics: meta,
      synthesis: synthesize(caps),
      not_measured: not_measured(caps, meta)
    }
  end

  # --- capabilities ---------------------------------------------------------

  defp situational_awareness(reports, lineage) do
    health_reports = Enum.count(reports, &(Map.get(&1, "generated_at") != nil))

    if health_reports > 0 or lineage != [] do
      %{
        status: :observed,
        evidence: [operations_reports: health_reports, lineage_entries: length(lineage)],
        detail: "self-report artifacts present; state reconstructable from disk"
      }
    else
      %{status: :not_measured, evidence: [], detail: "no self-report artifacts found"}
    end
  end

  defp goal_persistence(reports) do
    cycles =
      reports
      |> Enum.map(&Map.get(&1, "discovery_cycles"))
      |> Enum.reject(&is_nil/1)

    cond do
      cycles == [] ->
        %{status: :not_measured, evidence: [], detail: "no discovery-cycle data in reports"}

      monotonic_non_decreasing?(cycles) ->
        %{status: :observed, evidence: [cycle_series: cycles],
          detail: "research work persisted and never regressed across reports"}

      true ->
        %{status: :concern, evidence: [cycle_series: cycles],
          detail: "discovery cycles regressed between reports"}
    end
  end

  defp recovery(reports, cpl) do
    failures = sum_key(reports, "total_failures")
    recoveries = sum_key(reports, "total_recoveries")

    cond do
      failures == 0 and cpl == 0 ->
        %{status: :not_measured, evidence: [], detail: "no failures or checkpoints observed"}

      failures > 0 and recoveries >= failures ->
        %{status: :observed, evidence: [failures: failures, recoveries: recoveries],
          detail: "every observed failure has a matching recovery"}

      cpl > 0 and failures == 0 ->
        %{status: :observed, evidence: [cpl_checkpoints: cpl],
          detail: "checkpoints cycling; no failures observed"}

      true ->
        %{status: :concern, evidence: [failures: failures, recoveries: recoveries],
          detail: "failures without matching recoveries"}
    end
  end

  defp constitutional_restraint(lineage) do
    rejections =
      Enum.count(lineage, fn e ->
        e.lineage_type == :verification_evidence and get_in(e.payload, [:outcome]) == :rejected
      end)

    accepted_attacks =
      Enum.count(lineage, fn e ->
        e.lineage_type == :verification_evidence and
          get_in(e.payload, [:outcome]) == :accepted and get_in(e.payload, [:attack]) != nil
      end)

    cond do
      accepted_attacks > 0 ->
        %{status: :concern, evidence: [accepted_attacks: accepted_attacks],
          detail: "an adversarial outcome was accepted - investigate"}

      rejections > 0 ->
        %{status: :observed, evidence: [rejected_attacks: rejections],
          detail: "adversarial attempts rejected; restraint demonstrated"}

      true ->
        %{status: :not_measured, evidence: [],
          detail: "no verification-evidence entries in lineage"}
    end
  end

  defp learning(reports) do
    sigs = reports |> Enum.flat_map(&List.wrap(Map.get(&1, "failure_signatures")))

    cond do
      sigs == [] ->
        %{status: :not_measured, evidence: [], detail: "reports carry no failure signatures"}

      recurring(reports) == [] ->
        %{status: :observed, evidence: [signatures: Enum.frequencies(sigs)],
          detail: "failures observed without recurrence"}

      true ->
        %{status: :concern, evidence: [recurring: recurring(reports)],
          detail: "recurring failure signatures; learning not yet demonstrated"}
    end
  end

  defp continuity([]),
    do: %{status: :not_measured, evidence: [], detail: "no lineage entries on disk"}

  defp continuity(lineage) do
    case Store.verify_chain(lineage) do
      :ok ->
        %{status: :observed, evidence: [entries: length(lineage)],
          detail: "lineage chain intact; state reconstructable after restart"}

      {:error, reason} ->
        %{status: :concern, evidence: [reason: reason], detail: "lineage chain broken"}
    end
  end

  # --- meta-metrics ---------------------------------------------------------

  defp failure_recurrence(reports) do
    case recurring(reports) do
      [] -> :none
      rec -> rec
    end
  end

  defp recurring(reports) do
    reports
    |> Enum.flat_map(&List.wrap(Map.get(&1, "failure_signatures")))
    |> Enum.frequencies()
    |> Enum.filter(fn {_sig, n} -> n > 1 end)
  end

  # --- synthesis ("is there anything I should know?") -----------------------

  defp synthesize(caps) do
    concerns = for {name, %{status: :concern} = c} <- caps, do: "!" <> "#{name}: #{c.detail}"
    observed = for {name, %{status: :observed} = c} <- caps, do: "OK #{name}: #{c.detail}"
    concerns ++ observed
  end

  defp not_measured(caps, meta) do
    cap_names = for {name, %{status: :not_measured}} <- caps, do: name
    meta_names = for {name, :not_measured} <- meta, do: name
    cap_names ++ meta_names
  end

  # --- render ---------------------------------------------------------------

  def render(%__MODULE__{} = audit) do
    cap_lines =
      audit.capabilities
      |> Enum.sort_by(fn {name, _} -> to_string(name) end)
      |> Enum.map(fn {name, cap} ->
        "  [#{String.upcase(to_string(cap.status))}] #{name}: #{cap.detail}"
      end)

    not_measured =
      if audit.not_measured == [],
        do: "  (none)",
        else: Enum.map_join(audit.not_measured, "\n", &("  * " <> to_string(&1)))

    synthesis =
      if audit.synthesis == [],
        do: "  Nothing actionable - see not-measured capabilities below.",
        else: Enum.map_join(audit.synthesis, "\n", &("  " <> &1))

    """
    ==== JARVIS CAPABILITY AUDIT (read-only) ====
    Capabilities:
    #{Enum.join(cap_lines, "\n")}

    Is there anything I should know?
    #{synthesis}

    Not measured (uncertainty, not failure):
    #{not_measured}
    ============================================
    """
  end

  # --- helpers ---------------------------------------------------------------

  defp sum_key(reports, key) do
    reports |> Enum.map(&Map.get(&1, key)) |> Enum.reject(&is_nil/1) |> Enum.sum()
  end

  defp monotonic_non_decreasing?(list) do
    list
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.all?(fn [a, b] -> b >= a end)
  end
end