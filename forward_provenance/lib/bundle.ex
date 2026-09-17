defmodule TiannaraOS.Provenance.Bundle do
  @moduledoc """
  Independent Evidence Bundle producer.

  Produces a self-contained, byte-exact directory with:
    bundle_manifest.json   (every file listed with its sha256 under the canon spec)
    contracts/             (the contract bytes that the execution ran under)
    envelopes/             (all envelopes, one JSON per event)
    identity_objects/      (source/contract/environment/metric identity objects)
    results/               (raw result payload bytes)
    measurements/          (RAW measurement corpus — the load-bearing persistence)
    metrics/               (derived metric manifest + envelope)
    certificates/          (issued certificate)
    graph/                 (provenance graph JSON)
    audit_trail.md         (human-readable independent audit trail)

  The bundle is the *only* thing the independent verifier reads; everything
  must be recomputable from bundle bytes.
  """

  alias TiannaraOS.Provenance.Canon

  # --- straight path ---

  def produce(opts) do
    root = Keyword.fetch!(opts, :dir)
    contract = Keyword.fetch!(opts, :contract)            # contract identity object
    contract_bytes = Keyword.fetch!(opts, :contract_bytes)
    execution = Keyword.fetch!(opts, :execution)
    result = Keyword.fetch!(opts, :result)
    metric = Keyword.fetch!(opts, :metric)
    certificate = Keyword.fetch!(opts, :certificate)
    source = Keyword.fetch!(opts, :source)
    environment = Keyword.fetch!(opts, :environment)
    graph = Keyword.fetch!(opts, :graph)
    demo_id = Keyword.get(opts, :demo_id, "demo")

    ingest =
      %{}
      |> Map.put("contract", Canon.canon(contract))
      |> Map.put("contract_bytes", contract_bytes)
      |> Map.put("source", Canon.canon(source))
      |> Map.put("environment", Canon.canon(environment))
      |> Map.put("execution_started", Canon.canon(execution["started"]))
      |> Map.put("execution_ended", Canon.canon(execution["ended"]))
      |> Map.put("result", result["result_bytes"])
      |> Map.put("result_envelope", Canon.canon(result["envelope"]))
      |> Map.put("metric_envelope", Canon.canon(metric["envelope"]))
      |> Map.put("metric_corpus", Canon.canon(metric["corpus"]))
      |> Map.put("certificate", Canon.canon(certificate["envelope"]))
      |> Map.put("graph", Canon.canon(graph))

    # Split by filename base (drop sensitive/duplicated identities to avoid
    # hash-on-hash cycles; manifest carries per-file checksums).
    filenames = %{
      "contract" => "identity_objects/contract.json",
      "contract_bytes" => "contracts/contract.bytes",
      "source" => "identity_objects/source.json",
      "environment" => "identity_objects/environment.json",
      "execution_started" => "envelopes/execution_started.json",
      "execution_ended" => "envelopes/execution_ended.json",
      "result" => "results/result.bytes",
      "result_envelope" => "envelopes/result_produced.json",
      "metric_envelope" => "metrics/metric_computed.json",
      "metric_corpus" => "measurements/raw_corpus.json",
      "certificate" => "certificates/decision_recorded.json",
      "graph" => "graph/provenance_graph.json"
    }

    written = write_root(root, ingest, filenames)

    bundle_id = "bundle_" <> String.replace(Canon.sha256(%{"demo_id" => demo_id, "files" => written}), "-", "")

    manifest =
      %{
        "bundle_name" => "IndependentEvidenceBundle",
        "bundle_id" => bundle_id,
        "schema_version" => "1.0.0",
        "demo_id" => demo_id,
        "canonical_serialization_spec" => "tiannara-fp-canon-v1",
        "created_by" => "TiannaraOS.Provenance.Bundle",
        "files" => written,
        "audit_trail" => "audit_trail.md"
      }

    manifest_json = Canon.canon(manifest)
    File.mkdir_p!(Path.join(root, "meta"))
    File.write!(Path.join(root, "meta/bundle_manifest.json"), manifest_json)

    build_audit_trail(root, opts)

    %{
      "bundle_id" => bundle_id,
      "root" => root,
      "manifest" => manifest,
      "manifest_sha256" => Canon.sha256(manifest),
      "files" => written
    }
  end

  defp write_root(root, ingest, filenames) do
    ingest
    |> Enum.reduce(%{}, fn {key, bytes}, acc ->
      path = Map.fetch!(filenames, key)
      full = Path.join(root, path)
      File.mkdir_p!(Path.dirname(full))
      File.write!(full, bytes)
      Map.put(acc, path, Canon.sha256_bytes(bytes))
    end)
  end

  defp build_audit_trail(root, opts) do
    execution = Keyword.fetch!(opts, :execution)
    certificate = Keyword.fetch!(opts, :certificate)
    metric = Keyword.fetch!(opts, :metric)

    text = """
    # Independent Evidence Bundle — audit trail

    bundle_name: IndependentEvidenceBundle

    ## 1. What was run
    experiment: #{execution["experiment_id"]}
    execution_id: #{execution["execution_id"]}
    campaign: #{execution["campaign_id"]}

    ## 2. Against what source
    source identity: see identity_objects/source.json
      (repository commit + tree + source manifest hash)

    ## 3. With what contract
    contract: see contracts/contract.bytes
      (contract hash bound in the execution envelope)

    ## 4. With what inputs
    seed: #{execution["seed"]}
    raw measurements: measurements/raw_corpus.json
      (corpus sha256 recorded in metrics/metric_computed.json)

    ## 5. Using what environment
    environment: see identity_objects/environment.json
      (otp/elixir/deps_lock_hash — byte-exact execution environment)

    ## Derived metric
    metric id: #{metric["metric_id"]["object_hash"]}
    mean: #{metric["value"]["mean"]}  std_dev: #{metric["value"]["std_dev"]}

    ## Decision
    certificate_id: #{certificate["certificate_id"]}
    decision: #{certificate["decision"]}
    authority: #{certificate["authority"]}

    ## Recomposition protocol
    Every file in this bundle is referenced from bundle_manifest.json with its
    sha256 computed under spec/canonicalization_spec.yaml (canon v1). An
    independent verifier recomputes every identity from these bytes alone.
    """

    File.mkdir_p!(root)
    File.write!(Path.join(root, "audit_trail.md"), text)
  end
end