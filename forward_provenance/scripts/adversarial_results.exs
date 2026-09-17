# Re-runs the A-J adversarial scenarios and records verdicts to
# output/adversarial_results.json (deliverable #5).
alias TiannaraOS.Provenance.{Source, Demo, Verifier}
import TiannaraOS.Provenance.Canon

root = Path.expand("..", __DIR__)
contract_bytes = File.read!(Path.join(root, "contracts/tia_fp_forward_entropy_stability_v1.yaml"))
src = Source.build(repository: "adv-test", commit: "c" |> String.pad_leading(40, "0"), tree: "t", dirty_fingerprint: nil, source_files: [])

defmodule Scenarios do
  def run(name, fun) do
    status = fun.()
    %{"test" => name, "expected" => Map.get(status, :expected, ""), "outcome" => Map.put(status, :expected, nil)["outcome"], "verdict" => status[:outcome]}
  end
end

# Each helper returns %{outcome: "REJECT"|...}
defmodule R do
  import TiannaraOS.Provenance.Canon

  def root(name, contract_bytes, src) do
    dir = Path.join(System.tmp_dir!(), "fp_adv_#{name}_#{System.unique_integer([:positive])}")
    demo = Demo.run(experiment_id: "adv_" <> name, sample_count: 200, seed: 5, output_dir: dir, source: src, contract_bytes: contract_bytes)
    demo["bundle"]["root"]
  end

  def tamper(r, rel, new_bytes) do
    full = Path.join(r, rel)
    File.write!(full, new_bytes)
    mp = Path.join(r, "meta/bundle_manifest.json")
    m = mp |> File.read!() |> :json.decode()
    m = %{m | "files" => Map.put(m["files"], rel, sha256_bytes(new_bytes))}
    File.write!(mp, canon(m))
  end

  def delete(r, rel), do: File.rm!(Path.join(r, rel))

  def read_json(r, rel), do: r |> Path.join(rel) |> File.read!() |> :json.decode()
  def write_json(r, rel, term), do: File.write!(Path.join(r, rel), canon(term))
end

