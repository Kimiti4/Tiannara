defmodule Tiannara.Operations.ChallengeDiagnostics do
  @moduledoc """
  Classifies soak/challenge results into honest diagnostic buckets so the
  CRAV report distinguishes engine failures from test-environment artifacts.

  Input contract: a list of challenge records with `:challenge` (atom or the
  engine's string id), `:passed`/`:pass`, and an optional `:at`/`:timestamp`.

  Classifications:
    * `:healthy`     — every attempt passed
    * `:timing`      — failed on the first run, recovered afterwards
    * `:transient`   — single isolated failure mid-run that recovered
    * `:repeatable`  — 2+ consecutive failures (a real defect signal)
    * `:environmental` — failure in a liveness check (external inputs, not
      the engine): `:causal_lineage_integrity`, `:cross_domain_synthesis`
    * `:unknown`     — isolated failure with no recovery evidence

  `:repeatable`/`:unknown` downgrade the scientific confidence note of the
  report.
  """

  @liveness_challenges [:causal_lineage_integrity, :cross_domain_synthesis]

  @challenge_atoms %{
    "causal_lineage" => :causal_lineage_integrity,
    "cross_domain_synthesis" => :cross_domain_synthesis,
    "autonomous_experiment" => :autonomous_experiment,
    "self_improvement" => :self_improvement,
    "civilization_coordination" => :civilization_coordination,
    "anomaly_detection" => :anomaly_detection,
    "paradoxical_policy" => :paradoxical_policy,
    "impossible_ui" => :impossible_ui,
    "nested_negation" => :nested_negation,
    "tool_use" => :tool_use
  }

  @doc "Diagnoses challenge records, grouped per challenge."
  def diagnose(records) when is_list(records) do
    records
    |> Enum.map(&normalize/1)
    |> Enum.group_by(& &1.challenge)
    |> Map.new(fn {challenge, entries} ->
      {challenge, classify(entries, challenge)}
    end)
  end

  def diagnose(_), do: %{}

  @doc "Challenge names considered liveness checks (external-facing)."
  def liveness_challenges, do: @liveness_challenges

  defp normalize(%{name: name} = record) do
    %{
      challenge: challenge_atom(name),
      passed: bool(Map.get(record, :pass, Map.get(record, :passed, false))),
      at: Map.get(record, :timestamp) || Map.get(record, :at)
    }
  end

  defp normalize(%{challenge: challenge} = record) do
    %{
      challenge: challenge_atom(challenge),
      passed: bool(Map.get(record, :passed, Map.get(record, :pass, false))),
      at: Map.get(record, :at) || Map.get(record, :timestamp)
    }
  end

  defp challenge_atom(name) when is_binary(name),
    do: Map.get(@challenge_atoms, name, :unknown_challenge)

  defp challenge_atom(atom) when is_atom(atom), do: atom

  defp bool(true), do: true
  defp bool(false), do: false
  defp bool(_), do: false

  defp classify(entries, challenge) do
    sorted = Enum.sort_by(entries, fn e -> entry_time(e) end)
    attempts = length(sorted)
    failures = Enum.count(sorted, &(not &1.passed))
    passes = attempts - failures
    first = List.first(sorted)
    consecutive_failures = sorted |> Enum.take_while(&(not &1.passed)) |> length()
    liveness = challenge in @liveness_challenges

    classification =
      cond do
        failures == 0 -> :healthy
        consecutive_failures >= 2 -> :repeatable
        liveness -> :environmental
        first != nil and not first.passed and passes > 0 -> :timing
        failures == 1 and passes > 0 -> :transient
        true -> :unknown
      end

    %{
      challenge: challenge,
      classification: classification,
      liveness_check: liveness,
      attempts: attempts,
      passes: passes,
      failures: failures,
      recommendation: recommendation(classification, liveness),
      confidence_note: confidence_note(classification)
    }
  end

  defp entry_time(%{at: %DateTime{}} = e), do: e.at
  defp entry_time(%{at: at}) when is_binary(at), do: at
  defp entry_time(%{at: at}) when is_atom(at), do: at
  defp entry_time(_), do: :unknown

  defp recommendation(:healthy, _), do: "No action."

  defp recommendation(:timing, _),
    do: "Failure occurred at startup; ensure warm-up before verdict and retry."

  defp recommendation(:transient, _),
    do: "Isolated failure; log for observation, no action required."

  defp recommendation(:repeatable, _),
    do:
      "Repeatable failure indicates a real defect in this challenge path — investigate before relying on results."

  defp recommendation(:environmental, _),
    do:
      "Liveness check failed — inspect external inputs (world model, domain data) rather than the engine."

  defp recommendation(:unknown, _),
    do:
      "Unexplained failure — add counters/instrumentation to diagnose before relying on results."

  defp confidence_note(:repeatable), do: "Scientific confidence downgraded: repeatable failure."
  defp confidence_note(:unknown), do: "Scientific confidence downgraded: unexplained failure."
  defp confidence_note(_), do: "Pass/fail signal reliable."
end
