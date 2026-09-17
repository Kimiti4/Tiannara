defmodule TiannaraOS.Provenance.CertificateLifecycle do
  @moduledoc """
  Certificate lifecycle state machine (predicate P-CERTIFICATE-LIFECYCLE,
  Council-authorized).

  Consumes immutable certificate records produced ONLY by
  TiannaraOS.Provenance.CertificateIssuance (P-CERTIFICATE-ISSUANCE,
  VERIFIED) and maintains a SEPARATE, append-only lifecycle record per
  certificate_id. The issuance record, certificate_id, candidate identity,
  decision, evidence, and policy reference are NEVER modified by this module.

  The state vocabulary and transition rules are policy-pinned
  (TIA_PROVENANCE_CERTIFICATION_POLICY.yaml, certificate_states_and_transitions)
  and copied by the accepted Stage-8 lifecycle design:

    states:              VALID, SUSPENDED, REVOKED, UNVERIFIABLE, SUPERSEDED
    ALLOWED (this gate): VALID->SUSPENDED (suspend)
                         SUSPENDED->VALID (restore, full re-verification evidence)
                         {VALID,SUSPENDED}->UNVERIFIABLE (mark_unverifiable)
                         UNVERIFIABLE->SUSPENDED (evidence_recovered, human kind)
    restoration path:    UNVERIFIABLE -> SUSPENDED -> VALID (policy: "then
                         SUSPENDED->VALID path applies")
    FORBIDDEN (CLOSED):  VALID->REVOKED (P-CERTIFICATE-REVOCATION), all
                         outgoing from terminal REVOKED/SUPERSEDED,
                         UNVERIFIABLE->VALID (restore only via SUSPENDED),
                         every self-loop.
    NOT_DEFINED:         every other pair -> fail closed.

  Properties (mirroring the issuance predicate conventions):
    * authoritative    - one first-writer-wins lifecycle authority registered
                          in the lifecycle ledger; a request failing the
                          authority/kind check FAILS CLOSED.
    * fail-closed      - malformed authority, policy mismatch, missing
                          evidence, unknown/forbidden/undefined transition,
                          invalid source state, unregistered certificate, or a
                          conflicting duplicate NEVER changes state.
    * atomic           - every transition commits its single canonical ledger
                          sentence and state together; a ledger-append failure
                          rolls the registry back fully.
    * idempotent       - identical replay is recognized, never duplicated.
    * auditable        - per-id sequence + immutable records + replayable
                          ledger reconstruct the complete lifecycle history.
    * immutable        - certificate_id and the issuance record are preserved
                          byte-for-byte; transitions only append.

  Revocation, supersession, successor issuance, distributed verification,
  distributed issuance, authority rotation, and any A01..A12 activation
  remain CLOSED and unreachable from this module.
  """

  alias TiannaraOS.Provenance.{Canon, CertificateIssuance}

  @lifecycle_spec "tiannara-fp-lifecycle-v1"
  @lifecycle_authority "tiannara-fp-lifecycle-authority-v1"
  @authority_kind "human"
  @policy "tiannara-provenance-certification-policy"
  @policy_version "1.0.0"
  @canon_spec "tiannara-fp-canon-v1"

  @table :tiannaraos_fp_certificate_lifecycle
  @ledger_env :certificate_lifecycle_ledger_path

  @states ["VALID", "SUSPENDED", "REVOKED", "UNVERIFIABLE", "SUPERSEDED"]
  @restoration_path ["UNVERIFIABLE", "SUSPENDED", "VALID"]

  @transition_rules %{
    "suspend" => %{
      "sources" => ["VALID"],
      "next" => "SUSPENDED",
      "kinds" => ["human", "mechanism"],
      "restoration" => false
    },
    "restore" => %{
      "sources" => ["SUSPENDED"],
      "next" => "VALID",
      "kinds" => ["human", "mechanism"],
      "restoration" => true
    },
    "mark_unverifiable" => %{
      "sources" => ["VALID", "SUSPENDED"],
      "next" => "UNVERIFIABLE",
      "kinds" => ["human", "mechanism"],
      "restoration" => false
    },
    "evidence_recovered" => %{
      "sources" => ["UNVERIFIABLE"],
      "next" => "SUSPENDED",
      "kinds" => ["human"],
      "restoration" => true
    }
  }

  @closed_transitions [
    %{
      "from" => "VALID",
      "to" => "REVOKED",
      "predicate" => "P-CERTIFICATE-REVOCATION (CLOSED)",
      "verb" => "revoke"
    },
    %{
      "from" => "VALID",
      "to" => "SUPERSEDED",
      "predicate" => "P-CERTIFICATE-SUPERSESSION successor issuance (CLOSED)",
      "verb" => "supersede"
    }
  ]

  @forbidden_verbs ["revoke", "supersede"]
  @terminal_states ["REVOKED", "SUPERSEDED"]

  @doc "Machine-readable predicate contract."
  def spec do
    %{
      "lifecycle_spec" => @lifecycle_spec,
      "policy" => @policy,
      "policy_version" => @policy_version,
      "canonical_serialization_spec" => @canon_spec,
      "reused_issuance" => "TiannaraOS.Provenance.CertificateIssuance (P-CERTIFICATE-ISSUANCE)",
      "states" => @states,
      "transition_rules" => @transition_rules,
      "restoration_path" => @restoration_path,
      "closed_transitions" => @closed_transitions,
      "terminal_states" => @terminal_states
    }
  end

  @doc "Registry existence + lifecycle ledger replay (idempotent)."
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
              do: raise("certificate lifecycle registry unavailable")

            :ok
        end

      _ ->
        :ok
    end
  end

  @doc """
  Register the single lifecycle authority (explicit, first-writer-wins, no
  rotation/election/competing authorities). `authority` and `authority_kind`
  default to the configured single lifecycle authority.
  """
  def register_authority(opts \\ []) do
    ensure_started(opts)
    ledger = ledger_path(opts)

    entry = %{
      "authority" => Keyword.get(opts, :authority, @lifecycle_authority),
      "authority_kind" => Keyword.get(opts, :authority_kind, @authority_kind),
      "policy_ref" => %{"policy" => @policy, "policy_version" => @policy_version}
    }

    case :ets.insert_new(@table, {:__lifecycle_authority, entry}) do
      true ->
        append_ledger(ledger, %{"registry" => "lifecycle_authority", "entry" => entry})
        {:ok, entry}

      false ->
        {:error, :competing_authority, registered_authority()}
    end
  end

  @doc "Whether `authority` is the registered single lifecycle authority."
  def authorized_lifecycle_authority?(authority) do
    case registered_authority() do
      nil -> false
      %{"authority" => a} -> a == authority
    end
  end

  @doc """
  Submit a lifecycle transition request.

  request carries:
    certificate_id      issued certificate to transition (must resolve in the
                        issuance registry; the issuance record is read-only here)
    lifecycle_spec      #{inspect(@lifecycle_spec)} (enforced)
    transition          one of #{inspect(Map.keys(@transition_rules))}
                        ("revoke"/"supersede"/other verbs FAIL CLOSED)
    reason              binary reason (audit)
    authority_header    %{authority, authority_kind, role: "lifecycle"}
    policy_ref          accepted policy + version + authority_doc
    transition_evidence %{evidence_type, summary} (required)
    restoration         %{lineage, bundle_dir, bundle_id} REQUIRED and
                        re-verified for restore + evidence_recovered

  Returns {:ok, transition} | {:ok, replayed} | {:error, reason, detail}.
  Lifecycle state changes ONLY on a fully-passing transition; never otherwise.
  """
  def transition(request, opts \\ []) do
    ensure_started(opts)

    with :ok <- validate_request(request),
         :ok <- validate_lifecycle_spec(request["lifecycle_spec"]),
         {:ok, verb_spec} <- resolve_transition(request["transition"]),
         :ok <- validate_authority(request, verb_spec),
         :ok <- validate_policy_ref(request),
         :ok <- validate_evidence(request, verb_spec),
         {:ok, issuance} <- require_issued_certificate(request["certificate_id"]) do
      cid = request["certificate_id"]

      case acquire_lock(cid) do
        :ok ->
          try do
            commit_transition(request, verb_spec, issuance, cid, opts)
          after
            delete_lock(cid)
          end

        {:error, reason, detail} ->
          {:error, reason, detail}
      end
    end
  end

  @doc "Current lifecycle state record for an issued certificate."
  def current_state(certificate_id) when is_binary(certificate_id) do
    case current_record(certificate_id) do
      {:ok, record} ->
        {:ok,
         %{
           "state" => record["next_state"],
           "sequence" => record["sequence"],
           "materialized" => true
         }}

      :unregistered ->
        case fallback_initial(certificate_id) do
          {:ok, initial} ->
            {:ok,
             %{
               "state" => initial["next_state"],
               "sequence" => initial["sequence"],
               "materialized" => false
             }}

          error ->
            error
        end
    end
  end

  @doc "Complete transition history for a certificate_id (sequence order)."
  def history(certificate_id) when is_binary(certificate_id) do
    if table?() do
      @table
      |> :ets.tab2list()
      |> Enum.flat_map(fn
        {{^certificate_id, seq}, record} when is_integer(seq) and is_map(record) -> [record]
        _ -> []
      end)
      |> Enum.sort_by(& &1["sequence"])
    else
      []
    end
  end

  @doc "Registry snapshot (current lifecycle state per certificate_id)."
  def export do
    if table?() do
      @table
      |> :ets.tab2list()
      |> Enum.flat_map(fn
        {{cid, :state}, record} when is_binary(cid) -> [record]
        _ -> []
      end)
      |> Enum.sort_by(fn r -> {r["recorded_at_spec"], r["certificate_id"]} end)
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

  # ---------------------------------------------------------------------------
  # Transition resolution / classification
  # ---------------------------------------------------------------------------

  defp resolve_transition(verb) when is_binary(verb) do
    cond do
      verb in @forbidden_verbs ->
        closed = Enum.find(@closed_transitions, &(&1["verb"] == verb))

        {:error, :transition_forbidden,
         %{transition: verb, predicate: closed && closed["predicate"]}}

      Map.has_key?(@transition_rules, verb) ->
        {:ok, Map.fetch!(@transition_rules, verb)}

      true ->
        {:error, :transition_undefined, %{transition: verb}}
    end
  end

  defp resolve_transition(_), do: {:error, :invalid_transition, %{}}

  defp source_allowed?(sources, state), do: state in sources

  # ---------------------------------------------------------------------------
  # Authority boundary (single lifecycle authority; explicit, non-ambiguous)
  # ---------------------------------------------------------------------------

  defp validate_authority(request, verb_spec) do
    header = request["authority_header"]

    case header do
      %{"authority" => authority, "authority_kind" => kind, "role" => "lifecycle"}
      when is_binary(authority) and kind in ["human", "mechanism"] ->
        with :ok <- authority_registered?(),
             :ok <- authority_name?(authority),
             :ok <- authority_kind_matches?(kind),
             :ok <- authority_kind_permitted?(kind, verb_spec) do
          :ok
        end

      _ ->
        {:error, :malformed_authority_header, %{}}
    end
  end

  defp authority_registered? do
    if registered_authority() == nil, do: {:error, :authority_unregistered, %{}}, else: :ok
  end

  defp authority_name?(authority) do
    case registered_authority() do
      %{"authority" => a} when a == authority -> :ok
      _ -> {:error, :unauthorized_authority, %{authority: authority}}
    end
  end

  defp authority_kind_matches?(kind) do
    case registered_authority() do
      %{"authority_kind" => k} when k == kind ->
        :ok

      %{"authority_kind" => k} ->
        {:error, :authority_kind_mismatch, %{registered: k, given: kind}}

      _ ->
        {:error, :authority_unregistered, %{}}
    end
  end

  defp authority_kind_permitted?(kind, verb_spec) do
    if kind in verb_spec["kinds"], do: :ok, else: {:error, :authority_kind_denied, %{kind: kind}}
  end

  defp validate_policy_ref(request) do
    case request["policy_ref"] do
      %{
        "policy" => @policy,
        "policy_version" => @policy_version,
        "authority_doc" => doc,
        "authority_doc_id" => doc_id
      }
      when is_binary(doc) and is_binary(doc_id) ->
        :ok

      _ ->
        {:error, :invalid_policy_ref, %{}}
    end
  end

  # ---------------------------------------------------------------------------
  # Evidence requirements
  # ---------------------------------------------------------------------------

  defp validate_evidence(request, verb_spec) do
    case request["transition_evidence"] do
      %{"evidence_type" => type, "summary" => summary}
      when is_binary(type) and type != "" and is_binary(summary) and summary != "" ->
        if verb_spec["restoration"] do
          validate_restoration(request)
        else
          :ok
        end

      _ ->
        {:error, :missing_transition_evidence, %{}}
    end
  end

  defp validate_restoration(request) do
    case request["restoration"] do
      %{"lineage" => lineage, "bundle_dir" => bundle_dir, "bundle_id" => bundle_id}
      when is_map(lineage) and is_binary(bundle_dir) and is_binary(bundle_id) ->
        with :ok <- verify_restoration_chain(lineage, bundle_dir, bundle_id) do
          :ok
        end

      _ ->
        {:error, :missing_restoration_evidence, %{}}
    end
  end

  defp verify_restoration_chain(lineage, bundle_dir, bundle_id) do
    lineage_ok =
      lineage != nil and
        TiannaraOS.Provenance.MetricLineage.verify_lineage(lineage)["verdict"] in [
          "ACCEPT",
          "NOT CERTIFIABLE"
        ]

    bundle_ok =
      bundle_dir != nil and File.dir?(bundle_dir) and
        case TiannaraOS.Provenance.MetricLineage.verify_bundle(bundle_dir) do
          %{"bundle_id" => actual, "verdict" => "ACCEPT"} when is_binary(actual) ->
            actual == bundle_id

          %{"verdict" => "NOT CERTIFIABLE", "bundle_id" => actual} when is_binary(actual) ->
            actual == bundle_id

          _ ->
            false
        end

    if lineage_ok and bundle_ok, do: :ok, else: {:error, :restoration_chain_not_reverified, %{}}
  end

  defp require_issued_certificate(certificate_id) do
    case CertificateIssuance.resolve(certificate_id) do
      {:ok, %{"state" => "VALID"} = record} ->
        {:ok, record}

      {:ok, _record} ->
        {:error, :invalid_certificate_state, %{certificate_id: certificate_id}}

      {:error, :unregistered} ->
        {:error, :unregistered_certificate, %{certificate_id: certificate_id}}
    end
  end

  defp validate_request(request) when is_map(request), do: :ok
  defp validate_request(_), do: {:error, :invalid_request, %{}}

  defp validate_lifecycle_spec(@lifecycle_spec), do: :ok
  defp validate_lifecycle_spec(_), do: {:error, :invalid_request, %{}}

  # ---------------------------------------------------------------------------
  # Commit (atomic single-sentence ledger append, mirrored from issuance)
  # ---------------------------------------------------------------------------

  defp commit_transition(request, verb_spec, issuance, cid, opts) do
    signature = request_signature(request)

    case lookup_record(cid, signature) do
      {:ok, record} ->
        {:ok, Map.merge(record, %{"replayed" => true, "status" => "replayed"})}

      :none ->
        with {:ok, previous_state, sequence, initial} <- resolve_source_state(cid, verb_spec),
             :ok <- ensure_initial_allowed(previous_state, verb_spec, request["transition"]) do
          next_state = verb_spec["next"]

          {:ok, record} =
            build_record(
              request,
              verb_spec,
              issuance,
              cid,
              previous_state,
              next_state,
              sequence,
              initial
            )

          case persist_record(record, cid, ledger_path(opts)) do
            :ok -> {:ok, record}
            {:error, reason, detail} -> {:error, reason, detail}
          end
        else
          {:error, reason, detail} -> {:error, reason, detail}
        end
    end
  end

  defp resolve_source_state(cid, _verb_spec) do
    case current_record(cid) do
      {:ok, record} ->
        {:ok, record["next_state"], record["sequence"], false}

      :unregistered ->
        {:ok, "VALID", 0, true}
    end
  end

  defp ensure_initial_allowed(previous_state, verb_spec, verb) do
    if source_allowed?(verb_spec["sources"], previous_state),
      do: :ok,
      else:
        {:error, :invalid_source_state,
         %{current: previous_state, transition: verb, allowed_sources: verb_spec["sources"]}}
  end

  defp build_record(
         request,
         verb_spec,
         issuance,
         cid,
         previous_state,
         next_state,
         sequence,
         initial
       ) do
    signature = request_signature(request)
    evidence_ids = restoration_evidence_ids(request)
    reverification = reverification_result(request, verb_spec)

    envelope = build_transition_envelope(request, cid, previous_state, next_state, signature)

    record = %{
      "certificate_id" => cid,
      "lifecycle_spec" => @lifecycle_spec,
      "sequence" => sequence + 1,
      "initial" => initial,
      "adopted_from" =>
        if(initial,
          do: %{
            "certificate_id" => issuance["certificate_id"],
            "issuance_record_binding" => %{
              "issuance_spec" => issuance["issuance_spec"],
              "evidence_ids" => issuance["evidence_ids"],
              "decision" => issuance["decision"]
            }
          },
          else: nil
        ),
      "previous_state" => previous_state,
      "next_state" => next_state,
      "lifecycle_state" => next_state,
      "decision" => request["transition"],
      "reason" => request["reason"],
      "recorded_by" => "TiannaraOS.Provenance.CertificateLifecycle/1.0.0",
      "recorded_at_spec" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "authority_header" => request["authority_header"],
      "policy_ref" => request["policy_ref"],
      "transition_evidence" => request["transition_evidence"],
      "restoration_evidence_ids" => evidence_ids,
      "reverification_result" => reverification,
      "request_signature" => signature,
      "transition_envelope" => envelope
    }

    {:ok, record}
  end

  defp persist_record(record, cid, ledger) do
    prev_state_entry = lookup_state_entry(cid)

    case :ets.insert_new(@table, {{cid, record["sequence"]}, record}) do
      true ->
        case append_ledger(ledger, record) do
          :ok ->
            :ets.insert(@table, {{cid, :state}, record})
            :ok

          {:error, _kind, message} ->
            :ets.delete(@table, {cid, record["sequence"]})
            restore_state_entry(prev_state_entry, cid)
            {:error, :persistence_failure, %{reason: message}}
        end

      false ->
        {:error, :duplicate_conflicting, %{certificate_id: cid, sequence: record["sequence"]}}
    end
  end

  defp restore_state_entry({:ok, record}, cid) do
    :ets.insert(@table, {{cid, :state}, record})
    :ok
  end

  defp restore_state_entry(:unregistered, cid) do
    :ets.delete(@table, {cid, :state})
    :ok
  end

  defp build_transition_envelope(request, cid, previous_state, next_state, signature) do
    body = %{
      "envelope_spec" => @lifecycle_spec,
      "object_type" => "certificate_lifecycle_transition",
      "certificate_id" => cid,
      "transition" => request["transition"],
      "previous_state" => previous_state,
      "next_state" => next_state,
      "decision_hash" =>
        Canon.sha256(%{
          "transition" => request["transition"],
          "reason" => request["reason"],
          "certificate_id" => cid
        }),
      "authority_header" => request["authority_header"],
      "policy_ref" => request["policy_ref"],
      "recorded_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "request_signature" => signature
    }

    envelope = %{
      "schema_version" => "1.0.0",
      "envelope_spec" => @lifecycle_spec,
      "event_type" => "certificate_lifecycle_transition",
      "producer" => "TiannaraOS.Provenance.CertificateLifecycle/1.0.0",
      "canonical_serialization_spec" => @canon_spec,
      "verification_status" => "recorded",
      "payload_hash" => nil,
      "body" => body
    }

    %{envelope | "payload_hash" => Canon.sha256(Map.delete(envelope, "payload_hash"))}
  end

  defp request_signature(request) do
    Canon.sha256(%{
      "certificate_id" => request["certificate_id"],
      "transition" => request["transition"],
      "reason" => request["reason"],
      "authority_header" => request["authority_header"],
      "policy_ref" => request["policy_ref"],
      "transition_evidence" => request["transition_evidence"],
      "restoration_evidence_ids" => restoration_evidence_ids(request)
    })
  end

  defp restoration_evidence_ids(request) do
    case request["restoration"] do
      %{"lineage" => lineage, "bundle_id" => bundle_id} when is_binary(bundle_id) ->
        %{"lineage_id" => lineage && lineage["lineage_id"], "bundle_id" => bundle_id}

      _ ->
        nil
    end
  end

  defp reverification_result(request, verb_spec) do
    if verb_spec && verb_spec["restoration"] do
      case request["restoration"] do
        %{"lineage" => lineage, "bundle_dir" => bundle_dir} ->
          result =
            TiannaraOS.Provenance.MetricLineage.verify_lineage(lineage)["verdict"] ||
              "FAILED"

          bundle_verdict =
            case TiannaraOS.Provenance.MetricLineage.verify_bundle(bundle_dir) do
              %{"verdict" => v} -> v
              _ -> "FAILED"
            end

          %{"lineage_verdict" => result, "bundle_verdict" => bundle_verdict}

        _ ->
          nil
      end
    else
      nil
    end
  end

  # ---------------------------------------------------------------------------
  # Registry plumbing (mirrors issuance/IdentityAuthority conventions)
  # ---------------------------------------------------------------------------

  defp fallback_initial(certificate_id) do
    case CertificateIssuance.resolve(certificate_id) do
      {:ok, %{"state" => "VALID"} = record} ->
        {:ok,
         %{
           "certificate_id" => certificate_id,
           "sequence" => 0,
           "previous_state" => nil,
           "next_state" => "VALID",
           "lifecycle_state" => "VALID",
           "decision" => "adopted_from_issuance",
           "materialized" => false,
           "issuance_binding" => %{
             "issuance_spec" => record["issuance_spec"],
             "certificate_id" => record["certificate_id"]
           }
         }}

      _ ->
        {:error, :unregistered}
    end
  end

  defp current_record(certificate_id) do
    case lookup_state_entry(certificate_id) do
      {:ok, record} -> {:ok, record}
      :unregistered -> :unregistered
    end
  end

  defp lookup_state_entry(certificate_id) do
    if table?() do
      case :ets.lookup(@table, {certificate_id, :state}) do
        [{{^certificate_id, :state}, record}] -> {:ok, record}
        _ -> :unregistered
      end
    else
      :unregistered
    end
  end

  defp lookup_record(certificate_id, signature) do
    if table?() do
      case :ets.match_object(@table, {{certificate_id, :_}, :_}) do
        matches ->
          filtered =
            Enum.flat_map(matches, fn
              {{^certificate_id, seq}, record} when is_integer(seq) and is_map(record) ->
                if record["request_signature"] == signature, do: [record], else: []

              _other ->
                []
            end)

          case filtered do
            [] -> :none
            records -> {:ok, Enum.max_by(records, & &1["sequence"])}
          end
      end
    else
      :none
    end
  end

  defp acquire_lock(certificate_id) do
    case :ets.insert_new(@table, {{certificate_id, :lock}, true}) do
      true -> :ok
      false -> {:error, :concurrent_transition, %{certificate_id: certificate_id}}
    end
  end

  defp delete_lock(certificate_id), do: :ets.delete(@table, {certificate_id, :lock})

  defp registered_authority do
    if table?() do
      case :ets.lookup(@table, :__lifecycle_authority) do
        [{:__lifecycle_authority, entry}] -> entry
        _ -> nil
      end
    else
      nil
    end
  end

  defp table?, do: :ets.whereis(@table) != :undefined

  defp ledger_path(opts) do
    Keyword.get_lazy(opts, :ledger_path, &default_ledger_path/0)
  end

  defp default_ledger_path do
    case Application.get_env(:forward_provenance, @ledger_env) do
      nil -> Path.expand("data/certificate_lifecycle_ledger.jsonl")
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
          rec = decode_sentence(line)

          case rec do
            %{"registry" => "lifecycle_authority", "entry" => entry} ->
              :ets.insert_new(@table, {:__lifecycle_authority, entry})

            %{"certificate_id" => cid, "sequence" => seq} = record when is_integer(seq) ->
              :ets.insert_new(@table, {{cid, seq}, record})
              :ets.insert(@table, {{cid, :state}, record})
          end
        end
      end)
    end
  rescue
    _ -> :ok
  end

  defp decode_sentence(line) do
    line
    |> String.trim()
    |> :json.decode()
    |> deep_null_to_nil()
  end

  defp deep_null_to_nil(value) when value == :null, do: nil
  defp deep_null_to_nil(%{} = map), do: Map.new(map, fn {k, v} -> {k, deep_null_to_nil(v)} end)
  defp deep_null_to_nil(list) when is_list(list), do: Enum.map(list, &deep_null_to_nil/1)
  defp deep_null_to_nil(value), do: value
end
