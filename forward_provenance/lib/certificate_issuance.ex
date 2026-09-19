defmodule TiannaraOS.Provenance.CertificateIssuance do
  @moduledoc """
  Certificate issuance gate (predicate P-CERTIFICATE-ISSUANCE, Council-authorized).

  Minimal deterministic single-authority issuance boundary: turns an
  already-validated evidence chain (lineage + verified bundle + candidate
  decision envelope evidence) into ONE immutable certificate record UNDER the
  accepted provenance policy (TIA_PROVENANCE_CERTIFICATION_POLICY.yaml, schema
  1.0.0). M7 = HYBRID holds: exactly ONE forward issuance authority issues;
  verification stays a separate, closed predicate.

  Non-negotiable properties:
    * policy-gated  - every issuance_conditions.all_must_hold is represented
                      explicitly; every impossible_case is rejected; missing
                      evidence FAILS CLOSED (no silent invention/weakening).
    * fail-closed   - an invalid, ambiguous, or conflicting request can never
                      mint or mutate a certificate.
    * deterministic - certificate_id is the FROZEN identity re-derived through
                      TiannaraOS.Provenance.CertificateIdentity (P-IDENTITY-
                      CANONICAL). No other hash path exists here.
    * authority-explicit - the single forward issuance authority is resolved
                      from an explicit authority registry; never inferred from
                      host/process/time/order.
    * envelope-bound - issuance emits a decision_recorded envelope under the
                      frozen o2 body contract.
    * immutability  - a certificate record is created once; it is never
                      overwritten, never mutated, never SUPERSEDED/REVOKED by
                      this predicate.
    * atomic        - issuance is all-or-nothing: a record exists in the
                      registry AND the ledger, or no record exists at all.
    * auditable     - each issuance appends one canonical-JSON line to the
                      issuance ledger; replay is recognized (not duplicated);
                      conflict under an existing certificate_id fails closed.

  Lifecycle, revocation, supersession, distributed verification, distributed or
  rotated issuance, and any A01..A12 activation remain CLOSED and are NOT
  reachable from this module.
  """

  alias TiannaraOS.Provenance.{Canon, CertificateIdentity, CertificateAuthorityBridge}

  @issuance_spec "tiannara-fp-cert-v1"
  @issuance_authority "tiannara-fp-forward-issuance-authority-v1"
  @authority_kind "mechanism"
  @policy "tiannara-provenance-certification-policy"
  @policy_version "1.0.0"
  @canon_spec "tiannara-fp-canon-v1"

  @table :tiannaraos_fp_certificate_issuance
  @ledger_env :certificate_issuance_ledger_path

  @allowed_decisions ["certifies", "certifies_bounded", "qualifies_partial"]
  @reproducible_classes ["FULL", "CONDITIONAL", "PARTIAL", "NOT"]
  @epistemic_maturities ["STRUCTURAL", "IMPLEMENTED", "UNIT_VERIFIED", "INTEGRATION_VERIFIED", "RUNTIME_VERIFIED", "EMPIRICALLY_VALIDATED", "LONG_HORIZON_VALIDATED", "UNSPECIFIED"]

  @all_must_hold [
    "evidence_chain_single_execution_terminal_success",
    "execution_id_uniqueness_resolved",
    "source_identity_recorded_recomputable",
    "contract_identity_recorded_recomputable",
    "environment_identity_manifests_complete",
    "result_payload_bound_to_execution",
    "metric_recomputable_or_partial_with_gap",
    "reproducibility_class_declared",
    "canonical_serialization_spec_cited_recomputed",
    "historical_firewall_passes",
    "epistemic_maturity_declared"
  ]

  @impossible_cases [
    "certificate_on_unresolvable_execution_id",
    "certificate_on_hash_only_evidence",
    "certificate_on_partial_or_aborted_execution",
    "certificate_on_metric_without_manifest_or_corpus"
  ]

  @doc "Machine-readable predicate contract."
  def spec do
    %{
      "issuance_spec" => @issuance_spec,
      "authority_model" => "M7-HYBRID single forward issuance authority",
      "authority" => @issuance_authority,
      "authority_kind" => @authority_kind,
      "policy" => @policy,
      "policy_version" => @policy_version,
      "reused_identity" => "TiannaraOS.Provenance.CertificateIdentity (P-IDENTITY-CANONICAL)",
      "canonical_serialization_spec" => @canon_spec,
      "all_must_hold" => @all_must_hold,
      "impossible_cases" => @impossible_cases,
      "epistemic_maturities" => @epistemic_maturities
    }
  end

  @doc "Registry existence + ledger replay (idempotent)."
  def ensure_started(opts \\ []) do
    case :ets.whereis(@table) do
      :undefined ->
        ledger = Keyword.get_lazy(opts, :ledger_path, &default_ledger_path/0)

        try do
          :ets.new(@table, [
            :named_table,
            :set,
            :public,
            {:read_concurrency, true},
            {:write_concurrency, true}
          ])

          :ets.insert(@table, {:__ledger_path, ledger})
          replay_ledger(ledger)
          :ok
        rescue
          ArgumentError ->
            if :ets.whereis(@table) == :undefined,
              do: raise("certificate issuance registry unavailable")

            :ok
        end

      _ ->
        :ok
    end
  end

  @doc """
  Register the single forward issuance authority (M7-HYBRID). First writer wins;
  a competing authority is REJECTED (no distributed/competing issuers).
  `authority` defaults to the configured single forward issuance authority.
  """
  def register_authority(opts \\ []) do
    ensure_started(opts)
    ledger = ledger_path(opts)

    entry = %{
      "authority" => Keyword.get(opts, :authority, @issuance_authority),
      "authority_kind" => Keyword.get(opts, :authority_kind, @authority_kind),
      "policy_ref" => %{"policy" => @policy, "policy_version" => @policy_version}
    }

    case :ets.insert_new(@table, {:__authority, entry}) do
      true ->
        append_ledger(ledger, %{"registry" => "authority", "entry" => entry})
        {:ok, entry}

      false ->
        {:error, :competing_issuer, existing_authority()}
    end
  end

  @doc "Whether `authority` is the registered single forward issuance authority."
  def authorized_issuer?(authority) do
    case registered_authority() do
      nil -> false
      %{"authority" => a} -> a == authority
    end
  end

  @doc """
  Issue ONE certificate. request carries:
    bundle_dir            verified bundle directory (required; bundle is the
                          certification-time evidence, policy evidence_bundle)
    lineage               verified lineage (required; no hash-only evidence)
    authority_header      %{authority, authority_kind, role} (o3)
    policy_ref            %{policy, policy_version, authority_doc, authority_doc_id} (o3)
    decision              one of #{inspect(@allowed_decisions)}
    reason                binary reason (audit)
    environment           %{deps_lock_hash, input_manifest, output_manifest}
    metric_manifest       %{definition_version, computation_hash, aggregation,
                            seed_dependence, corpus_sha256}
    reproducibility_class one of #{inspect(@reproducible_classes)}
    historical_references [] (must be empty; historical firewall)
    epistemic_maturity one of the declared evidence maturity states; this is
      separate from lifecycle state and never inferred from issuance success.

  Returns {:ok, issued} | {:ok, replayed} | {:error, reason, detail}.
  Certificate state changes ONLY on a fully-passing issuance; never otherwise.
  """
  def issue(request, opts \\ []) do
    ensure_started(opts)

    with :ok <- validate_request(request),
         {:ok, id_suite} <- identity(request),
         {:ok, gate} <- policy_gate(request, id_suite),
         :ok <- validate_authority(request),
         :ok <- validate_decision_envelope(request, id_suite) do
      certificate_id = id_suite.certificate_id
      signature = request_signature(request, id_suite)

      case recorded(certificate_id) do
        {:ok, record} ->
          if record["request_signature"] == signature do
            {:ok, Map.merge(record, %{"replayed" => true, "status" => "replayed"})}
          else
            {:error, :duplicate_conflicting, %{certificate_id: certificate_id, existing: record}}
          end

        :unregistered ->
          persist(certificate_id, signature, request, id_suite, gate, opts)
      end
    end
  end

  @doc "Resolve an issued certificate record by its deterministic certificate_id."
  def resolve(certificate_id) do
    case recorded(certificate_id) do
      {:ok, record} -> {:ok, record}
      :unregistered -> {:error, :unregistered}
    end
  end

  @doc "Registry snapshot (issued certificates only)."
  def export do
    if table?() do
      @table
      |> :ets.tab2list()
      |> Enum.reject(fn
        {:__ledger_path, _} -> true
        {:__authority, _} -> true
        _ -> false
      end)
      |> Enum.map(fn {_id, record} -> record end)
      |> Enum.sort_by(fn r -> {r["recorded_at"], r["certificate_id"]} end)
    else
      []
    end
  end

  @doc "Recreate the registry from `ledger_path` (test/restart isolation)."
  def reset(ledger_path) do
    case table?() and :ets.lookup(@table, :__ledger_path) do
      false ->
        :ok

      [{:__ledger_path, ^ledger_path}] ->
        :ets.delete(@table)

      [{:__ledger_path, other}] ->
        raise ArgumentError, "registry belongs to another ledger: #{inspect(other)}"
    end

    ensure_started(ledger_path: ledger_path)
    :ok
  end

  @doc "Re-derive the certificate identity with the VERIFIED P-IDENTITY-CANONICAL implementation."
  def derive_certificate_id(candidate_id_spec, spine) do
    CertificateIdentity.derive(candidate_id_spec, spine)
  end

  # ---------------------------------------------------------------------------
  # Identity: reuse the frozen spine (public bridge candidate) + P-IDENTITY-CANONICAL
  # ---------------------------------------------------------------------------

  defp identity(request) do
    lineage = request["lineage"]
    bundle_id = request["bundle_id"]

    with :ok <- require_verified_bundle(lineage, bundle_id, request["bundle_dir"]),
         {:ok, candidate} <-
           CertificateAuthorityBridge.candidate(lineage, bundle_id, %{
             "requested_transition" => "issue_certificate",
             "actor" => Map.get(request, "actor", "certificate_issuance")
           }) do
      case identity_spine(candidate) do
        {:ok, spine} ->
          case CertificateIdentity.derive("tiannara-fp-cert-candidate-v1", spine) do
            {:ok, certificate_id} ->
              {:ok,
               %{
                 candidate: candidate,
                 spine: spine,
                 certificate_id: certificate_id,
                 lineage_id: lineage && lineage["lineage_id"],
                 bundle_id: bundle_id
               }}

            {:error, reason} ->
              {:error, :identity_invalid, %{reason: reason}}
          end

        {:error, reason} ->
          {:error, :identity_invalid, %{reason: reason}}
      end
    else
      {:error, reason, _ctx} ->
        {:error, {:identity_derivation_failed, reason}, %{}}

      {:error, reason} ->
        {:error, {:identity_derivation_failed, reason}, %{}}
    end
  end

  @doc """
  The frozen identity input (fz-b PIN o1) over the bridge candidate spine.
  `attempt` is a STRING domain in the frozen schema; the bridge candidate emits
  the raw lineage attempt (integer). Normalization is deterministic, pure, and
  idempotent (a string attempt passes through unchanged), so the ONLY
  certificate identity is the verified P-IDENTITY-CANONICAL derivation.
  """
  def identity_spine(candidate) do
    spine =
      candidate
      |> Map.delete("candidate_id")
      |> Map.update("attempt", "1", &to_string/1)

    case CertificateIdentity.validate("tiannara-fp-cert-candidate-v1", spine) do
      :ok -> {:ok, spine}
      {:error, reason} -> {:error, reason}
    end
  end

  defp require_verified_bundle(lineage, bundle_id, bundle_dir) do
    if lineage != nil and is_binary(bundle_id) and bundle_id != "" and File.dir?(bundle_dir) do
      case TiannaraOS.Provenance.MetricLineage.verify_bundle(bundle_dir) do
        %{"bundle_id" => actual} when is_binary(actual) ->
          if actual == bundle_id, do: :ok, else: {:error, :bundle_id_mismatch, %{}}

        _ ->
          {:error, :unverified_bundle, %{}}
      end
    else
      {:error, :missing_bundle_id, %{}}
    end
  end

  # ---------------------------------------------------------------------------
  # Policy gate: all_must_hold explicit + impossible_cases rejected
  # ---------------------------------------------------------------------------

  @doc "Evaluate the accepted policy's issuance conditions against the request."
  def policy_gate(request, _id_suite \\ nil) do
    lineage = request["lineage"]
    execution = lineage && lineage["execution"]
    metric = lineage && lineage["metric"]
    result = lineage && lineage["result"]
    source = lineage && lineage["source"]
    contract = lineage && lineage["contract"]
    environment = request["environment"]
    metric_manifest = request["metric_manifest"]

    suite = %{
      fully_verified: fully_verified?(lineage, request["bundle_dir"]),
      registered: registered_execution?(execution && execution["execution_id"]),
      lineage_present: lineage != nil,
      status: execution && execution["status"],
      source: source,
      contract: contract,
      result: result,
      metric: metric,
      environment: environment,
      metric_manifest: metric_manifest,
      declared_class: request["reproducibility_class"],
      historical: request["historical_references"],
      canon_spec: request["canonical_serialization_spec"]
    }

    must_hold =
      Enum.map(@all_must_hold, fn c -> %{"condition" => c, "status" => must_hold(c, suite)} end)

    impossible =
      Enum.map(@impossible_cases, fn c ->
        %{
          "impossible_case" => c,
          "status" => if(impossible?(c, suite), do: "PRESENT", else: "ABSENT")
        }
      end)

    all_must_hold_pass = Enum.all?(must_hold, &(&1["status"] == "PASS"))
    no_impossible = Enum.all?(impossible, &(&1["status"] == "ABSENT"))

    gate = %{
      "verdict" => if(all_must_hold_pass and no_impossible, do: "ISSUABLE", else: "BLOCKED"),
      "all_pass" => all_must_hold_pass and no_impossible,
      "all_must_hold" => must_hold,
      "impossible_cases" => impossible,
      "block_reasons" => build_block_reasons(must_hold, impossible)
    }

    if gate["all_pass"], do: {:ok, gate}, else: {:error, :policy_blocked, gate}
  end

  defp must_hold("evidence_chain_single_execution_terminal_success", s) do
    cond do
      not s.lineage_present -> "FAIL"
      not s.fully_verified -> "FAIL"
      s.status != "completed" -> "FAIL"
      true -> "PASS"
    end
  end

  defp must_hold("execution_id_uniqueness_resolved", s) do
    if s.registered, do: "PASS", else: "FAIL"
  end

  defp must_hold("source_identity_recorded_recomputable", s) do
    if recomputable_object?(s.source), do: "PASS", else: "FAIL"
  end

  defp must_hold("contract_identity_recorded_recomputable", s) do
    if recomputable_object?(s.contract), do: "PASS", else: "FAIL"
  end

  defp must_hold("environment_identity_manifests_complete", s) do
    case s.environment do
      %{"deps_lock_hash" => lock, "input_manifest" => inp, "output_manifest" => out}
      when is_binary(lock) and is_map(inp) and is_map(out) ->
        if Map.keys(inp) != [] and Map.keys(out) != [], do: "PASS", else: "FAIL"

      _ ->
        "FAIL"
    end
  end

  defp must_hold("result_payload_bound_to_execution", s) do
    case s.result do
      %{"result_id" => rid, "payload_hash" => ph, "execution_id" => eid}
      when is_binary(rid) and is_binary(ph) and is_binary(eid) ->
        "PASS"

      _ ->
        "FAIL"
    end
  end

  defp must_hold("metric_recomputable_or_partial_with_gap", s) do
    if valid_metric_evidence?(s), do: metric_verdict(s), else: "FAIL"
  end

  defp must_hold("reproducibility_class_declared", s) do
    if s.declared_class in @reproducible_classes, do: "PASS", else: "FAIL"
  end

  defp must_hold("canonical_serialization_spec_cited_recomputed", s) do
    if s.canon_spec == @canon_spec, do: "PASS", else: "FAIL"
  end

  defp must_hold("historical_firewall_passes", s) do
    if s.historical in [nil, []], do: "PASS", else: "FAIL"
  end

  defp must_hold(_other, _s), do: "FAIL"

  defp impossible?("certificate_on_unresolvable_execution_id", s), do: not s.registered
  defp impossible?("certificate_on_hash_only_evidence", s), do: not s.lineage_present

  defp impossible?("certificate_on_partial_or_aborted_execution", s),
    do: s.status in ["partial", "aborted"]

  defp impossible?("certificate_on_metric_without_manifest_or_corpus", s),
    do: s.metric == nil or s.metric_manifest == nil

  defp impossible?(_other, _s), do: false

  defp recomputable_object?(%{"kind" => kind, "fields" => fields, "object_hash" => hash})
       when is_binary(kind) and is_map(fields) and is_binary(hash) do
    Canon.sha256(%{"kind" => kind, "fields" => fields}) == hash
  end

  defp recomputable_object?(_), do: false

  defp fully_verified?(lineage, bundle_dir) do
    lineage_ok =
      lineage != nil and
        TiannaraOS.Provenance.MetricLineage.verify_lineage(lineage)["verdict"] in [
          "ACCEPT",
          "NOT CERTIFIABLE"
        ]

    bundle_ok =
      bundle_dir != nil and File.dir?(bundle_dir) and
        TiannaraOS.Provenance.MetricLineage.verify_bundle(bundle_dir)["verdict"] in [
          "ACCEPT",
          "NOT CERTIFIABLE"
        ]

    lineage_ok and bundle_ok
  end

  defp registered_execution?(nil), do: false
  defp registered_execution?(id), do: TiannaraOS.Provenance.IdentityAuthority.registered?(id)

  defp valid_metric_evidence?(s) do
    is_map(s.metric) and is_map(s.metric_manifest) and
      manifest_complete?(s.metric_manifest) and
      is_binary(metric_id(s.metric)) and
      is_binary(s.metric["corpus_sha256"]) and
      s.metric["corpus_sha256"] == s.metric_manifest["corpus_sha256"]
  end

  defp manifest_complete?(m) do
    is_binary(m["definition_version"]) and is_binary(m["computation_hash"]) and
      is_binary(m["aggregation"]) and is_boolean(m["seed_dependence"]) and
      is_binary(m["corpus_sha256"])
  end

  defp metric_verdict(s) do
    if s.fully_verified do
      "PASS"
    else
      if s.declared_class == "PARTIAL" and is_binary(request_gap(s)), do: "PASS", else: "FAIL"
    end
  end

  defp metric_id(%{"metric_id" => %{"object_hash" => h}}) when is_binary(h), do: h
  defp metric_id(%{"metric_id" => h}) when is_binary(h), do: h
  defp metric_id(_), do: nil

  defp request_gap(s), do: (s.declared_class == "PARTIAL" && s.metric_manifest["gap"]) || nil

  defp build_block_reasons(must_hold, impossible) do
    failed = Enum.filter(must_hold, &(&1["status"] == "FAIL")) |> Enum.map(& &1["condition"])

    present =
      Enum.filter(impossible, &(&1["status"] == "PRESENT")) |> Enum.map(& &1["impossible_case"])

    failed ++ present
  end

  # ---------------------------------------------------------------------------
  # Authority boundary (M7-HYBRID single forward issuance authority)
  # ---------------------------------------------------------------------------

  defp validate_authority(request) do
    header = request["authority_header"]
    pr = request["policy_ref"]

    case header do
      %{"authority" => authority, "authority_kind" => kind, "role" => "issuance"}
      when is_binary(authority) and kind in ["human", "mechanism"] ->
        cond do
          not authorized_issuer?(authority) ->
            {:error, :unauthorized_issuer, %{authority: authority}}

          not valid_policy_ref?(pr) ->
            {:error, :invalid_policy_ref, %{}}

          true ->
            :ok
        end

      _ ->
        {:error, :malformed_authority_header, %{}}
    end
  end

  defp valid_policy_ref?(%{
         "policy" => @policy,
         "policy_version" => @policy_version,
         "authority_doc" => doc,
         "authority_doc_id" => doc_id
       })
       when is_binary(doc) and is_binary(doc_id),
       do: true

  defp valid_policy_ref?(_), do: false

  # ---------------------------------------------------------------------------
  # Decision / envelope (o2)
  # ---------------------------------------------------------------------------

  defp validate_decision_envelope(request, id_suite) do
    decision = request["decision"]
    reason = request["reason"]

    cond do
      decision not in @allowed_decisions -> {:error, :invalid_decision, %{decision: decision}}
      not is_binary(reason) or reason == "" -> {:error, :missing_reason, %{}}
      id_suite.certificate_id == nil -> {:error, :identity_not_reached, %{}}
      true -> :ok
    end
  end

  defp request_signature(request, id_suite) do
    Canon.sha256(%{
      "certificate_id" => id_suite.certificate_id,
      "decision" => request["decision"],
      "reason" => request["reason"],
      "authority_header" => request["authority_header"],
      "policy_ref" => request["policy_ref"],
      "issuance_spec" => @issuance_spec,
      "evidence_ids" => %{
        "lineage_id" => id_suite.lineage_id,
        "bundle_id" => id_suite.bundle_id
      }
    })
  end

  # ---------------------------------------------------------------------------
  # Persistence: record + envelope + ledger (atomic)
  # ---------------------------------------------------------------------------

  defp persist(certificate_id, signature, request, id_suite, gate, opts) do
    ledger = ledger_path(opts)

    record = %{
      "certificate_id" => certificate_id,
      "request_signature" => signature,
      "issuance_spec" => @issuance_spec,
      "decision" => request["decision"],
      "reason" => request["reason"],
      "authority_header" => request["authority_header"],
      "policy_ref" => request["policy_ref"],
      "evidence_ids" => %{"lineage_id" => id_suite.lineage_id, "bundle_id" => id_suite.bundle_id},
      "envelope" => build_decision_envelope(request, id_suite),
      "policy_gate" => %{
        "all_must_hold_pass" => gate["all_pass"],
        "impossible_cases" => gate["impossible_cases"]
      },
      "state" => "VALID",
      "epistemic_maturity" => Map.get(request, "epistemic_maturity", "UNSPECIFIED"),
      "recorded_at" => DateTime.utc_now() |> DateTime.to_iso8601()
    }

    case :ets.insert_new(@table, {certificate_id, record}) do
      true ->
        case append_ledger(ledger, record) do
          :ok ->
            {:ok, record}

          {:error, _kind, message} ->
            :ets.delete(@table, certificate_id)
            {:error, :persistence_failure, %{reason: message}}
        end

      false ->
        {:error, :duplicate_conflicting, %{certificate_id: certificate_id}}
    end
  end

  defp build_decision_envelope(request, id_suite) do
    body = %{
      "envelope_spec" => "tiannara-fp-certificate-identity-v1",
      "object_type" => "certificate_decision",
      "decision" => request["decision"],
      "decision_hash" =>
        Canon.sha256(%{
          "decision" => request["decision"],
          "reason" => request["reason"],
          "certificate_id" => id_suite.certificate_id
        }),
      "authority_header" => request["authority_header"],
      "policy_ref" => request["policy_ref"],
      "issued_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "certificate_id" => id_suite.certificate_id,
      "evidence_bindings" => [
        %{"kind" => "lineage", "id" => id_suite.lineage_id},
        %{"kind" => "bundle", "id" => id_suite.bundle_id}
      ]
    }

    TiannaraOS.Provenance.Envelope.build(
      event_type: "decision_recorded",
      producer: "TiannaraOS.Provenance.CertificateIssuance/1.0.0",
      body: body,
      bindings: %{
        "lineage" => id_suite.lineage_id,
        "bundle" => id_suite.bundle_id
      }
    )
  end

  defp validate_request(request) when is_map(request), do: :ok
  defp validate_request(_), do: {:error, :invalid_request, %{}}

  # ---------------------------------------------------------------------------
  # Registry plumbing (mirrors IdentityAuthority persistence conventions)
  # ---------------------------------------------------------------------------

  defp recorded(certificate_id) do
    if table?() do
      case :ets.lookup(@table, certificate_id) do
        [{^certificate_id, record}] -> {:ok, record}
        _ -> :unregistered
      end
    else
      :unregistered
    end
  end

  defp registered_authority do
    if table?() do
      case :ets.lookup(@table, :__authority) do
        [{:__authority, entry}] -> entry
        _ -> nil
      end
    else
      nil
    end
  end

  defp existing_authority, do: registered_authority()

  defp table?, do: :ets.whereis(@table) != :undefined

  defp ledger_path(opts) do
    Keyword.get_lazy(opts, :ledger_path, &default_ledger_path/0)
  end

  defp default_ledger_path do
    case Application.get_env(:forward_provenance, @ledger_env) do
      nil -> Path.expand("data/certificate_issuance_ledger.jsonl")
      path -> Path.expand(path)
    end
  end

  defp append_ledger(path, record) do
    path
    |> Path.dirname()
    |> File.mkdir_p!()

    File.open(path, [:append, :utf8], fn io ->
      :io.put_chars(io, [Canon.canon(record), "\n"])
    end)

    :ok
  rescue
    e -> {:error, :ledger_append_failed, Exception.message(e)}
  end

  defp replay_ledger(path) do
    if File.regular?(path) do
      path
      |> File.stream!([], :line)
      |> Enum.each(fn line ->
        line = String.trim(line)

        if line != "" do
          rec = :json.decode(line)

          case rec do
            %{"registry" => "authority", "entry" => entry} ->
              :ets.insert_new(@table, {:__authority, entry})

            %{"certificate_id" => cid} = record ->
              :ets.insert_new(@table, {cid, record})
          end
        end
      end)
    end
  rescue
    _ -> :ok
  end
end
