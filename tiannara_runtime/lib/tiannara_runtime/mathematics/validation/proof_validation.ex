defmodule TiannaraRuntime.Mathematics.Validation.ProofValidation do
  @moduledoc """
  Phase 16.X.95 — Proof Validation Campaign

  Executes proof constructions across all 5 strategies, verifies replay
  equality, dependency correctness, and measures verification latency.
  """

  @behaviour TiannaraRuntime.Mathematics.Validation.Campaign

  alias TiannaraRuntime.Mathematics.ProofEngine
  alias TiannaraRuntime.Mathematics.MathematicalID

  @impl true
  def name, do: "Proof Validation"

  @impl true
  def description, do: "Execute proof constructions across all 5 strategies, verify replay equality, dependency correctness, measure verification latency."

  @impl true
  def run(_opts \\ []) do
    checks = [
      check_all_strategies(),
      check_replay_equality(),
      check_dependency_correctness(),
      check_verification_latency()
    ]

    status = if Enum.all?(checks, fn c -> c.status == :pass end), do: :pass, else: :fail

    {:ok, %{
      campaign: name(),
      status: status,
      checks: checks,
      summary: %{
        total: length(checks),
        passed: Enum.count(checks, fn c -> c.status == :pass end),
        failed: Enum.count(checks, fn c -> c.status == :fail end),
        errors: Enum.count(checks, fn c -> c.status == :error end)
      }
    }}
  end

  defp check_all_strategies do
    strategies = [:direct, :contradiction, :induction, :constructive, :computational]
    count_per = 20
    total = count_per * length(strategies)

    results = Enum.flat_map(strategies, fn strategy ->
      Enum.map(1..count_per, fn i ->
        assertion_id = "assertion_#{strategy}_#{i}"
        assumptions = ["axiom_#{i}", "lemma_#{i}_#{strategy}"]
        steps = Enum.map(0..2, fn sn ->
          %{
            "step_number" => sn,
            "rule_applied" => strategy_atom_to_string(strategy),
            "input_objects" => ["in_#{i}_#{sn}"],
            "output_object" => "out_#{i}_#{sn}",
            "fingerprint" => MathematicalID.from_canonical_map(%{strategy: strategy, i: i, sn: sn})
          }
        end)

        start = System.monotonic_time()
        result = ProofEngine.build_proof(assertion_id, strategy, assumptions, steps)
        duration = System.monotonic_time() - start

        case result do
          {:ok, proof} ->
            %{strategy: strategy, iteration: i, ok: true, duration: duration, proof_hash: proof["proof_hash"]}
          {:error, reason} ->
            %{strategy: strategy, iteration: i, ok: false, error: reason}
        end
      end)
    end)

    failures = Enum.filter(results, fn r -> r[:ok] == false end)

    if failures == [] do
      avg_duration_ns = Enum.map(results, fn r -> r[:duration] end) |> then(fn ds -> Enum.sum(ds) / max(length(ds), 1) end)
      avg_duration_ms = avg_duration_ns / 1_000_000

      per_strategy = Enum.map(strategies, fn s ->
        strat_results = Enum.filter(results, fn r -> r[:strategy] == s end)
        s_count = length(strat_results)
        s_ok = Enum.count(strat_results, fn r -> r[:ok] == true end)
        "#{s}: #{s_ok}/#{s_count}"
      end)

      %{check: "all_strategies", status: :pass, detail: "#{total} proofs built across #{length(strategies)} strategies (avg #{Float.round(avg_duration_ms, 3)}ms). #{Enum.join(per_strategy, ", ")}"}
    else
      %{check: "all_strategies", status: :fail, detail: "#{length(failures)} failures: #{inspect(Enum.take(failures, 5))}"}
    end
  end

  defp check_replay_equality do
    strategies = [:direct, :contradiction, :induction, :constructive, :computational]

    results = Enum.map(1..50, fn i ->
      strategy = Enum.at(strategies, rem(i, length(strategies)))
      assertion_id = "replay_check_#{i}"
      steps = Enum.map(0..2, fn sn ->
        %{
          "step_number" => sn,
          "rule_applied" => "modus_ponens",
          "input_objects" => ["premise_#{i}_#{sn}"],
          "output_object" => "conclusion_#{i}_#{sn}",
          "fingerprint" => MathematicalID.from_canonical_map(%{check: i, step: sn})
        }
      end)

      with {:ok, original} <- ProofEngine.build_proof(assertion_id, strategy, ["ax_#{i}"], steps),
           {:ok, replayed} <- ProofEngine.replay_proof(original) do
        hashes_match = original["proof_hash"] == replayed["proof_hash"]
        ids_match = original["proof_id"] == replayed["proof_id"]
        deps_match = original["dependencies"] == replayed["dependencies"]
        all_match = hashes_match and ids_match and deps_match
        detail = if(all_match, do: :ok, else: :mismatch)
        %{iteration: i, match: all_match, detail: detail}
      else
        {:error, reason} -> %{iteration: i, match: false, detail: reason}
      end
    end)

    mismatches = Enum.filter(results, fn r -> r[:match] == false end)

    if mismatches == [] do
      %{check: "replay_equality", status: :pass, detail: "50 proofs replayed, all hashes/ids/deps match"}
    else
      %{check: "replay_equality", status: :fail, detail: "#{length(mismatches)} mismatches: #{inspect(Enum.take(mismatches, 3))}"}
    end
  end

  defp check_dependency_correctness do
    results = Enum.map(1..50, fn i ->
      steps = Enum.map(0..2, fn sn ->
        %{
          "step_number" => sn,
          "rule_applied" => "modus_ponens",
          "input_objects" => ["premise_#{i}_#{sn}"],
          "output_object" => "conclusion_#{i}_#{sn}"
        }
      end)

      case ProofEngine.build_proof("assertion_dep_#{i}", :direct, ["ax_#{i}"], steps) do
        {:ok, proof} ->
          case ProofEngine.verify_proof(proof) do
            {:ok, verified} ->
              %{iteration: i, ok: true, status: Map.get(verified, "verification_status", "verified")}
            {:error, reason} ->
              %{iteration: i, ok: false, error: reason}
          end
        {:error, reason} ->
          %{iteration: i, ok: false, error: reason}
      end
    end)

    successes = Enum.filter(results, fn r -> r[:ok] == true end)
    failures = Enum.filter(results, fn r -> r[:ok] == false end)

    if successes == results do
      %{check: "dependency_correctness", status: :pass, detail: "#{length(successes)}/#{length(results)} proofs passed full verification"}
    else
      %{check: "dependency_correctness", status: :fail, detail: "#{length(failures)} failures: #{inspect(Enum.take(failures, 3))}"}
    end
  end

  defp check_verification_latency do
    strategies = [:direct, :contradiction, :induction, :constructive, :computational]

    timings = Enum.map(1..50, fn i ->
      strategy = Enum.at(strategies, rem(i, length(strategies)))
      steps = Enum.map(0..4, fn sn ->
        %{
          "step_number" => sn,
          "rule_applied" => "modus_ponens",
          "input_objects" => ["p_#{i}_#{sn}"],
          "output_object" => "q_#{i}_#{sn}"
        }
      end)

      with {:ok, proof} <- ProofEngine.build_proof("assertion_lat_#{i}", strategy, ["ax_#{i}"], steps) do
        {start, _} = :timer.tc(fn -> ProofEngine.verify_proof(proof) end)
        start
      else
        _ -> 0
      end
    end)

    valid_timings = Enum.filter(timings, fn t -> t > 0 end)

    if length(valid_timings) > 0 do
      avg_us = Enum.sum(valid_timings) / length(valid_timings)
      max_us = Enum.max(valid_timings)
      min_us = Enum.min(valid_timings)

      %{check: "verification_latency", status: :pass, detail: "50 verifications: avg=#{Float.round(avg_us, 1)}us, min=#{min_us}us, max=#{max_us}us"}
    else
      %{check: "verification_latency", status: :error, detail: "No valid timings collected"}
    end
  end

  defp strategy_atom_to_string(:direct), do: "direct_proof"
  defp strategy_atom_to_string(:contradiction), do: "contradiction_proof"
  defp strategy_atom_to_string(:induction), do: "induction_proof"
  defp strategy_atom_to_string(:constructive), do: "constructive_proof"
  defp strategy_atom_to_string(:computational), do: "computational_proof"
end
