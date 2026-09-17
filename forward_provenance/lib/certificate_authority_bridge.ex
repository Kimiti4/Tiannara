defmodule TiannaraOS.Provenance.CertificateAuthorityBridge do
  @moduledoc """
  Certificate State / Authority bridge (Stage 6).

  Turns *verified forward-provenance evidence* (a Stage-5 lineage + its
  evidence bundle) into a deterministic *certificate candidate*, then evaluates
  the candidate against the existing certificate machinery WITHOUT creating,
  replacing, or bypassing an authority.

  The discovered authoring-area authority (TiannaraOS.Provenance.Certificate)
  is a PURE, STATELESS identity/envelope generator: it has NO certificate
  ledger, NO lifecycle, NO revocation, NO supersession rules, NO decision
  policy, and NO Council/constitutional gate. Per the Council gate (§17) any
  authority rule that does not exist is marked UNKNOWN/BLOCKED and certification
  is prevented until the ambiguity is resolved. This module makes that boundary
  machine-visible: `authorized_issuance?` is structurally `false` while any
  authority predicate is undefined, so the bridge PROVABLY cannot mint a
  certificate. When every predicate is later defined and passing, the existing
  Certificate.issue/1 path remains the single issuance entry point.

  The layers never collapse:
  PROVENANCE_VERIFIED /= CERTIFICATE_CANDIDATE /= CERTIFICATE_AUTHORIZED /=
  CERTIFICATE_ACTIVE /= CERTIFICATE_REVOKED.
  """

  alias TiannaraOS.Provenance.{Canon, IdentityAuthority, MetricLineage, RuntimeContract}

  @bridge_spec "tiannara-fp-certificate-authority-bridge-v1"
  @candidate_spec "tiannara-fp-cert-candidate-v1"
  @existing_issuer "TiannaraOS.Provenance.Certificate.issue/1"
  @existing_issuance_spec "tiannara-fp-cert-v1"

  @verdicts ["CERTIFIED", "CERTIFIED_BOUNDED", "QUALIFIED_PARTIAL", "NOT_CERTIFIED", "UNKNOWN", "BLOCKED"]

  @doc "Normative identity of the Stage-6 bridge contract."
  def spec do
    %{
      "spec_name" => @bridge_spec,
      "version" => "1.0.0",
      "area" => "forward_provenance only",
      "stage" => 6,
      "boundary" => "provenance_verified /= certificate_candidate /= certificate_authorized /= certificate_active /= certificate_revoked",
      "issuer" => @existing_issuer,
      "issuance_spec" => @existing_issuance_spec,
      "invariant" => "evidence can propose certificate state; only the existing certificate authority can establish authoritative certificate state",
      "default_decision" => "BLOCKED",
      "verdicts" => @verdicts
    }
  end

  @doc """
  Bounded authority map (A01..A12) recovered by Stage-6 reconnaissance.

  Each entry carries path, symbol, current_behavior, authority_level,
  input_contract, output_contract, mutation_capability, persistence_behavior,
  verification_behavior, evidence, and an allowed status
  (CERTIFIED | CERTIFIED_BOUNDED | QUALIFIED_PARTIAL | NOT_CERTIFIED |
   UNKNOWN | BLOCKED). Nothing is inferred CERTIFIED from the absence of an
   error.
  """
  def authority_map do
    [
      %{
        "code" => "A01", "label" => "Certificate Authority",
        "path" => "forward_provenance/lib/certificate.ex", "symbol" => "TiannaraOS.Provenance.Certificate.issue/1",
        "current_behavior" => "pure stateless identity/envelope generator; decision vocabulary is comment-only and unvalidated; authority is a passthrough string",
        "authority_level" => "identity generator; decision policy ABSENT",
        "input_contract" => "decision, reason, authority, evidence, options",
        "output_contract" => "certificate_id, decision, authority, envelope, evidence_bindings, certificate_hash",
        "mutation_capability" => "none (creates a new envelope only; cannot overwrite or revoke)",
        "persistence_behavior" => "none of its own; envelope embedded in bundle at certificates/decision_recorded.json",
        "verification_behavior" => "Verifier checks binding + edge presence only; never evaluates decision/authority",
        "evidence" => "lib/certificate.ex", "status" => "QUALIFIED_PARTIAL"
      },
      %{
        "code" => "A02", "label" => "Certificate State",
        "path" => "bundle certificates/decision_recorded.json", "symbol" => "immutable decision envelope per bundle",
        "current_behavior" => "one immutable envelope per bundle; NO ledger/registry, NO lifecycle, NO state transitions",
        "authority_level" => "envelope only; state semantics UNDEFINED",
        "input_contract" => "bundled decision_recorded envelope",
        "output_contract" => "certificates/decision_recorded.json",
        "mutation_capability" => "none",
        "persistence_behavior" => "bundle-embedded; no durable certificate ledger",
        "verification_behavior" => "Verifier binding check + edge presence",
        "evidence" => "exhaustive grep: certificate_state/ledger -> no matches", "status" => "NOT_CERTIFIED"
      },
      %{
        "code" => "A03", "label" => "Certificate identity",
        "path" => "lib/certificate.ex", "symbol" => "certificate_id + envelope payload_hash",
        "current_behavior" => "envelope payload_hash deterministic; certificate_id = cert_<>hex(uuid) NON-deterministic",
        "authority_level" => "content identity defined; issuing identity non-deterministic",
        "input_contract" => "decision envelope fields",
        "output_contract" => "certificate_id, certificate_hash (= envelope payload_hash)",
        "mutation_capability" => "none",
        "persistence_behavior" => "embedded in bundle",
        "verification_behavior" => "payload_hash recomputable",
        "evidence" => "lib/certificate.ex:26,51", "status" => "QUALIFIED_PARTIAL"
      },
      %{
        "code" => "A04", "label" => "Certificate lifecycle/status",
        "path" => "lib/certificate.ex comment only", "symbol" => "\"certified\" | \"failed\" | \"contested\"",
        "current_behavior" => "comment-only vocabulary; unvalidated passthrough; no lifecycle states exist",
        "authority_level" => "UNDEFINED",
        "input_contract" => "any decision string",
        "output_contract" => "verbatim passthrough",
        "mutation_capability" => "none",
        "persistence_behavior" => "none",
        "verification_behavior" => "never evaluated",
        "evidence" => "lib/certificate.ex:19 (comment); no enum/guard", "status" => "NOT_CERTIFIED"
      },
      %{
        "code" => "A05", "label" => "Authority validation",
        "path" => "lib/verifier.ex certificate_binding_check", "symbol" => "Verifier.verify/1",
        "current_behavior" => "only checks certificate envelope binds the metric identity and edge presence; no authority decision",
        "authority_level" => "evidence integrity only; decision validation ABSENT",
        "input_contract" => "bundled certificate envelope + metric envelope",
        "output_contract" => "check ACCEPT/REJECT",
        "mutation_capability" => "none",
        "persistence_behavior" => "none",
        "verification_behavior" => "binding object_hash equality + edge presence",
        "evidence" => "lib/verifier.ex:227-245,247-255", "status" => "NOT_CERTIFIED"
      },
      %{
        "code" => "A06", "label" => "Persistence",
        "path" => "lib/bundle.ex; data/identity_authority_ledger.jsonl", "symbol" => "bundle embed; authority ledger (execution-id only)",
        "current_behavior" => "certificates persist only inside an evidence bundle; the identity-authority ledger records executions only",
        "authority_level" => "QUALIFIED (bundle path established)",
        "input_contract" => "certificate envelope -> certificates/decision_recorded.json",
        "output_contract" => "bundle file",
        "mutation_capability" => "file write on export",
        "persistence_behavior" => "bundle-scoped, not a durable cert registry",
        "verification_behavior" => "manifest hash verification",
        "evidence" => "lib/bundle.ex:50,66", "status" => "QUALIFIED_PARTIAL"
      },
      %{
        "code" => "A07", "label" => "Revocation/invalidation",
        "path" => "none in authoring area", "symbol" => "none",
        "current_behavior" => "no revocation vocabulary or mechanism exists",
        "authority_level" => "UNDEFINED",
        "input_contract" => "n/a", "output_contract" => "n/a",
        "mutation_capability" => "none (nothing to revoke)",
        "persistence_behavior" => "none",
        "verification_behavior" => "none",
        "evidence" => "grep revoke/revoked -> no matches in forward_provenance", "status" => "BLOCKED"
      },
      %{
        "code" => "A08", "label" => "Council/constitutional gate",
        "path" => "contract metadata only", "symbol" => "none in code",
        "current_behavior" => "Council authorization appears as declarative metadata; no runtime gate exists in the authoring-area certificate path",
        "authority_level" => "UNDEFINED",
        "input_contract" => "certificate decision",
        "output_contract" => "none enforced",
        "mutation_capability" => "none",
        "persistence_behavior" => "none",
        "verification_behavior" => "none",
        "evidence" => "contracts/forward_provenance_contract.yaml:6 (metadata only)", "status" => "BLOCKED"
      },
      %{
        "code" => "A09", "label" => "Existing certificate consumers",
        "path" => "scripts/verify_demo.exs, test/adversarial_test.exs, lib/verifier.ex; root Omega.DeploymentGateway (OUT of scope)", "symbol" => "Verifier + scripts/tests",
        "current_behavior" => "consumers read the bundled certificate envelope and verify binding; root consumers gated on verdict :certified",
        "authority_level" => "read-only consumers",
        "input_contract" => "bundle certificates/decision_recorded.json",
        "output_contract" => "ACCEPT/REJECT/UNVERIFIED",
        "mutation_capability" => "none",
        "persistence_behavior" => "none",
        "verification_behavior" => "binding check + edge presence",
        "evidence" => "lib/verifier.ex; test/adversarial_test.exs:45-112", "status" => "QUALIFIED_PARTIAL"
      },
      %{
        "code" => "A10", "label" => "Existing certificate verification",
        "path" => "lib/verifier.ex", "symbol" => "Verifier.verify/1",
        "current_behavior" => "certificate envelope payload lies within a manifest-verified bundle; binding + required edge checked; decision/authority never assessed",
        "authority_level" => "integrity/binding only",
        "input_contract" => "bundle directory",
        "output_contract" => "status ACCEPT/REJECT/UNVERIFIED/CONTESTED",
        "mutation_capability" => "none",
        "persistence_behavior" => "none",
        "verification_behavior" => "manifest hashes + recompute + edge presence",
        "evidence" => "lib/verifier.ex:29-42", "status" => "QUALIFIED_PARTIAL"
      },
      %{
        "code" => "A11", "label" => "Existing provenance consumers",
        "path" => "lib/metric_lineage.ex verify_bundle/1; scripts", "symbol" => "MetricLineage.verify_bundle",
        "current_behavior" => "bundle verify recomputes lineage/result/metric/value from bytes; Stage-5 bundles carry NO certificate",
        "authority_level" => "evidence consumers",
        "input_contract" => "bundle directory",
        "output_contract" => "verdict ACCEPT/NOT CERTIFIABLE/UNVERIFIED/REJECT",
        "mutation_capability" => "none",
        "persistence_behavior" => "none",
        "verification_behavior" => "independent recompute",
        "evidence" => "lib/metric_lineage.ex:639-658", "status" => "QUALIFIED_PARTIAL"
      },
      %{
        "code" => "A12", "label" => "Existing audit/evidence records",
        "path" => "data/identity_authority_ledger.jsonl; bundle envelopes", "symbol" => "append-only authority ledger (execution-id); bundle audit_trail.md",
        "current_behavior" => "execution records are ledgered append-only; evidence bundles are self-auditing; there is NO certificate-level audit store",
        "authority_level" => "execution audit only",
        "input_contract" => "execution records",
        "output_contract" => "authority ledger events; bundle audit_trail.md",
        "mutation_capability" => "append-only ledger",
        "persistence_behavior" => "jsonl ledger + bundle artifacts",
        "verification_behavior" => "ledger replay; manifest hashes",
        "evidence" => "lib/identity_authority.ex; lib/metric_lineage.ex audit_trail", "status" => "NOT_CERTIFIED"
      }
    ]
  end

  @doc """
  Recovered certificate lifecycle as a state-transition table.

  The existing authority defines exactly one transition (identity envelope
  issuance); every lifecycle transition (active/revoked/superseded) is
  UNDEFINED and therefore BLOCKED.
  """
  def lifecycle_table do
    [
      %{
        "current" => "none (no certificate exists in the evidence bundle)",
        "event" => "certificate issue (candidate accepted)",
        "required_evidence" => "validated identity bindings (source/contract/execution/result/metric/lineage/bundle)",
        "authority" => "TiannaraOS.Provenance.Certificate.issue/1 (stateless; decision policy ABSENT)",
        "next" => "certificates/decision_recorded.json envelope",
        "allowed" => "identity/binding issuance only when authority predicates are defined AND passing; BLOCKED otherwise"
      },
      %{
        "current" => "certificate (envelope)",
        "event" => "revoke | supersede | expire | activate",
        "required_evidence" => "UNDEFINED (no such rule exists)",
        "authority" => "UNDEFINED",
        "next" => "UNDEFINED",
        "allowed" => "false (BLOCKED until the existing authority defines the rule)"
      }
    ]
  end

  @doc """
  Deterministic certificate candidate derived from a Stage-5 lineage.

  candidate(lineage, bundle_id) or candidate(lineage, bundle_id,
  authority_context). Identical (lineage, bundle_id, authority_context) always
  produce the identical candidate_id; different execution attempts remain
  distinguishable. Returns {:ok, candidate} or {:error, reason, ctx}.
  """
  def candidate(lineage, bundle_id, authority_context \\ %{}) do
    with {:ok, spine} <- candidate_spine(lineage, bundle_id, authority_context) do
      candidate_id = Canon.sha256(%{"candidate_id_spec" => @candidate_spec, "spine" => spine})
      {:ok, Map.put(spine, "candidate_id", candidate_id)}
    end
  end

  defp candidate_spine(nil, _bundle_id, _ctx), do: {:error, :missing_provenance, %{}}

  defp candidate_spine(lineage, bundle_id, authority_context) do
    with :ok <- require_lineage(lineage),
         :ok <- require_string(bundle_id, :missing_bundle_id) do
      execution = lineage["execution"]
      result = lineage["result"]
      metric = lineage["metric"]
      definition = lineage["metric_definition"]

      spine = %{
        "candidate_spec" => @candidate_spec,
        "source_id" => id_of(lineage["source"]),
        "contract_id" => id_of(lineage["contract"]),
        "execution_id" => execution["execution_id"],
        "attempt" => execution["attempt"],
        "status" => execution["status"],
        "certifiable_terminal" => RuntimeContract.certifiable?(execution["status"]),
        "result_id" => result["result_id"],
        "result_payload_hash" => result["payload_hash"],
        "definition_id" => id_of(definition),
        "metric_id" => id_of(metric["metric_id"]),
        "corpus_sha256" => metric["corpus_sha256"],
        "value" => lineage["value"],
        "lineage_id" => lineage["lineage_id"],
        "bundle_id" => bundle_id,
        "authority_context" => authority_context
      }

      {:ok, spine}
    end
  end

  @doc """
  Stage-6 precondition gate: 13 checks (PC-01..PC-13). A FAIL is a typed
  rejection; missing evidence is never converted into a default. Returns
  %{"checks" => [...], "all_pass" => bool}.
  """
  def preconditions(lineage, candidate, bundle_dir \\ nil) do
    execution = lineage["execution"]
    result = lineage["result"]
    metric = lineage["metric"]
    bundle_result = bundle_result(bundle_dir)

    checks = [
      pc_check("PC-01", "source_present", "SOURCE exists", lineage["source"] != nil, :missing_source),
      pc_check("PC-02", "contract_present", "CONTRACT exists", lineage["contract"] != nil, :missing_contract),
      pc_check("PC-03", "execution_present", "EXECUTION exists", execution != nil, :missing_provenance),
      pc_check("PC-04", "execution_registered", "EXECUTION is registered",
        registered_execution?(execution && execution["execution_id"]), :missing_execution),
      pc_check("PC-05", "execution_completed", "EXECUTION completed",
        execution != nil && RuntimeContract.certifiable?(execution["status"]), :incomplete_execution),
      pc_check("PC-06", "result_present", "RESULT exists",
        result != nil && is_binary(result["result_id"]) && is_binary(result["payload_hash"]), :missing_result),
      pc_check("PC-07", "result_matches_execution", "RESULT matches execution",
        execution != nil && result != nil && result["execution_id"] == execution["execution_id"], :invalid_lineage),
      pc_check("PC-08", "metric_present", "METRIC exists",
        metric != nil && metric["metric_id"] != nil, :missing_metric),
      pc_check("PC-09", "metric_matches_result", "METRIC matches result",
        result != nil && metric != nil && metric["result_id"] == result["result_id"], :metric_result_mismatch),
      pc_check("PC-10", "lineage_verifies", "LINEAGE verifies",
        lineage_valid?(lineage), :invalid_lineage),
      pc_check("PC-11", "bundle_verifies", "BUNDLE verifies",
        bundle_result != nil && bundle_result["verdict"] == "ACCEPT", :unverified_bundle),
      pc_check("PC-12", "bundle_untampered", "BUNDLE is untampered",
        bundle_result != nil && bundle_result["verdict"] == "ACCEPT", :unverified_bundle),
      pc_check("PC-13", "candidate_deterministic", "candidate identity is deterministic",
        candidate_deterministic?(candidate), :candidate_identity_mismatch)
    ]

    %{"checks" => checks, "all_pass" => Enum.all?(checks, &(&1["status"] == "PASS"))}
  end

  @doc """
  Authority validation: the ten authority predicates (AV-01..AV-10).
  Predicates the existing authority does NOT define are BLOCKED with a typed
  reason, and that alone prevents certification. Returns
  %{"checks" => [...], "verdict" => "PASS" | "BLOCKED", "blocked" => [...],
    "blocked_predicates" => [...]}.
  """
  def authority_validation(evidence, _candidate) do
    lineage = evidence["lineage"]
    bundle_dir = evidence["bundle_dir"]

    checks = [
      %{
        "av" => "AV-01", "predicate" => "candidate_validity",
        "status" => "PASS", "detail" => "candidate well-formed",
        "defined" => true
      },
      %{
        "av" => "AV-02", "predicate" => "lineage_validity",
        "status" => if(lineage_valid?(lineage), do: "PASS", else: "FAIL"),
        "detail" => "lineage is valid (ACCEPT or NOT CERTIFIABLE)", "defined" => true
      },
      %{
        "av" => "AV-03", "predicate" => "certificate_uniqueness",
        "status" => if(certificate_in_bundle?(bundle_dir), do: "BLOCKED", else: "PASS"),
        "detail" => "one immutable decision envelope per bundle; existing certificate present -> conflict, no silent overwrite",
        "defined" => if(bundle_dir, do: true, else: false)
      },
      %{
        "av" => "AV-04", "predicate" => "authority_eligibility",
        "status" => "BLOCKED", "detail" => "who may be certified / authority decision policy does not exist in the existing authority",
        "defined" => false
      },
      %{
        "av" => "AV-05", "predicate" => "state_transition_legality",
        "status" => "BLOCKED", "detail" => "certificate state transitions (candidate->active->revoked) are undefined; only an immutable envelope exists",
        "defined" => false
      },
      %{
        "av" => "AV-06", "predicate" => "existing_certificate_conflict",
        "status" => if(certificate_in_bundle?(bundle_dir), do: "BLOCKED", else: "PASS"),
        "detail" => "no certificate present or explicit conflict block", "defined" => true
      },
      %{
        "av" => "AV-07", "predicate" => "revocation_conflict",
        "status" => "BLOCKED", "detail" => "revocation semantics are undefined in the existing authority",
        "defined" => false
      },
      %{
        "av" => "AV-08", "predicate" => "supersession_rules",
        "status" => "BLOCKED", "detail" => "supersession rules are undefined in the existing authority",
        "defined" => false
      },
      %{
        "av" => "AV-09", "predicate" => "authorization_requirements",
        "status" => "BLOCKED", "detail" => "Council/constitutional authorization gate not present in the authoring-area authority",
        "defined" => false
      },
      %{
        "av" => "AV-10", "predicate" => "constitutional_council_requirements",
        "status" => "BLOCKED", "detail" => "constitutional/Council requirements not present in the authoring-area authority",
        "defined" => false
      }
    ]

    blocked = Enum.filter(checks, &(&1["status"] == "BLOCKED"))
    failed = Enum.filter(checks, &(&1["status"] == "FAIL"))
    verdict = if blocked == [] and failed == [], do: "PASS", else: "BLOCKED"

    %{
      "checks" => checks,
      "verdict" => verdict,
      "blocked" => blocked,
      "blocked_predicates" => Enum.map(blocked, & &1["predicate"])
    }
  end

  @doc """
  Full Stage-6 evaluation of a lineage + evidence bundle. PURE and
  deterministic: identical inputs -> identical verdict, block_reasons,
  candidate_id, and audit_identity. verdict uses the vocabulary
  CERTIFIED | CERTIFIED_BOUNDED | QUALIFIED_PARTIAL | NOT_CERTIFIED | UNKNOWN
  | BLOCKED. `certificate_issuable` is "NO_AUTHORITY_POLICY" while any
  authority predicate is undefined (this stage's discovered state).
  """
  def evaluate(lineage, bundle_dir, authority_context \\ %{}) do
    bundle_result = bundle_result(bundle_dir)

    if bundle_dir != nil and (bundle_result == nil or bundle_result["verdict"] not in ["ACCEPT", "NOT CERTIFIABLE"]) do
      unverified_decision(lineage, bundle_result, authority_context)
    else
      bundle_id = bundle_result && bundle_result["bundle_id"]

      with {:ok, candidate} <- candidate(lineage, bundle_id, authority_context) do
      pre = preconditions(lineage, candidate, bundle_dir)
      authority = authority_validation(%{"lineage" => lineage, "bundle_dir" => bundle_dir}, candidate)

      {verdict, issuable, reasons} = decide(pre, authority, lineage)

      before_state = if certificate_in_bundle?(bundle_dir), do: "certificate_present", else: "no_certificate_in_bundle"

      audit = %{
        "evidence_ids" => %{
          "lineage_id" => lineage["lineage_id"],
          "bundle_id" => bundle_id,
          "candidate_id" => candidate["candidate_id"]
        },
        "rules_applied" => %{"preconditions_all_pass" => pre["all_pass"], "authority_verdict" => authority["verdict"]},
        "decision" => verdict,
        "before_state" => before_state,
        "after_state" => "no_certificate_created",
        "reasons" => stringify_reasons(reasons),
        "requested_transition" => Map.get(authority_context, "requested_transition"),
        "actor" => Map.get(authority_context, "actor")
      }

      audit_identity = Canon.sha256(audit)

      %{
        "candidate" => candidate,
        "candidate_id" => candidate["candidate_id"],
        "verdict" => verdict,
        "authorized_issuance?" => issuable == "YES",
        "blocked?" => verdict not in ["CERTIFIED", "CERTIFIED_BOUNDED"],
        "block_reasons" => reasons,
        "certificate_issuable" => issuable,
        "preconditions" => pre,
        "authority" => authority,
        "evidence_ids" => %{"lineage_id" => lineage["lineage_id"], "bundle_id" => bundle_id},
        "audit" => audit,
        "audit_identity" => audit_identity
      }
    else
      {:error, reason, _ctx} ->
        %{
          "candidate" => nil,
          "candidate_id" => nil,
          "verdict" => verdict_for_error(reason),
          "authorized_issuance?" => false,
          "blocked?" => true,
          "block_reasons" => [reason],
          "certificate_issuable" => "NO_EVIDENCE",
          "preconditions" => %{"checks" => [], "all_pass" => false},
          "authority" => %{"checks" => [], "verdict" => "BLOCKED", "blocked" => [], "blocked_predicates" => []},
          "evidence_ids" => %{"lineage_id" => lineage && lineage["lineage_id"], "bundle_id" => nil},
          "audit" => %{
            "evidence_ids" => %{"lineage_id" => lineage && lineage["lineage_id"], "bundle_id" => nil, "candidate_id" => nil},
            "rules_applied" => %{},
            "decision" => "UNKNOWN",
            "before_state" => "no_certificate_in_bundle",
            "after_state" => "no_certificate_created",
            "reasons" => [to_string(reason)],
            "requested_transition" => Map.get(authority_context, "requested_transition"),
            "actor" => Map.get(authority_context, "actor")
          },
          "audit_identity" => Canon.sha256(%{"reason" => to_string(reason), "actor" => Map.get(authority_context, "actor")})
        }
    end
    end
  end

  defp unverified_decision(lineage, bundle_result, authority_context) do
    %{
      "candidate" => nil,
      "candidate_id" => nil,
      "verdict" => "NOT_CERTIFIED",
      "authorized_issuance?" => false,
      "blocked?" => true,
      "block_reasons" => [:unverified_bundle],
      "certificate_issuable" => "NO_EVIDENCE",
      "preconditions" => %{"checks" => [], "all_pass" => false},
      "authority" => %{"checks" => [], "verdict" => "BLOCKED", "blocked" => [], "blocked_predicates" => []},
      "evidence_ids" => %{
        "lineage_id" => lineage && lineage["lineage_id"],
        "bundle_id" => bundle_result && bundle_result["bundle_id"]
      },
      "audit" => %{
        "evidence_ids" => %{
          "lineage_id" => lineage && lineage["lineage_id"],
          "bundle_id" => bundle_result && bundle_result["bundle_id"],
          "candidate_id" => nil
        },
        "rules_applied" => %{"bundle_verdict" => bundle_result && bundle_result["verdict"]},
        "decision" => "NOT_CERTIFIED",
        "before_state" => "bundle_unverified",
        "after_state" => "no_certificate_created",
        "reasons" => ["unverified_bundle"],
        "requested_transition" => Map.get(authority_context, "requested_transition"),
        "actor" => Map.get(authority_context, "actor")
      },
      "audit_identity" => Canon.sha256(%{
        "reason" => "unverified_bundle",
        "lineage_id" => lineage && lineage["lineage_id"],
        "actor" => Map.get(authority_context, "actor")
      })
    }
  end

  @doc """
  State transition is SAFE-BLOCKED. While `authorized_issuance?` is false (the
  discovered authority state), transition/3 returns {:blocked, decision} and can
  never create a certificate. Only when every authority predicate is defined
  and passing would the existing Certificate.issue/1 path be the issuance
  entry point (documented here, unreachable in this stage's discovered state).
  """
  def transition(lineage, bundle_dir, authority_context \\ %{}) do
    decision = evaluate(lineage, bundle_dir, authority_context)

    if decision["authorized_issuance?"] do
      candidate = decision["candidate"]
      {:issued, issue_via_existing_authority(candidate, decision)}
    else
      {:blocked, decision}
    end
  end

  defp issue_via_existing_authority(candidate, decision) do
    bindings = %{
      "source" => %{"object_hash" => candidate["source_id"]},
      "contract" => %{"object_hash" => candidate["contract_id"]},
      "execution" => %{"object_hash" => Canon.sha256(%{"execution_id" => candidate["execution_id"]})},
      "result" => %{"object_hash" => Canon.sha256(%{"result_id" => candidate["result_id"]})},
      "metric" => %{"object_hash" => candidate["metric_id"]},
      "lineage" => %{"object_hash" => Canon.sha256(%{"lineage_id" => candidate["lineage_id"]})}
    }

    %{
      "candidate_id" => candidate["candidate_id"],
      "evidence_bindings" => bindings,
      "authority_decision" => decision["verdict"],
      "issuer" => @existing_issuer,
      "issuance_spec" => @existing_issuance_spec
    }
  end

  defp decide(pre, authority, _lineage) do
    cond do
      not pre["all_pass"] ->
        failing = pre["checks"] |> Enum.filter(&(&1["status"] == "FAIL")) |> Enum.map(& &1["reason"])
        only_source_contract_nil? = failing -- [:missing_source, :missing_contract] == [] and failing != []
        verdict = if only_source_contract_nil?, do: "QUALIFIED_PARTIAL", else: "NOT_CERTIFIED"
        {verdict, "NO_PRECONDITIONS", failing}

      authority["verdict"] != "PASS" ->
        reasons = Enum.map(authority["blocked"], & :"authority_undefined_#{&1["predicate"]}") ++
                  Enum.map(authority["blocked"], fn _ -> :authority_rejected end) ++
                  blocked_reasons(authority)
        {"BLOCKED", "NO_AUTHORITY_POLICY", Enum.uniq(reasons)}

      true ->
        {"CERTIFIED", "YES", []}
    end
  end

  defp blocked_reasons(authority) do
    Enum.flat_map(authority["blocked"], fn check ->
      case check["predicate"] do
        "authorization_requirements" -> [:authorization_required]
        "constitutional_council_requirements" -> [:constitutional_block]
        "revocation_conflict" -> [:revoked_certificate]
        "supersession_rules" -> [:stale_state]
        "state_transition_legality" -> [:illegal_transition]
        "authority_eligibility" -> [:authority_rejected]
        "certificate_uniqueness" -> [:certificate_conflict, :duplicate_certificate]
        _ -> []
      end
    end)
  end

  defp pc_check(id, name, description, pass, fail_reason) do
    %{
      "check_id" => id,
      "check" => name,
      "description" => description,
      "status" => if(pass, do: "PASS", else: "FAIL"),
      "reason" => if(pass, do: nil, else: fail_reason)
    }
  end
