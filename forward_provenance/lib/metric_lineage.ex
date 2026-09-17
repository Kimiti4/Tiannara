defmodule TiannaraOS.Provenance.MetricLineage do
  @moduledoc """
  Stage 5 (Council-authorized): Metric Lineage.

  Establishes the provenance chain RESULT <- EXECUTION and
  METRIC <- RESULT + METRIC_DEFINITION as a normative DERIVATION CONTRACT, and
  provides an independent verification path that recomputes every identity
  from canonical bytes (never trusting producer memory).

  Governing commitments (see spec/metric_lineage.yaml for the normative copy):

    * VALUE != VALIDITY: a metric is provenance-qualified only when its
      identity is bound to a resolved result and a resolved metric definition.
      A metric that merely exists, has a plausible value, or passes a hash
      check but is NOT lineage-bound is REJECTED as a provenance claim.
      (The pre-existing TiannaraOS.Provenance.Metric identity is recorded as a
      LIMITATION: it does not bind the metric to its result, so it is not
      provenance-qualified under Stage 5.)
    * canonical result identity: result_id = sha256(execution_id, attempt,
      payload_hash, canon-spec, lineage-spec) - deterministic, attempt-bound,
      with NO timestamp/process/position dependence.
    * canonical metric identity: metric_id = sha256(kind, result_id,
      metric_definition.id, canonical value, corpus_sha256).
    * definition identity: metric_definition.id = sha256(kind, content fields).
      A definition change in ANY content field (formula, aggregation,
      input-selection, normalization, units, population, window, rounding)
      yields a DIFFERENT definition identity, regardless of the human name.
    * determinism: identical canonical result bytes + identical definition +
      identical corpus produce byte-identical lineage (same lineage_id).
    * failure semantics (Stage 4 preserved): only terminal status `completed`
      is certifiable; failed/timed_out/cancelled/aborted/unknown yield
      NOT CERTIFIABLE; partial remains non-certifiable. No silent change.
    * distributed: a declared parent_execution_id that does not resolve in the
      identity authority yields UNVERIFIED (never auto-attribution, Stage 4).
    * observability: provenance failures are NOT collapsed; each yields a
      distinct reason (missing_execution, missing_result, result_mismatch,
      metric_mismatch, definition_mismatch, attempt_mismatch, orphan_lineage,
      invalid_terminal_state, canonicalization_mismatch).

  The lineage is built with derive/1 and verified with verify_lineage/1 (pure,
  no producer memory) and verify_bundle/1 (reads ONLY a self-contained bundle
  directory). Stage 5 does NOT issue certificates: certificate state/authority
  semantics remain Stage 6 scope.
  """

  alias TiannaraOS.Provenance.{Canon, Identity, IdentityAuthority, RuntimeContract}

  @lineage_spec "tiannara-fp-metric-lineage-v1"
  @canon_spec "tiannara-fp-canon-v1"
  @legal_terminal_statuses [
    "completed",
    "failed",
    "partial",
    "timed_out",
    "cancelled",
    "aborted",
    "unknown"
  ]

  @required_edges [
    "result_derived_from_execution",
    "metric_computed_from_result"
  ]

  @doc "Machine-readable Stage-5 contract descriptor."
  def spec do
    %{
      "lineage_spec" => @lineage_spec,
      "canonical_serialization_spec" => @canon_spec,
      "chain" => "SOURCE -> CONTRACT -> EXECUTION -> RESULT -> METRIC",
      "established" => "RESULT <- EXECUTION; METRIC <- RESULT + METRIC_DEFINITION",
      "result_identity" => "sha256(execution_id, attempt, payload_hash, canon, lineage)",
      "metric_identity" => "sha256(kind, result_id, metric_definition_id, value, corpus_sha256)",
      "definition_identity" => "sha256(kind, content fields): any field change -> different id",
      "determinism" => "same result bytes + same definition + same corpus -> same lineage_id",
      "certifiable_terminal" => "completed only (Stage 4 preserved)",
      "unresolved_parent" => "UNVERIFIED, never auto-attributed (Stage 4 preserved)",
      "failure_reasons" => %{
        "missing_execution" => "result references an execution the authority never registered",
        "missing_result" => "metric references a result that cannot be resolved",
        "result_mismatch" => "recomputed result identity != recorded identity",
        "metric_mismatch" => "recomputed metric identity != recorded identity",
        "definition_mismatch" => "recomputed definition identity != referenced definition",
        "attempt_mismatch" => "result attempt != execution attempt (retry collapsed)",
        "orphan_lineage" => "chain edge missing or dangling",
        "invalid_terminal_state" => "terminal status not legal, or execution not certifiable",
        "canonicalization_mismatch" => "recomputed value/payload/corpus != recorded"
      }
    }
  end

  @doc """
  Metric definition identity (Q6). Any change in ANY content field binds a new
  identity; the human-readable name is NOT the identity. `version` is a label
  only; the content hash is the identity.
  """
  def definition(opts) do
    name = Keyword.fetch!(opts, :name)
    aggregation = Keyword.fetch!(opts, :aggregation)
    input_field = Keyword.fetch!(opts, :input_field)
    normalization = Keyword.get(opts, :normalization, "none")
    units = Keyword.get(opts, :units, "scalar")
    population = Keyword.get(opts, :population, "all_trials")
    window = Keyword.get(opts, :window, "full")
    rounding = Keyword.get(opts, :rounding, 6)
    op = Keyword.get(opts, :op, "tiannara-fp-aggregate-v1")
    version = Keyword.get(opts, :version, "1.0.0")

    fields = %{
      "name" => name,
      "aggregation" => aggregation,
      "input_field" => input_field,
      "normalization" => normalization,
      "units" => units,
      "population" => population,
      "window" => window,
      "rounding" => rounding,
      "op" => op
    }

    id = Identity.object_id("metric_definition", fields)
    Map.put(id, "version", version)
  end

  @doc "Canonical result identity for (execution, attempt, payload hash)."
  def result_id(execution_id, attempt, payload_hash) do
    Canon.sha256(%{
      "lineage_spec" => @lineage_spec,
      "execution_id" => execution_id,
      "attempt" => attempt,
      "payload_hash" => payload_hash,
      "canonical_serialization_spec" => @canon_spec
    })
  end

  @doc """
  Deterministic aggregation used both at derivation and at independent
  recomputation (mean/stddev over the canonical corpus). Identical to the
  pre-existing Metric aggregation formula so both paths agree.
  """
  def recompute_value(definition, corpus) do
    rounding = definition["fields"]["rounding"]

    case definition["fields"]["aggregation"] do
      "mean_stddev" ->
        n = length(corpus)
        mean = Enum.sum(corpus) / n |> Float.round(rounding)
        variance = corpus |> Enum.map(fn x -> :math.pow(x - mean, 2) end) |> Enum.sum() |> Kernel./(n)
        std_dev = :math.sqrt(variance) |> Float.round(rounding)
        %{"mean" => mean, "std_dev" => std_dev}

      other ->
        raise ArgumentError, "unsupported aggregation: #{inspect(other)}"
    end
  end

  @doc """
  Build the full Stage-5 lineage for one execution attempt.

  opts (map keys):
    execution_id, producer, attempt (default 1), status
    payload            the raw result payload (JSON-compatible term)
    definition         metric_definition identity object (definition/1)
    corpus             raw measurement samples
    parent_execution_id (optional; Stage-4 distributed linkage)
    execution_records  optional [started_norm, terminal_norm] for bundle envelopes
    source, contract, contract_bytes, environment (optional identity objects
    for the evidence bundle)

  Returns {:ok, lineage} | {:error, reason, context}.
  """
  def derive(opts) do
    execution_id = Map.fetch!(opts, "execution_id")
    producer = Map.get(opts, "producer", "unknown_producer")
    attempt = Map.get(opts, "attempt", 1)
    status = Map.fetch!(opts, "status")
    definition = Map.fetch!(opts, "definition")
    payload = Map.fetch!(opts, "payload")
    corpus = Map.fetch!(opts, "corpus")
    parent_execution_id = Map.get(opts, "parent_execution_id")

    with :ok <- check_status(status),
         :ok <- check_execution_registered(execution_id),
         {:ok, result_rec} <- build_result(execution_id, attempt, payload),
         {:ok, value, metric_rec} <- build_metric(result_rec, definition, corpus) do
      lineage = %{
        "lineage_spec" => @lineage_spec,
        "execution" => %{
          "execution_id" => execution_id,
          "producer" => producer,
          "attempt" => attempt,
          "status" => status
        },
        "result" => result_rec,
        "metric_definition" => definition,
        "metric" => metric_rec,
        "value" => value,
        "corpus" => corpus,
        "parent_execution_id" => parent_execution_id,
        "edges" => build_edges(result_rec, metric_rec, parent_execution_id),
        "source" => Map.get(opts, "source"),
        "contract" => Map.get(opts, "contract"),
        "contract_bytes" => Map.get(opts, "contract_bytes"),
        "environment" => Map.get(opts, "environment"),
        "execution_records" => Map.get(opts, "execution_records")
      }

      {:ok, Map.put(lineage, "lineage_id", lineage_id(lineage))}
    else
      err -> err
    end
  end

  @doc "Canonical, deterministic identity of a lineage (M15/M16)."
  def lineage_id(lineage) do
    Canon.sha256(%{
      "lineage_spec" => @lineage_spec,
      "execution_id" => lineage["execution"]["execution_id"],
      "attempt" => lineage["execution"]["attempt"],
      "status" => lineage["execution"]["status"],
      "result_id" => lineage["result"]["result_id"],
      "payload_hash" => lineage["result"]["payload_hash"],
      "metric_definition" => lineage["metric_definition"]["object_hash"],
      "metric_id" => lineage["metric"]["metric_id"],
      "value" => lineage["value"],
      "corpus_sha256" => lineage["metric"]["corpus_sha256"],
      "parent_execution_id" => lineage["parent_execution_id"]
    })
  end

  @doc """
  Build a canonical result record bound to one execution attempt (Q1/Q5/Q7).
  Returns {:error, :missing_execution, ctx} when the execution is not
  registered with the identity authority (Q8/Q9: no orphan result).
  """
  def build_result(execution_id, attempt, payload) do
    case IdentityAuthority.resolve(execution_id) do
      {:error, :unregistered} ->
        {:error, :missing_execution, %{"execution_id" => execution_id, "attempt" => attempt}}

      {:ok, authority_record} ->
        result_bytes = Canon.canon(payload)
        payload_hash = Canon.sha256_bytes(result_bytes)
        rid = result_id(execution_id, attempt, payload_hash)

        result_rec = %{
          "result_id" => "result_" <> rid,
          "execution_id" => execution_id,
          "authority" => authority_record["authority"],
          "attempt" => attempt,
          "payload_hash" => payload_hash,
          "result_bytes" => result_bytes,
          "canonical_serialization_spec" => @canon_spec
        }

        {:ok, result_rec}
    end
  end

  @doc """
  Build a lineage-qualified metric bound to a result and a definition (Q3/Q5).
  Returns {:error, reason, ctx} when the result's execution cannot be resolved
  (:missing_execution) — an orphan result can never produce a metric.
  """
  def build_metric(result_rec, definition, corpus) do
    case IdentityAuthority.resolve(result_rec["execution_id"]) do
      {:error, :unregistered} ->
        {:error, :missing_execution, %{"execution_id" => result_rec["execution_id"]}}

      {:ok, _} ->
        value = recompute_value(definition, corpus)
        corpus_sha256 = Canon.sha256(corpus)

        metric_id =
          Identity.object_id("metric", %{
            "lineage_spec" => @lineage_spec,
            "result_id" => result_rec["result_id"],
            "metric_definition" => definition["object_hash"],
            "value" => value,
            "corpus_sha256" => corpus_sha256
          })

        metric_rec = %{
          "metric_id" => metric_id,
          "result_id" => result_rec["result_id"],
          "definition_id" => definition["object_hash"],
          "corpus_sha256" => corpus_sha256,
          "compute_spec" => definition["fields"]["op"]
        }

        {:ok, value, metric_rec}
    end
  end

  defp build_edges(result_rec, metric_rec, parent_execution_id) do
    edges = [
      %{
        "type" => "result_derived_from_execution",
        "from" => %{"kind" => "execution", "id" => result_rec["execution_id"]},
        "to" => %{"kind" => "result", "id" => result_rec["result_id"]}
      },
      %{
        "type" => "metric_computed_from_result",
        "from" => %{"kind" => "result", "id" => result_rec["result_id"]},
        "to" => %{"kind" => "metric", "id" => metric_rec["metric_id"]["object_hash"]}
      }
    ]

    case parent_execution_id do
      nil -> edges
      parent when is_binary(parent) -> [parent_of_edge(parent, result_rec["execution_id"]) | edges]
    end
  end

  defp parent_of_edge(parent_id, child_id) do
    %{
      "type" => "PARENT_OF",
      "from" => %{"kind" => "execution", "id" => parent_id},
      "to" => %{"kind" => "execution", "id" => child_id}
    }
  end

  @doc """
  Independent lineage verification (verifier never asks the producer).

  Recomputes every identity from the lineage's own recorded fields and returns
  %{"verdict" => ..., "certifiable" => bool, "checks" => [...],
    "lineage_id" => ...}.

  Verdicts: ACCEPT | NOT CERTIFIABLE | UNVERIFIED | REJECT.
  """
  def verify_lineage(lineage) do
    checks = run_checks(lineage)
    certifiable = RuntimeContract.certifiable?(lineage["execution"]["status"])
    verdict = gate(checks, certifiable)

    %{"verdict" => verdict, "certifiable" => certifiable, "checks" => checks, "lineage_id" => lineage["lineage_id"]}
  end

  defp run_checks(lineage) do
    execution = lineage["execution"]
    result = lineage["result"]
    metric = lineage["metric"]
    definition = lineage["metric_definition"]
    corpus = lineage["corpus"]
    parent = lineage["parent_execution_id"]

    [
      execution_registered_check(execution["execution_id"], execution["producer"]),
      terminal_status_check(execution["status"]),
      attempt_consistency_check(execution, result),
      result_execution_match_check(execution["execution_id"], result["execution_id"]),
      result_payload_check(result["result_bytes"], result["payload_hash"]),
      result_identity_check(execution, result),
      definition_identity_check(definition, metric["definition_id"]),
      value_recompute_check(definition, corpus, lineage["value"]),
      corpus_hash_check(corpus, metric["corpus_sha256"]),
      metric_identity_check(result, metric, lineage["value"]),
      metric_result_match_check(result, metric),
      edges_check(lineage["edges"], result, metric),
      parent_resolution_check(parent)
    ]
  end

  defp execution_registered_check(execution_id, producer) do
    ok =
      case IdentityAuthority.resolve(execution_id) do
        {:ok, rec} -> rec["producer"] == producer
        _ -> false
      end

    check("execution_registered", ok, "missing_execution",
      "execution_id #{inspect(execution_id)} must be registered with the identity authority under the recorded producer")
  end

  defp terminal_status_check(status) do
    check("terminal_status", status in @legal_terminal_statuses, "invalid_terminal_state",
      "terminal status #{inspect(status)} must be one of #{inspect(@legal_terminal_statuses)}")
  end

  defp attempt_consistency_check(execution, result) do
    check("attempt_consistency", result["attempt"] == execution["attempt"], "attempt_mismatch",
      "result attempt #{result["attempt"]} must equal execution attempt #{execution["attempt"]} (retries are distinct)")
  end

  defp result_execution_match_check(execution_id, result_execution_id) do
    check("result_execution_match", result_execution_id == execution_id, "result_mismatch",
      "result references execution #{inspect(result_execution_id)} but lineage execution is #{inspect(execution_id)}")
  end

  defp result_payload_check(result_bytes, payload_hash) do
    ok = is_binary(result_bytes) and Canon.sha256_bytes(result_bytes) == payload_hash

    check("result_payload", ok, "canonicalization_mismatch",
      "payload_hash must recompute from canonical result bytes")
  end

  defp result_identity_check(execution, result) do
    recomputed = result_id(execution["execution_id"], result["attempt"], result["payload_hash"])
    stored = String.replace_prefix(result["result_id"], "result_", "")

    check("result_identity", recomputed == stored, "result_mismatch",
      "recomputed result identity #{String.slice(recomputed, 0, 12)}... != recorded #{String.slice(stored, 0, 12)}...")
  end

  defp definition_identity_check(definition, recorded_definition_id) do
    recomputed = Identity.object_id("metric_definition", definition["fields"])["object_hash"]
    recorded_definition_id = String.replace_prefix(to_string(recorded_definition_id || ""), "metric_definition_", "")

    check("definition_identity", recorded_definition_id != "" and recomputed == recorded_definition_id,
      "definition_mismatch",
      "the stored definition content hashes to #{String.slice(recomputed, 0, 12)}... but the metric references #{String.slice(recorded_definition_id, 0, 12)}...")
  end

  defp value_recompute_check(definition, corpus, stored_value) do
    recomputed = recompute_value(definition, corpus)

    check("value_recompute", recomputed == stored_value, "canonicalization_mismatch",
      "recorded metric value must equal the deterministic recomputation from the raw corpus")
  end

  defp corpus_hash_check(corpus, corpus_sha256) do
    check("corpus_hash", Canon.sha256(corpus) == corpus_sha256, "canonicalization_mismatch",
      "corpus sha256 must recompute from the recorded raw corpus")
  end

  defp metric_identity_check(result, metric, value) do
    recomputed =
      Identity.object_id("metric", %{
        "lineage_spec" => @lineage_spec,
        "result_id" => result["result_id"],
        "metric_definition" => metric["definition_id"],
        "value" => value,
        "corpus_sha256" => metric["corpus_sha256"]
      })

    ok = metric["metric_id"]["object_hash"] == recomputed["object_hash"]

    check("metric_identity", ok, "metric_mismatch",
      "recomputed metric identity must equal the recorded metric identity (metric must be derived from THIS result under THIS definition)")
  end

  defp metric_result_match_check(result, metric) do
    check("metric_result_match", metric["result_id"] == result["result_id"], "orphan_lineage",
      "the metric's recorded result_id must equal the lineage result's result_id (no dangling binding)")
  end

  defp edges_check(edges, result, metric) do
    types = Enum.map(edges || [], & &1["type"])

    ok =
      Enum.all?(@required_edges, fn type -> type in types end) &&
        Enum.any?(edges || [], fn e ->
          e["type"] == "result_derived_from_execution" &&
            e["to"]["id"] == result["result_id"] &&
            e["from"]["id"] == result["execution_id"]
        end) &&
        Enum.any?(edges || [], fn e ->
          e["type"] == "metric_computed_from_result" &&
            e["from"]["id"] == result["result_id"] &&
            e["to"]["id"] == metric["metric_id"]["object_hash"]
        end)

    check("edges", ok, "orphan_lineage",
      "required lineage edges must be present and must join the recorded result/metric identities")
  end

  defp parent_resolution_check(parent) do
    case parent do
      nil ->
        %{"check" => "parent_resolution", "status" => "ACCEPT", "reason" => nil, "detail" => "no parent declared (root execution)"}

      parent when is_binary(parent) ->
        if IdentityAuthority.registered?(parent) do
          %{"check" => "parent_resolution", "status" => "ACCEPT", "reason" => nil, "detail" => "declared parent resolved in the authority"}
        else
          %{
            "check" => "parent_resolution",
            "status" => "UNVERIFIED",
            "reason" => "unresolved_parent",
            "detail" => "declared parent is not registered; chain is UNVERIFIED, never auto-attributed"
          }
        end
    end
  end

  defp check(name, ok, reason, detail) do
    %{"check" => name, "status" => if(ok, do: "ACCEPT", else: "REJECT"), "reason" => if(ok, do: nil, else: reason), "detail" => detail}
  end

  defp gate(checks, certifiable) do
    rejected = Enum.find(checks, fn c -> c["status"] == "REJECT" end)
    unresolved = Enum.find(checks, fn c -> c["status"] == "UNVERIFIED" end)

    cond do
      rejected != nil -> "REJECT"
      unresolved != nil -> "UNVERIFIED"
      certifiable -> "ACCEPT"
      true -> "NOT CERTIFIABLE"
    end
  end

  defp check_status(status) do
    if status in @legal_terminal_statuses,
      do: :ok,
      else: {:error, :invalid_terminal_state, %{"status" => status, "legal" => @legal_terminal_statuses}}
  end

  defp check_execution_registered(execution_id) do
    case IdentityAuthority.resolve(execution_id) do
      {:ok, _} -> :ok
      {:error, :unregistered} -> {:error, :missing_execution, %{"execution_id" => execution_id}}
    end
  end

  @doc """
  Export a self-contained Stage-5 evidence bundle (NO certificates) under
  `dir`. Every written file is listed in meta/bundle_manifest.json with its
  sha256 under the canon spec, so an independent verifier reads ONLY bundle
  bytes. Returns %{"bundle_id", "root", "manifest", "files", "lineage_id"}.
  """
  def export_bundle(lineage, dir) do
    File.rm_rf!(dir)
    written = write_files(dir, bundle_ingest(lineage))

    bundle_id = "stage5_bundle_" <> Canon.sha256(%{"lineage_id" => lineage["lineage_id"], "files" => written})

    manifest = %{
      "bundle_name" => "Stage5MetricLineageEvidenceBundle",
      "bundle_id" => bundle_id,
      "schema_version" => "1.0.0",
      "lineage_spec" => @lineage_spec,
      "canonical_serialization_spec" => @canon_spec,
      "lineage_id" => lineage["lineage_id"],
      "files" => written,
      "audit_trail" => "audit_trail.md"
    }

    File.mkdir_p!(Path.join(dir, "meta"))
    File.write!(Path.join(dir, "meta/bundle_manifest.json"), Canon.canon(manifest))
    File.write!(Path.join(dir, "audit_trail.md"), audit_trail(lineage, bundle_id))

    %{"bundle_id" => bundle_id, "root" => dir, "manifest" => manifest, "files" => written, "lineage_id" => lineage["lineage_id"]}
  end

  defp bundle_ingest(lineage) do
    [
      {"identity_objects/source.json", canon_or_nil(lineage["source"])},
      {"identity_objects/contract.json", canon_or_nil(lineage["contract"])},
      {"identity_objects/environment.json", canon_or_nil(lineage["environment"])},
      {"identity_objects/metric_definition.json", Canon.canon(lineage["metric_definition"])},
      {"identity_objects/execution.json", Canon.canon(lineage["execution"])},
      {"contracts/contract.bytes", Map.get(lineage, "contract_bytes")},
      {"envelopes/execution_started.json", started_env_or_nil(lineage)},
      {"envelopes/execution_ended.json", ended_env_or_nil(lineage)},
      {"results/result.bytes", lineage["result"]["result_bytes"]},
      {"metrics/metric.json", Canon.canon(lineage["metric"])},
      {"measurements/raw_corpus.json", Canon.canon(lineage["corpus"])},
      {"graph/provenance_graph.json", Canon.canon(%{"lineage_id" => lineage["lineage_id"], "edges" => lineage["edges"]})}
    ]
  end

  defp started_env_or_nil(lineage) do
    case lineage["execution_records"] do
      [started, _term] -> runtime_env_or_nil(RuntimeContract.to_envelopes([started]))
      _ -> nil
    end
  end

  defp ended_env_or_nil(lineage) do
    case lineage["execution_records"] do
      [_started, term] -> runtime_env_or_nil(RuntimeContract.to_envelopes([term]))
      _ -> nil
    end
  end

  defp runtime_env_or_nil([env | _]), do: Canon.canon(env)
  defp runtime_env_or_nil([]), do: nil

  defp canon_or_nil(nil), do: nil
  defp canon_or_nil(term), do: Canon.canon(term)

  defp write_files(dir, ingest) do
    ingest
    |> Enum.reject(fn {_path, bytes} -> bytes == nil end)
    |> Enum.reduce(%{}, fn {path, bytes}, acc ->
      full = Path.join(dir, path)
      File.mkdir_p!(Path.dirname(full))
      File.write!(full, bytes)
      Map.put(acc, path, Canon.sha256_bytes(bytes))
    end)
  end

  defp audit_trail(lineage, bundle_id) do
    """
    # Stage 5 Metric Lineage — Evidence Bundle audit trail

    bundle_id: #{bundle_id}
    lineage_id: #{lineage["lineage_id"]}
    lineage_spec: #{@lineage_spec}

    ## Execution
    execution_id: #{lineage["execution"]["execution_id"]}
    producer: #{lineage["execution"]["producer"]}
    attempt: #{lineage["execution"]["attempt"]}
    status: #{lineage["execution"]["status"]}

    ## Result
    result_id: #{lineage["result"]["result_id"]}
    payload_hash: #{lineage["result"]["payload_hash"]}

    ## Metric definition
    definition_id: #{lineage["metric_definition"]["object_hash"]}
    aggregation: #{lineage["metric_definition"]["fields"]["aggregation"]}
    rounding: #{lineage["metric_definition"]["fields"]["rounding"]}

    ## Metric
    metric_id: #{lineage["metric"]["metric_id"]["object_hash"]}
    corpus_sha256: #{lineage["metric"]["corpus_sha256"]}

    ## Recomposition protocol
    Every file in this bundle is referenced from meta/bundle_manifest.json with
    its sha256 under spec/canonicalization_spec.yaml (canon v1). An independent
    verifier (MetricLineage.verify_bundle/1) recomputes result identity, metric
    identity, definition identity, and metric value from these bytes alone and
    NEVER asks the producer whether the lineage is valid.

    ## Stage 5 scope
    This bundle contains NO certificate. Certificate state/authority semantics
    (Stage 6) decide what, if anything, this lineage certifies.
    """
  end

  @doc """
  Independent bundle verification (section 22). Reads ONLY the bundle
  directory, verifies manifest file hashes, reconstructs the lineage from
  bundle bytes, and runs verify_lineage/1. Returns the same verdict shape.
  """
  def verify_bundle(dir) do
    manifest_path = Path.join(dir, "meta/bundle_manifest.json")

    with {:ok, manifest} <- read_json(manifest_path),
         :ok <- verify_manifest_hashes(dir, manifest["files"]),
         {:ok, lineage} <- lineage_from_bundle(dir) do
      result = verify_lineage(lineage)
      Map.put(result, "bundle_id", manifest["bundle_id"])
    else
      err ->
        %{
          "verdict" => "UNVERIFIED",
          "certifiable" => false,
          "checks" => [],
          "lineage_id" => nil,
          "bundle_id" => nil,
          "error" => inspect(err)
        }
    end
  end

  defp read_json(path) do
    case File.read(path) do
      {:ok, bytes} -> {:ok, :json.decode(bytes)}
      {:error, _} -> {:error, :manifest_missing}
    end
  end

  defp verify_manifest_hashes(dir, files) do
    Enum.reduce_while(files, :ok, fn {path, expected}, :ok ->
      case File.read(Path.join(dir, path)) do
        {:ok, bytes} ->
          if Canon.sha256_bytes(bytes) == expected, do: {:cont, :ok}, else: {:halt, {:error, :file_hash_mismatch, path}}

        _ ->
          {:halt, {:error, :file_missing, path}}
      end
    end)
  end

  defp lineage_from_bundle(dir) do
    read_json = fn p ->
      case File.read(Path.join(dir, p)) do
        {:ok, bytes} -> {:ok, :json.decode(bytes)}
        {:error, _} -> {:error, :missing_file, p}
      end
    end

    read_bytes = fn p ->
      case File.read(Path.join(dir, p)) do
        {:ok, bytes} -> {:ok, bytes}
        {:error, _} -> {:error, :missing_file, p}
      end
    end

    with {:ok, execution} <- read_json.("identity_objects/execution.json"),
         {:ok, definition} <- read_json.("identity_objects/metric_definition.json"),
         {:ok, metric} <- read_json.("metrics/metric.json"),
         {:ok, corpus} <- read_json.("measurements/raw_corpus.json"),
         {:ok, graph} <- read_json.("graph/provenance_graph.json"),
         {:ok, result_bytes} <- read_bytes.("results/result.bytes") do
      payload_hash = Canon.sha256_bytes(result_bytes)

      result_rec = %{
        "result_id" => metric["result_id"],
        "execution_id" => execution["execution_id"],
        "authority" => "tiannara-fp-identity-v1",
        "attempt" => execution["attempt"],
        "payload_hash" => payload_hash,
        "result_bytes" => result_bytes,
        "canonical_serialization_spec" => @canon_spec
      }

      lineage = %{
        "lineage_spec" => @lineage_spec,
        "execution" => execution,
        "result" => result_rec,
        "metric_definition" => definition,
        "metric" => metric,
        "value" => recompute_value(definition, corpus),
        "corpus" => corpus,
        "parent_execution_id" => nil,
        "edges" => graph["edges"],
        "execution_records" => nil,
        "source" => nil,
        "contract" => nil,
        "contract_bytes" => nil,
        "environment" => nil,
        "lineage_id" => graph["lineage_id"]
      }

      case find_parent_edges(graph["edges"]) do
        nil -> {:ok, lineage}
        parent_id -> {:ok, %{lineage | "parent_execution_id" => parent_id}}
      end
    end
  end

  defp find_parent_edges(edges) do
    case Enum.find(edges || [], fn e -> e["type"] == "PARENT_OF" end) do
      %{"from" => %{"id" => parent_id}} -> parent_id
      _ -> nil
    end
  end
end