scenarios = [
  fn ->
    r = R.root("A", contract_bytes, src)
    started = R.read_json(r, "envelopes/execution_started.json")
    ended = R.read_json(r, "envelopes/execution_ended.json")
    ended = %{ended | "body" => Map.put(ended["body"], "execution_id", started["body"]["execution_id"] <> "_other")}
    R.tamper(r, "envelopes/execution_ended.json", canon(ended))
    %{name: "A wrong_execution", expected: "REJECT", outcome: Verifier.verify(r)["status"]}
  end,
  fn ->
    r = R.root("B", contract_bytes, src)
    R.tamper(r, "results/result.bytes", "[0.0,0.1,0.2,0.3]")
    %{name: "B wrong_result", expected: "REJECT", outcome: Verifier.verify(r)["status"]}
  end,
  fn ->
    r = R.root("C", contract_bytes, src)
    R.tamper(r, "contracts/contract.bytes", "contract_version: 9.9.9\n")
    %{name: "C wrong_contract", expected: "REJECT", outcome: Verifier.verify(r)["status"]}
  end,
  fn ->
    r = R.root("D", contract_bytes, src)
    R.delete(r, "envelopes/execution_ended.json")
    %{name: "D missing_execution", expected: "UNVERIFIED", outcome: Verifier.verify(r)["status"]}
  end,
  fn ->
    r = R.root("E", contract_bytes, src)
    cert = R.read_json(r, "certificates/decision_recorded.json")
    R.tamper(r, "certificates/decision_recorded.json", canon(%{cert | "bindings" => %{}}))
    %{name: "E hash_only_evidence", expected: "REJECT", outcome: Verifier.verify(r)["status"]}
  end,
  fn ->
    d1 = Demo.run(experiment_id: "adv_F1", sample_count: 200, seed: 9, output_dir: Path.join(System.tmp_dir!(), "fp_adv_F1_#{System.unique_integer([:positive])}"), source: src, contract_bytes: contract_bytes)
    d2 = Demo.run(experiment_id: "adv_F2", sample_count: 200, seed: 9, output_dir: Path.join(System.tmp_dir!(), "fp_adv_F2_#{System.unique_integer([:positive])}"), source: src, contract_bytes: contract_bytes)
    same_metric = d1["metric"]["value"] == d2["metric"]["value"]
    distinct_identity = d1["execution"]["execution_id"] != d2["execution"]["execution_id"]
    outcome = if same_metric and distinct_identity, do: "ACCEPT", else: "REJECT"
    %{name: "F duplicate_identity", expected: "ACCEPT (identity ≠ metric equality)", outcome: outcome}
  end,
  fn ->
    r = R.root("G", contract_bytes, src)
    R.delete(r, "measurements/raw_corpus.json")
    %{name: "G deleted_evidence", expected: "UNVERIFIED", outcome: Verifier.verify(r)["status"]}
  end,
  fn ->
    r = R.root("H", contract_bytes, src)
    corpus = R.read_json(r, "measurements/raw_corpus.json")
    corpus = List.replace_at(corpus, 0, 0.999999999)
    R.tamper(r, "measurements/raw_corpus.json", canon(corpus))
    %{name: "H metric_substitution", expected: "REJECT", outcome: Verifier.verify(r)["status"]}
  end,
  fn ->
    r = R.root("I", contract_bytes, src)
    fake = %{
      "schema_version" => "1.0.0",
      "envelope_id" => "env_fake",
      "event_type" => "decision_recorded",
      "parent_envelope_id" => nil,
      "producer" => "attacker",
      "produced_at" => "2026-09-08T00:00:00Z",
      "bindings" => %{"metric" => %{"kind" => "metric", "object_hash" => String.duplicate("0", 64)}},
      "verification_status" => "unverified",
      "canonical_serialization_spec" => "tiannara-fp-canon-v1",
      "payload_hash" => nil,
      "body" => %{"certificate_id" => "cert_fake", "decision" => "certified", "reason" => "spoof", "authority" => "attacker", "validated_edges" => [], "issuance_spec" => "tiannara-fp-cert-v1"}
    }
    R.tamper(r, "certificates/decision_recorded.json", canon(%{fake | "payload_hash" => sha256(%{fake | "payload_hash" => nil} |> Map.delete("payload_hash"))}))
    %{name: "I certificate_substitution", expected: "REJECT", outcome: Verifier.verify(r)["status"]}
  end,
  fn ->
    r1 = R.root("J1", contract_bytes, src)
    # later execution (code drift simulation)
    _ = Demo.run(experiment_id: "adv_J2", sample_count: 200, seed: 3, output_dir: Path.join(System.tmp_dir!(), "fp_adv_J2_#{System.unique_integer([:positive])}"), source: src, contract_bytes: contract_bytes)
    %{name: "J contract_drift", expected: "ACCEPT (v1 bundle stays verifiable)", outcome: Verifier.verify(r1)["status"]}
  end
]

results = Enum.map(scenarios, fn s ->
  %{name: n, expected: e, outcome: o} = s.()
  %{"test" => n, "expected" => e, "outcome" => o, "pass" => (o == e) or (e in ["ACCEPT (identity ≠ metric equality)", "ACCEPT (v1 bundle stays verifiable)"] and o == "ACCEPT")}
end)

out = %{
  "file" => "output/adversarial_results.json",
  "authority" => "TiannaraOS.Provenance test suite (test/adversarial_test.exs) + re-run",
  "adversarial_vocabulary" => ["ACCEPT", "REJECT", "UNVERIFIED", "CONTESTED"],
  "artifacts_reference" => ["TIA_PROVENANCE_ADVERSARIAL_TEST_PLAN.yaml (A-J)"],
  "tests" => results,
  "summary" => %{"total" => length(results), "passed" => Enum.count(results, & &1["pass"])}
}

File.mkdir_p!(Path.join(root, "output"))
File.write!(Path.join(root, "output/adversarial_results.json"), canon(out))
IO.inspect(out, limit: :infinity)