defp lineage_valid?(nil), do: false

  defp lineage_valid?(lineage) do
    MetricLineage.verify_lineage(lineage)["verdict"] in ["ACCEPT", "NOT CERTIFIABLE"]
  end

  defp stringify_reasons(reasons) do
    Enum.map(reasons, &to_string/1)
  end

  defp registered_execution?(nil), do: false
  defp registered_execution?(execution_id) do
    match?({:ok, _}, IdentityAuthority.resolve(execution_id))
  end

  defp candidate_deterministic?(nil), do: false
  defp candidate_deterministic?(candidate) do
    spine = Map.delete(candidate, "candidate_id")
    Canon.sha256(%{"candidate_id_spec" => @candidate_spec, "spine" => spine}) == candidate["candidate_id"]
  end

  defp bundle_result(nil), do: nil
  defp bundle_result(dir) do
    if File.dir?(dir), do: MetricLineage.verify_bundle(dir), else: nil
  end

  defp certificate_in_bundle?(nil), do: false
  defp certificate_in_bundle?(dir) do
    File.exists?(Path.join(dir, "certificates/decision_recorded.json"))
  end

  defp require_lineage(lineage) do
    if is_map(lineage) and lineage["lineage_id"] != nil and lineage["result"] != nil and
         lineage["metric"] != nil and lineage["execution"] != nil,
       do: :ok,
       else: {:error, :invalid_lineage, %{"lineage_id" => lineage && lineage["lineage_id"]}}
  end

  defp require_string(nil, reason), do: {:error, reason, %{}}
  defp require_string(value, _reason) when is_binary(value), do: :ok
  defp require_string(_value, reason), do: {:error, reason, %{}}

  defp id_of(nil), do: nil
  defp id_of(%{"object_hash" => hash}) when is_binary(hash), do: hash
  defp id_of(term), do: Canon.sha256(Canon.canon(term))

  defp verdict_for_error(:missing_provenance), do: "UNKNOWN"
  defp verdict_for_error(_), do: "NOT_CERTIFIED"
end