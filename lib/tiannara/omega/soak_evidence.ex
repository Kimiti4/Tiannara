defmodule Tiannara.Omega.SoakEvidence do
  @moduledoc """
  Pure extractor turning the soak's LOG-ONLY trail into structured, auditable
  evidence: totals, hourly TRAJECTORIES (rates, not just totals), mint
  diversity (monoculture tracking), and a differential cross-check against an
  independent reference audit.

  Constitutional basis: "Maintain audit trails", "Support reproducibility",
  "Evidence Before Confidence", "Uncertainty should never be hidden"
  (unmatched lines are counted; proxies are labeled as proxies).
  """

  defstruct agency_loops: 0,
            loop_series: [],
            loop_monotonic: true,
            recoveries: 0,
            restraints: 0,
            improvement_cycles: 0,
            self_diagnoses: 0,
            workflow_crashes: 0,
            workflow_crash_signatures: %{},
            mints: 0,
            mint_signatures: %{},
            duplicate_mint_groups: [],
            pipeline_bypasses: 0,
            rejects: 0,
            first_mint_at: nil,
            hourly: %{},
            unmatched_lines: 0,
            total_lines: 0

  # Patterns mirror the reference audit (scripts/audit_soak_signals.exs) token
  # for token, so cross_check compares the same definitions. The agency_loop
  # pattern is anchored to the completion line: "[AgencyLoop] call failed"
  # warning dumps embed arbitrary digits that would otherwise poison both the
  # loop count and monotonicity.
  @doc "Patterns as a fresh map (kept as a function: Regex structs cannot be escaped from a module attribute)."
  def patterns do
    %{
      agency_loop: ~r/\[AgencyLoop\] Loop (\d+) completed/,
      recovery: ~r/recovering|Recovered|recovered|resume|Resumed/,
      restraint: ~r/REJECTED BY FALSIFICATION|not authorized|unauthorized|illegal_transition|BLOCKED|:gate_closed|GATE CLOSED/,
      improvement: ~r/improvement cycle|Proposing|proposal approved|suggested/,
      self_diagnosis: ~r/systemic bottleneck|monoculture|stall|bottleneck detected/,
      workflow_crash: ~r/^(?:\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\|)?\*\* \(ArgumentError\) (could not put\/update.*)/,
      mint: ~r/MINTED:\s*(.+)/,
      bypass: ~r/bypass|direct[-_ ]mint|upsert_law/i,
      reject: ~r/REJECTED BY FALSIFICATION CHECK/
    }
  end

  @cross_check_fields [:agency_loops, :recoveries, :restraints, :improvement_cycles,
                       :self_diagnoses, :workflow_crashes, :mints]

  def extract(lines) when is_list(lines) do
    p = patterns()
    lines |> Enum.reduce(%__MODULE__{}, &reduce_line(&1, &2, p)) |> finalize()
  end

  def monotonic?(series) do
    series |> Enum.chunk_every(2, 1, :discard) |> Enum.all?(fn [a, b] -> b >= a end)
  end

  # --- trajectory (rates over time) ---------------------------------------

  @doc "Per-hour rates so we measure trajectory, not merely totals."
  def trajectory(%__MODULE__{hourly: hourly}) do
    hourly
    |> Enum.sort_by(fn {h, _} -> to_string(h) end)
    |> Enum.map(fn {h, b} ->
      %{hour: h,
        loops_per_hour: Map.get(b, :loop, 0),
        recoveries_per_hour: Map.get(b, :recovery, 0),
        crashes_per_hour: Map.get(b, :crash, 0),
        mints_per_hour: Map.get(b, :mint, 0),
        diagnoses_per_hour: Map.get(b, :diagnosis, 0),
        improvements_per_hour: Map.get(b, :improvement, 0),
        restraints_per_hour: Map.get(b, :restraint, 0)}
    end)
  end

  @doc "Monoculture tracking: unique vs total mints."
  def mint_diversity(%__MODULE__{} = e) do
    unique = map_size(e.mint_signatures)

    %{total_mints: e.mints, unique_mints: unique,
      unique_ratio: ratio(unique, e.mints),
      duplicate_mint_rate: ratio(e.mints - unique, e.mints)}
  end

  # --- differential audit (extractor validation) --------------------------

  @doc """
  Differential audit against an INDEPENDENT reference audit (e.g. the output of
  audit_soak_signals.exs). No hard-coded ground truth: expected values come
  from the reference at the same timestamp.
  """
  def cross_check(%__MODULE__{} = extracted, reference, tolerance \\ 0) do
    checks =
      for field <- @cross_check_fields, into: %{} do
        ex = Map.get(extracted, field)
        ref = Map.get(reference, field) || Map.get(reference, to_string(field))
        delta = if is_number(ex) and is_number(ref), do: ex - ref, else: nil
        ok = is_number(delta) and abs(delta) <= tolerance
        {field, %{extracted: ex, reference: ref, delta: delta, match: ok}}
      end

    status = if Enum.all?(checks, fn {_k, c} -> c.match end), do: :match, else: :mismatch
    %{status: status, checks: checks}
  end

  def render(%__MODULE__{} = e) do
    div = mint_diversity(e)

    dup =
      e.duplicate_mint_groups
      |> Enum.take(5)
      |> Enum.map_join("\n", fn {sig, n} -> "  #{n}x #{sig}" end)

    """
    ============ SOAK EVIDENCE EXTRACTION ============
    total_lines:            #{e.total_lines}
    unmatched_lines:        #{e.unmatched_lines}

    AgencyLoop loops:       #{e.agency_loops} (monotonic: #{e.loop_monotonic})
    recoveries:             #{e.recoveries}
    restraint events:       #{e.restraints}
    improvement cycles:     #{e.improvement_cycles}
    self-diagnoses:         #{e.self_diagnoses}
    WorkflowEngine crashes: #{e.workflow_crashes}
    MINTED:                 #{e.mints} (unique: #{div.unique_mints}, dup_rate: #{Float.round(div.duplicate_mint_rate, 3)})
    first mint at:          #{e.first_mint_at || "n/a"}
    pipeline bypasses:      #{e.pipeline_bypasses}
    rejects:                #{e.rejects}

    Top duplicate-mint groups:
    #{dup}
    ==================================================
    """
  end

  # --- internals -----------------------------------------------------------

  defp reduce_line(line, acc, p) do
    hour = hour_of(line)

    acc
    |> Map.update!(:total_lines, &(&1 + 1))
    |> bump_signal(p.recovery, :recoveries, :recovery, line, hour)
    |> bump_signal(p.restraint, :restraints, :restraint, line, hour)
    |> bump_signal(p.improvement, :improvement_cycles, :improvement, line, hour)
    |> bump_signal(p.self_diagnosis, :self_diagnoses, :diagnosis, line, hour)
    |> bump_signal(p.bypass, :pipeline_bypasses, :bypass, line, hour)
    |> bump_signal(p.reject, :rejects, :reject, line, hour)
    |> capture(line, p, hour)
  end

  # Independent counters, mirroring audit_soak_signals.exs: a line may
  # contribute to several signals (e.g. "REJECTED BY FALSIFICATION CHECK"
  # counts in BOTH restraint and rejects), so these are NOT exclusive.
  defp bump_signal(acc, pattern, total_field, bucket_key, line, hour) do
    if Regex.match?(pattern, line) do
      acc
      |> Map.update!(total_field, &(&1 + 1))
      |> Map.update!(:hourly, &bump(&1, hour, bucket_key))
    else
      acc
    end
  end

  # Signature-capturing primary classification (mint/crash/loop) plus the
  # unmatched tally for the remainder. Signals already counted above are not
  # re-classified here.
  defp capture(acc, line, p, hour) do
    cond do
      sig = match_sig(p.mint, line) ->
        %{acc | mints: acc.mints + 1,
                mint_signatures: Map.update(acc.mint_signatures, sig, 1, &(&1 + 1)),
                first_mint_at: acc.first_mint_at || extract_ts(line),
                hourly: bump(acc.hourly, hour, :mint)}

      sig = match_sig(p.workflow_crash, line) ->
        %{acc | workflow_crashes: acc.workflow_crashes + 1,
                workflow_crash_signatures: Map.update(acc.workflow_crash_signatures, sig, 1, &(&1 + 1)),
                hourly: bump(acc.hourly, hour, :crash)}

      n = loop_number(line, p) ->
        %{acc | agency_loops: max(acc.agency_loops, n),
                loop_series: [n | acc.loop_series],
                loop_monotonic: acc.loop_monotonic and n >= acc.agency_loops,
                hourly: bump(acc.hourly, hour, :loop)}

      already_signaled?(line, p) ->
        acc

      true ->
        %{acc | unmatched_lines: acc.unmatched_lines + 1}
    end
  end

  defp already_signaled?(line, p) do
    Enum.any?([p.recovery, p.restraint, p.improvement, p.self_diagnosis, p.bypass, p.reject],
              &Regex.match?(&1, line))
  end

  defp finalize(acc) do
    dup =
      acc.mint_signatures
      |> Enum.filter(fn {_s, n} -> n > 1 end)
      |> Enum.sort_by(fn {_s, n} -> -n end)

    %{acc | loop_series: Enum.reverse(acc.loop_series), duplicate_mint_groups: dup}
  end

  defp match_sig(pattern, line) do
    case Regex.run(pattern, line) do
      [_, sig] -> String.trim(sig)
      [_] -> String.trim(line)
      nil -> nil
    end
  end

  defp loop_number(line, p) do
    case Regex.run(p.agency_loop, line) do
      [_, n] -> String.to_integer(n)
      _ -> nil
    end
  end

  defp extract_ts(line) do
    case Regex.run(~r/(\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2})/, line) do
      [_, ts] -> ts
      _ -> nil
    end
  end

  defp hour_of(line) do
    case extract_ts(line) do
      nil -> :unknown
      ts -> String.slice(ts, 0, 13)
    end
  end

  defp bump(hourly, hour, key) do
    bucket = Map.get(hourly, hour, %{})
    Map.put(hourly, hour, Map.update(bucket, key, 1, &(&1 + 1)))
  end

  defp ratio(_num, 0), do: 0.0
  defp ratio(num, den), do: num / den
end