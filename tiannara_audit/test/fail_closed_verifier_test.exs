defmodule TiannaraAudit.FailClosedVerifierTest do
  @moduledoc """
  R1/Batch 1 step 5 (F-ARC-007, F-GOV-011): the independent verifiers must be
  able to fail.

  Two of the four verifiers could not fail:

  - `GraphVerifier` reported `match: true` and `failures: 0` for every sample,
    whatever it computed;
  - `ProofVerifier` treated a **missing** expected fingerprint as a pass
    ("independent fingerprint: ...").

  The report they produced - the tracked `INDEPENDENT_AUDIT_REPORT.md` with
  "220 / 220 PASS" - is therefore **not evidence** and is retired as such.

  This suite pins the fail-closed contract for every verifier: a true claim
  passes, a false claim fails, and a missing expectation fails.
  """

  use ExUnit.Case, async: true

  alias TiannaraAudit.{GraphVerifier, HashVerifier, ProofVerifier, RuntimeVerifier}

  defp true_hash_sample do
    input = %{"a" => 1, "b" => [1, 2, 3]}

    %{
      sample_id: 1,
      input: input,
      expected_hash: HashVerifier.from_canonical_map(input)
    }
  end

  defp false_hash_sample do
    %{sample_id: 2, input: %{"a" => 1}, expected_hash: String.duplicate("0", 64)}
  end

  defp proof_sample do
    %{
      proof_id: "p1",
      assertion_id: "a1",
      strategy: :direct,
      assumptions: [],
      steps: [],
      dependencies: [],
      verification_status: :verified
    }
  end

  describe "HashVerifier" do
    test "a true claim passes" do
      result = HashVerifier.verify([true_hash_sample()])

      assert result.total == 1
      assert result.failures == 0
    end

    test "a false claim fails" do
      result = HashVerifier.verify([false_hash_sample()])

      assert result.total == 1
      assert result.failures == 1
      assert [detail] = result.details
      assert detail =~ "expected"
    end

    test "a missing expectation fails" do
      result = HashVerifier.verify([%{sample_id: 3, input: %{"a" => 1}}])

      assert result.failures == 1
    end
  end

  describe "GraphVerifier" do
    defp graph_sample(extra) do
      Map.merge(
        %{
          node_id: "n1",
          node_type: :entity,
          metadata: %{"k" => "v"}
        },
        extra
      )
    end

    test "a false claim fails" do
      result = GraphVerifier.verify([graph_sample(%{expected_hash: String.duplicate("f", 64)})])

      assert result.total == 1
      assert result.failures == 1
      assert [detail] = result.details
      assert detail =~ "expected"
    end

    test "a missing expectation fails" do
      result = GraphVerifier.verify([graph_sample(%{})])

      assert result.total == 1
      assert result.failures == 1
      assert [detail] = result.details
      assert detail =~ "no expected hash"
    end

    test "a true claim passes and the expectation is not part of the hashed content" do
      base = graph_sample(%{})

      # Without an expectation the claim cannot be verified.
      without = GraphVerifier.verify([base])
      assert without.failures == 1

      # The expectation key is metadata about the claim, not part of it: the
      # same content with the expectation added still verifies.
      hash = result_sample_hash(base)

      passing = GraphVerifier.verify([Map.put(base, :expected_hash, hash)])

      assert passing.total == 1
      assert passing.failures == 0
    end
  end

  describe "ProofVerifier" do
    test "a false claim fails" do
      sample = %{sample_id: 1, proof_summary: proof_sample(), expected_fingerprint: String.duplicate("0", 64)}

      result = ProofVerifier.verify([sample])

      assert result.failures == 1
    end

    test "a missing expectation fails" do
      sample = %{sample_id: 2, proof_summary: proof_sample()}

      result = ProofVerifier.verify([sample])

      assert result.total == 1
      assert result.failures == 1
      assert [detail] = result.details
      assert detail =~ "no expected fingerprint"
    end

    test "a missing proof summary fails" do
      result = ProofVerifier.verify([%{sample_id: 3, expected_fingerprint: String.duplicate("0", 64)}])

      assert result.failures == 1
    end

    test "a true claim passes" do
      summary = proof_sample()
      expected = ProofVerifier.compute_fingerprint(summary)

      result = ProofVerifier.verify([%{sample_id: 4, proof_summary: summary, expected_fingerprint: expected}])

      assert result.total == 1
      assert result.failures == 0
    end
  end

  describe "RuntimeVerifier" do
    test "a false claim fails" do
      expr = %{type: :op, value: 1, children: []}

      result = RuntimeVerifier.verify([%{sample_id: 1, expression: expr, expected_hash: String.duplicate("0", 64)}])

      assert result.failures == 1
    end

    test "a missing expectation fails" do
      expr = %{type: :op, value: 1, children: []}

      result = RuntimeVerifier.verify([%{sample_id: 2, expression: expr}])

      assert result.failures == 1
    end

    test "a missing expression fails" do
      result = RuntimeVerifier.verify([%{sample_id: 3, expected_hash: String.duplicate("0", 64)}])

      assert result.failures == 1
    end
  end

  # The graph verifier does not expose the computed hash, so the expectation
  # for a graph sample is derived with the same algorithm the verifier uses.
  defp result_sample_hash(sample) do
    metadata =
      sample
      |> Map.drop([:node_id, :node_type, :expected_hash, :sample_id, :seq])
      |> Enum.map(fn {k, v} -> {to_string(k), v} end)
      |> Enum.sort_by(fn {k, _v} -> k end)
      |> Enum.into(%{})

    canonical = %{
      "node_id" => sample[:node_id],
      "node_type" => sample[:node_type],
      "metadata" => metadata
    }

    HashVerifier.from_canonical_map(canonical)
  end
end
