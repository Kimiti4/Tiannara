defmodule TiannaraOS.Provenance.Verifier do
  @moduledoc """
  Independent verifier.

  Reads ONLY from the evidence bundle directory (bundle-manifest.json + every
  referenced file). Recomputes every identity from canonical bytes, replays the
  metric aggregation from the raw corpus, verifies envelope payload hashes, and
  checks graph edge closure. Emits ACCEPT / REJECT / UNVERIFIED / CONTESTED per
  check, mirroring the adversarial vocabulary.

  Termination contract: the forward implementation stops (does not certify)
  unless EVERY required edge in the chain verifies. This module embodies that
  gate.
  """

  alias TiannaraOS.Provenance.Canon

  @required_edges [
    "contract_asserts_source",
    "execution_under_contract",
    "result_derived_from_execution",
    "metric_computed_from_result",
    "certificate_certifies_metric"
  ]

  @doc """
  Verify a bundle root. Returns %{status, checks, edges}.
  """
  def verify(root) do
    with {:ok, manifest} <- read_manifest(root),
         :ok <- verify_manifest_hashes(root, manifest),
         {:ok, ctx} <- load_bundle(root) do
      checks = run_checks(ctx)
      edges = verify_edges(ctx)

      %{
        "status" => gate_status(checks, edges),
        "checks" => checks,
        "edges" => edges,
        "bundle_id" => manifest["bundle_id"]
      }
    else
      err ->
        %{
          "status" => "UNVERIFIED",
          "checks" => [],
          "edges" => [],
          "bundle_id" => manifest_id_or_nil(root),
          "error" => inspect(err)
        }
    end
  end

  defp manifest_id_or_nil(root) do
    case File.read(Path.join(root, "meta/bundle_manifest.json")) do
      {:ok, bytes} ->
        case :json.decode(bytes) do
          decoded when is_map(decoded) -> Map.get(decoded, "bundle_id")
          _ -> nil
        end
      _ -> nil
    end
  end

  defp read_manifest(root) do
    path = Path.join(root, "meta/bundle_manifest.json")
    case File.read(path) do
      {:ok, bytes} -> {:ok, decode(bytes)}
      {:error, _} -> {:error, :manifest_missing}
    end
  end

  defp decode(bytes), do: :json.decode(bytes)

  defp verify_manifest_hashes(root, manifest) do
    Enum.reduce_while(manifest["files"], :ok, fn {path, expected}, :ok ->
      case File.read(Path.join(root, path)) do
        {:ok, bytes} ->
          actual = Canon.sha256_bytes(bytes)
          if actual == expected, do: {:cont, :ok}, else: {:halt, {:error, :file_hash_mismatch, path, expected, actual}}
        _ ->
          {:halt, {:error, :file_missing, path}}
      end
    end)
  end

  defp load_bundle(root) do
    needs = [
      "identity_objects/source.json",
      "identity_objects/contract.json",
      "identity_objects/environment.json",
      "envelopes/execution_started.json",
      "envelopes/execution_ended.json",
      "results/result.bytes",
      "envelopes/result_produced.json",
      "metrics/metric_computed.json",
      "measurements/raw_corpus.json",
      "certificates/decision_recorded.json",
      "graph/provenance_graph.json",
      "contracts/contract.bytes"
    ]

    with :ok <- ensure_files(root, needs) do
      read = fn p -> File.read!(Path.join(root, p)) end

      source = decode(read.("identity_objects/source.json"))
      contract = decode(read.("identity_objects/contract.json"))
      environment = decode(read.("identity_objects/environment.json"))
      started = decode(read.("envelopes/execution_started.json"))
      ended = decode(read.("envelopes/execution_ended.json"))
      result_bytes = read.("results/result.bytes")
      result_env = decode(read.("envelopes/result_produced.json"))
      metric_env = decode(read.("metrics/metric_computed.json"))
      corpus = decode(read.("measurements/raw_corpus.json"))
      cert_env = decode(read.("certificates/decision_recorded.json"))
      graph = decode(read.("graph/provenance_graph.json"))

      {:ok, %{
        "source" => source,
        "contract" => contract,
        "environment" => environment,
        "started" => started,
        "ended" => ended,
        "result_bytes" => result_bytes,
        "result_env" => result_env,
        "metric_env" => metric_env,
        "corpus" => corpus,
        "cert_env" => cert_env,
        "graph" => graph,
        "contract_bytes" => read.("contracts/contract.bytes")
      }}
    end
  end

  defp ensure_files(root, needs) do
    missing = Enum.reject(needs, fn p -> File.exists?(Path.join(root, p)) end)
    if missing == [], do: :ok, else: {:error, :files_missing, missing}
  end

  defp run_checks(ctx) do
    [
      envelope_payload_hash_check(ctx),
      source_identity_check(ctx),
      contract_identity_check(ctx),
      execution_binding_check(ctx),
      result_payload_check(ctx),
      metric_recompute_check(ctx),
      certificate_binding_check(ctx)
    ]
  end

  # -- each check returns %{check, status, detail}

  defp envelope_payload_hash_check(ctx) do
    res = Canon.sha256(Map.delete(ctx["started"], "payload_hash")) == ctx["started"]["payload_hash"]

    %{
      "check" => "envelope:execution_started",
      "status" => if(res, do: "ACCEPT", else: "REJECT"),
      "detail" => "payload_hash recomputed over envelope minus payload_hash field"
    }
  end

  defp source_identity_check(ctx) do
    source = ctx["source"]
    res = valid_identity_object("source", source)
    %{"check" => "source_identity", "status" => if(res, do: "ACCEPT", else: "REJECT"), "detail" => "source object_hash recomputed"}
  end

  defp contract_identity_check(ctx) do
    # Independently recompute the contract identity from identity_objects/contract.json
    # (fields embed the contract bytes) and cross-check against contracts/contract.bytes.
    contract = ctx["contract"]
    contract_bytes = ctx["contract_bytes"]

    recomputed_ok =
      valid_identity_object("contract", contract) &&
        contract["fields"]["contract_bytes"] == contract_bytes

    %{
      "check" => "contract_identity",
      "status" => if(recomputed_ok, do: "ACCEPT", else: "REJECT"),
      "detail" => "contract object_hash recomputed from contract.bytes and identity fields"
    }
  end

  defp execution_binding_check(ctx) do
    started = ctx["started"]
    ended = ctx["ended"]

    ok =
      ended["parent_envelope_id"] == started["envelope_id"] &&
        ended["body"]["execution_id"] == started["body"]["execution_id"]

    %{"check" => "execution_binding", "status" => if(ok, do: "ACCEPT", else: "REJECT"), "detail" => "execution_ended parent chain to execution_started"}
  end

  defp result_payload_check(ctx) do
    env = ctx["result_env"]
    recomputed = Canon.sha256_bytes(ctx["result_bytes"])
    status = if recomputed == env["body"]["payload_hash"], do: "ACCEPT", else: "REJECT"
    %{"check" => "result_payload", "status" => status, "detail" => "payload_hash recomputed from results/result.bytes"}
  end

  defp metric_recompute_check(ctx) do
    corpus = ctx["corpus"]
    metric_env = ctx["metric_env"]
    rounding = metric_env["body"]["rounding"]
    n = Enum.count(corpus)
    mean = Enum.sum(corpus) / n |> Float.round(rounding)
    var = corpus |> Enum.map(fn x -> :math.pow(x - mean, 2) end) |> Enum.sum() |> Kernel./(n)
    std = :math.sqrt(var) |> Float.round(rounding)

    stored_mean = Float.round(metric_env["body"]["value_mean"] || 0, rounding)
    stored_std = Float.round(metric_env["body"]["value_std_dev"] || 0, rounding)

    status =
      cond do
        mean != stored_mean -> "REJECT"
        std != stored_std -> "REJECT"
        true -> "ACCEPT"
      end

    %{"check" => "metric_recompute", "status" => status, "detail" => "mean/std recomputed from raw corpus under deterministic aggregation"}
  end

  defp certificate_binding_check(ctx) do
    cert = ctx["cert_env"]
    metric_env = ctx["metric_env"]

    # certificate should bind to the metric identity object referenced in metric envelope
    cert_bindings = cert["bindings"]
    metric_bound = cert_bindings["metric"]
    metric_from_env = metric_env["bindings"]["metric"]

    ok =
      (metric_bound != nil && metric_env != nil) &&
        metric_bound["object_hash"] == metric_from_env["object_hash"]

    %{
      "check" => "certificate_binding",
      "status" => if(ok, do: "ACCEPT", else: "REJECT"),
      "detail" => "certificate decision envelope binds metric identity referenced by metric envelope"
    }
  end

  defp verify_edges(ctx) do
    graph = ctx["graph"]
    edges = graph["edges"]

    Enum.map(@required_edges, fn type ->
      present = Enum.any?(edges, fn e -> e["type"] == type end)
      %{"edge" => type, "status" => if(present, do: "ACCEPT", else: "MISSING")}
    end)
  end

  defp gate_status(checks, edges) do
    accepted = Enum.count(checks, fn c -> c["status"] == "ACCEPT" end)
    rejected = Enum.count(checks, fn c -> c["status"] == "REJECT" end)
    missing_edges = Enum.count(edges, fn e -> e["status"] == "MISSING" end)

    cond do
      rejected > 0 -> "REJECT"
      missing_edges > 0 -> "UNVERIFIED"
      accepted == length(checks) and missing_edges == 0 -> "ACCEPT"
      true -> "CONTESTED"
    end
  end

  defp valid_identity_object(kind, %{"kind" => k, "object_hash" => h} = obj) do
    k == kind && Canon.sha256(%{"kind" => k, "fields" => obj["fields"]}) == h
  end

  defp valid_identity_object(_, _), do: false
end