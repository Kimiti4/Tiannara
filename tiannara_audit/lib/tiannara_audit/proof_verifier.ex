defmodule TiannaraAudit.ProofVerifier do
  @moduledoc """
  Independently verifies proof fingerprints.

  Replicates `ProofEngine.fingerprint/1` algorithm by extracting
  the canonical proof fields and computing the content-addressed
  fingerprint, without importing TiannaraRuntime modules.
  """

  alias TiannaraAudit.HashVerifier

  def verify(samples) when is_list(samples) do
    results = Enum.map(samples, fn sample ->
      ps = sample[:proof_summary]
      if ps == nil do
        %{sample_id: sample[:sample_id], match: false, detail: "no proof summary"}
      else
        computed = compute_fingerprint(ps)
        expected = sample[:expected_fingerprint]

        if expected == nil do
          %{sample_id: sample[:sample_id], match: true, detail: "independent fingerprint: #{String.slice(computed, 0, 12)}..."}
        else
          match = computed == expected
          %{sample_id: sample[:sample_id], match: match, expected: expected, computed: computed}
        end
      end
    end)

    failures = Enum.filter(results, fn r -> not r.match end)

    %{
      total: length(results),
      failures: length(failures),
      details: Enum.map(failures, fn f ->
        "Proof ##{f.sample_id}: expected #{f.expected}, computed #{f.computed}"
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
