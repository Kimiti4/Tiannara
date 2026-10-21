defmodule TiannaraAudit.RuntimeVerifier do
  @moduledoc """
  Independently verifies runtime expression fingerprints.

  Replicates `SymbolicExpression.id/1` algorithm:
  1. Build map with "type", "value", and "children" (children hashed first)
  2. Call `from_canonical_map` on the result
  """

  alias TiannaraAudit.HashVerifier

  # Fail-closed: an absent expression or an absent expectation is a failure,
  # not a pass, and it must be reported rather than raise (F-ARC-007).
  def verify(samples) when is_list(samples) do
    results = Enum.map(samples, fn sample ->
      expr = sample[:expression]
      expected = sample[:expected_hash]

      cond do
        expr == nil ->
          %{sample_id: sample[:sample_id], match: false, detail: "no expression"}

        is_nil(expected) ->
          %{
            sample_id: sample[:sample_id],
            match: false,
            detail: "no expected hash to verify against"
          }

        true ->
          computed = compute_expression_hash(expr)
          match = computed == expected

          %{
            sample_id: sample[:sample_id],
            match: match,
            expected: expected,
            computed: computed,
            detail: if(match, do: "fingerprint verified", else: "expected #{expected}, computed #{computed}")
          }
      end
    end)

    failures = Enum.filter(results, fn r -> not r.match end)

    %{
      total: length(results),
      failures: length(failures),
      details: Enum.map(failures, fn f ->
        "Runtime sample ##{f.sample_id}: #{Map.get(f, :detail, "mismatch")}"
      end)
    }
  end

  def compute_expression_hash(expr) when is_map(expr) do
    children_hashes = Enum.map(expr[:children] || [], fn child ->
      compute_expression_hash(child)
    end)

    canonical = %{
      "type" => expr[:type],
      "value" => expr[:value],
      "children" => children_hashes
    }

    HashVerifier.from_canonical_map(canonical)
  end
end
