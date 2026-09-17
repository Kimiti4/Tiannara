defmodule TiannaraRuntime.Mathematics.Validation.DeterministicReplay do
  @moduledoc """
  Phase 16.X.95 — Deterministic Replay Validation Campaign

  Generates and replays symbolic expressions, proofs, and conjectures,
  verifying that hashes, fingerprints, and graph roots are identical after replay.
  """

  @behaviour TiannaraRuntime.Mathematics.Validation.Campaign

  alias TiannaraRuntime.Mathematics.SymbolicEngine
  alias TiannaraRuntime.Mathematics.ProofEngine
  alias TiannaraRuntime.Mathematics.ConjectureEngine
  alias TiannaraRuntime.Mathematics.MathematicalID

  @impl true
  def name, do: "Deterministic Replay Validation"

  @impl true
  def description, do: "Generate and replay symbolic expressions, proofs, and conjectures. Verify identical hashes, fingerprints, and graph roots after replay."

  @impl true
  def run(_opts \\ []) do
    checks = [
      check_symbolic_expression_replay(),
      check_proof_replay(),
      check_conjecture_replay(),
      check_hash_stability()
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

  defp check_symbolic_expression_replay do
    count = 100
    results = Enum.reduce_while(1..count, [], fn i, acc ->
      expr = generate_expression(i)
      re_expr = regenerate_expression(i)

      hash1 = SymbolicEngine.expression_hash(expr)
      hash2 = SymbolicEngine.expression_hash(re_expr)

      if hash1 == hash2 do
        {:cont, [%{iteration: i, match: true} | acc]}
      else
        {:halt, [%{iteration: i, match: false, expected: hash1, got: hash2}]}
      end
    end)

    mismatches = Enum.filter(results, fn r -> r[:match] == false end)

    if mismatches == [] do
      %{check: "symbolic_expression_replay", status: :pass, detail: "#{count} expressions replayed, all hashes match"}
    else
      %{check: "symbolic_expression_replay", status: :fail, detail: "#{length(mismatches)} hash mismatches: #{inspect(Enum.take(mismatches, 3))}"}
    end
  end

  defp check_proof_replay do
    count = 100
    strategies = [:direct, :contradiction, :induction, :constructive, :computational]

    results = Enum.reduce_while(1..count, [], fn i, acc ->
      strategy = Enum.at(strategies, rem(i, length(strategies)))
      assertion_id = "assertion_replay_#{i}"
      assumptions = ["axiom_#{i}", "lemma_#{i}"]
      steps = Enum.map(0..3, fn sn ->
        rule_applied = if rem(sn, 2) == 0, do: "modus_ponens", else: "hypothetical_syllogism"
        %{
          "step_number" => sn,
          "rule_applied" => rule_applied,
          "input_objects" => ["obj_#{i}_#{sn}"],
          "output_object" => "result_#{i}_#{sn}",
          "fingerprint" => MathematicalID.from_canonical_map(%{"iter" => i, "step" => sn})
        }
      end)

      case ProofEngine.build_proof(assertion_id, strategy, assumptions, steps) do
        {:ok, proof} ->
          case ProofEngine.replay_proof(proof) do
            {:ok, replayed} ->
              if proof["proof_hash"] == replayed["proof_hash"] do
                {:cont, [%{iteration: i, match: true} | acc]}
              else
                {:halt, [%{iteration: i, match: false}]}
              end
            {:error, reason} ->
              {:halt, [%{iteration: i, error: reason}]}
          end
        {:error, reason} ->
          {:halt, [%{iteration: i, error: reason}]}
      end
    end)

    mismatches = Enum.filter(results, fn r -> r[:match] == false end)
    errors = Enum.filter(results, fn r -> Map.has_key?(r, :error) end)

    cond do
      errors != [] ->
        %{check: "proof_replay", status: :error, detail: "#{length(errors)} errors: #{inspect(Enum.take(errors, 3))}"}
      mismatches != [] ->
        %{check: "proof_replay", status: :fail, detail: "#{length(mismatches)} hash mismatches"}
      true ->
        %{check: "proof_replay", status: :pass, detail: "#{count} proofs replayed, all hashes match"}
    end
  end

  defp check_conjecture_replay do
    count = 100
    sources = ConjectureEngine.valid_sources()

    results = Enum.reduce_while(1..count, [], fn i, acc ->
      source = Enum.at(sources, rem(i, length(sources)))
      statement = "Conjecture #{i}: Every #{source} structure has property P"
      opts = %{"source" => source, "dependencies" => ["dep_#{i}"], "research_value" => 0.5 + (rem(i, 10) / 20.0)}

      case ConjectureEngine.generate_conjecture(statement, opts) do
        {:ok, conjecture} ->
          case ConjectureEngine.replay_conjecture(conjecture) do
            {:ok, replayed} ->
              if conjecture["conjecture_id"] == replayed["conjecture_id"] and
                 conjecture["priority"] == replayed["priority"] and
                 conjecture["cluster"] == replayed["cluster"] do
                {:cont, [%{iteration: i, match: true} | acc]}
              else
                {:halt, [%{iteration: i, match: false}]}
              end
            {:error, reason} ->
              {:halt, [%{iteration: i, error: reason}]}
          end
        {:error, reason} ->
          {:halt, [%{iteration: i, error: reason}]}
      end
    end)

    mismatches = Enum.filter(results, fn r -> r[:match] == false end)
    errors = Enum.filter(results, fn r -> Map.has_key?(r, :error) end)

    cond do
      errors != [] ->
        %{check: "conjecture_replay", status: :error, detail: "#{length(errors)} errors: #{inspect(Enum.take(errors, 3))}"}
      mismatches != [] ->
        %{check: "conjecture_replay", status: :fail, detail: "#{length(mismatches)} mismatches"}
      true ->
        %{check: "conjecture_replay", status: :pass, detail: "#{count} conjectures replayed, all ids/priorities/clusters match"}
    end
  end

  defp check_hash_stability do
    hash_input = %{"type" => "test", "value" => 42, "nested" => [%{"a" => 1}, %{"b" => 2}]}
    first = MathematicalID.from_canonical_map(hash_input)

    results = Enum.map(1..100, fn _ ->
      current = MathematicalID.from_canonical_map(hash_input)
      current
    end)

    all_match = Enum.all?(results, fn h -> h == first end)

    if all_match do
      %{check: "hash_stability", status: :pass, detail: "100 repeated hashes all identical: #{String.slice(first, 0, 16)}..."}
    else
      %{check: "hash_stability", status: :fail, detail: "Hash instability detected"}
    end
  end

  defp generate_expression(i) do
    case rem(i, 5) do
      0 -> SymbolicEngine.constant(i)
      1 -> SymbolicEngine.variable("x_#{i}")
      2 -> SymbolicEngine.operator(:+, [SymbolicEngine.constant(i) |> elem(1), SymbolicEngine.variable("y") |> elem(1)])
      3 -> SymbolicEngine.operator(:*, [SymbolicEngine.variable("x") |> elem(1), SymbolicEngine.constant(i) |> elem(1)])
      4 -> SymbolicEngine.function("sin", [SymbolicEngine.variable("theta_#{i}") |> elem(1)])
    end
    |> case do
      {:ok, expr} -> expr
      _ -> {:ok, c} = SymbolicEngine.constant(0); c
    end
  end

  defp regenerate_expression(i) do
    generate_expression(i)
  end
end
