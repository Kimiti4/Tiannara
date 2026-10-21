defmodule TiannaraAudit.ProofVerifier do
  @moduledoc """
  Independently verifies proof fingerprints.

  Replicates `ProofEngine.fingerprint/1` algorithm by extracting
  the canonical proof fields and computing the content-addressed
  fingerprint, without importing TiannaraRuntime modules.
  """

  alias TiannaraAudit.HashVerifier

  # The verifier is fail-closed: a proof is verified only when the sample
  # carries the fingerprint it is compared against. A missing expectation is a
  # failure, not a pass (F-ARC-007).
  def verify(samples) when is_list(samples) do
    results = Enum.map(samples, fn sample ->
      ps = sample[:proof_summary]
      expected = sample[:expected_fingerprint]

      cond do
        ps == nil ->
          %{sample_id: sample[:sample_id], match: false, detail: "no proof summary"}

        is_nil(expected) ->
          %{
            sample_id: sample[:sample_id],
            match: false,
            detail: "no expected fingerprint to verify against"
          }

        true ->
          computed = compute_fingerprint(ps)
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
        "Proof ##{f.sample_id}: #{Map.get(f, :detail, "mismatch")}"
      end)
    }
  end

  def compute_fingerprint(proof_summary) do
    step_fingerprints = Enum.map(proof_summary[:steps] || [], fn s ->
      HashVerifier.from_canonical_map(%{
        "step_number" => s[:step_number],
        "rule_applied" => s[:rule_applied],
        "input_objects" => s[:input_objects] || [],
        "output_object" => s[:output_object] || "",
        "dependency_hashes" => s[:dependency_hashes] || []
      })
    end)

    canonical = %{
      "proof_id" => proof_summary[:proof_id],
      "assertion_id" => proof_summary[:assertion_id],
      "strategy" => proof_summary[:strategy],
      "assumptions" => proof_summary[:assumptions] || [],
      "steps" => step_fingerprints,
      "dependencies" => proof_summary[:dependencies] || [],
      "verification_status" => proof_summary[:verification_status]
    }

    HashVerifier.from_canonical_map(canonical)
  end
end
