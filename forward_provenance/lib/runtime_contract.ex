defmodule TiannaraOS.Provenance.RuntimeContract do
  @moduledoc """
  Provenance Runtime Contract (Stages 2 + 4, Council-authorized).

  Normalizes an OPAQUE runtime execution event from any producer (forward demo,
  Phase-4 RealExecution, OPC ExecutionRuntime, future producers) into the
  forward provenance model through exactly ONE identity authority, and binds
  execution ids used in provenance graph joins to exactly one registered
  producer.

  Stage 4 adds the failure vocabulary (TIMEOUT/CANCELLED/ABORTED/UNKNOWN beyond
  SUCCESS/FAILURE/PARTIAL) and DISTRIBUTED semantics (a declared parent
  execution id + a PARENT_OF edge that is NEVER auto-attributed).

  Properties (normative copy: spec/provenance_runtime_contract.yaml):
    * opaque id acceptance: any `execution_id` shape is accepted, but only by
      resolution through the IdentityAuthority (first-writer-wins)
    * SUBSTITUTION (test K): a record that would attribute an id owned by
      another producer to itself is rejected
    * RETRY = NEW execution id (test L): re-starting an already-opened
      execution id within a lifecycle window (or folded series) is an
      attempt-reuse violation and is rejected; Stage 3 instrumentation starts
      resolve idempotently only when the id was authority-minted by the same
      producer and the lifecycle window has no prior entry for it
    * terminal events (completed/failed/partial/timed_out/cancelled/aborted/
      unknown) require an open `started` for the same id+producer;
      orphan/unknown/closed attempts are rejected
    * FAILURE VOCABULARY (test M): each terminal maps one-to-one to
      SUCCESS/FAILURE/PARTIAL/TIMEOUT/CANCELLED/ABORTED/UNKNOWN. ONLY
      `completed` is certifiable; every other terminal - including an
      `unknown` status - is NOT CERTIFIABLE and is never silently upgraded.
    * DISTRIBUTED (test P): a start/terminal event may declare a
      `parent_execution_id`. The PARENT_OF edge is created ONLY when the parent
      resolves in the identity authority. An unresolvable parent yields
      UNVERIFIED and is NEVER auto-attributed (no fabricated/guessed parent).
      An execution with no declared parent is a root execution, not an orphan.
    * resolver binding: bind/2 joins an opaque id to exactly one producer

  PURE CONTRACT: accept/2 takes a caller-owned lifecycle map and returns the
  updated lifecycle, with no hidden state. Stage 3 instrumentation and any
  distributed holder own the lifecycle between events.
  """

  alias TiannaraOS.Provenance.{Envelope, IdentityAuthority}

  @contract "tiannara-fp-runtime-contract-v1"
  @terminal_states [
    "completed",
    "failed",
    "partial",
    "timed_out",
    "cancelled",
    "aborted",
    "unknown"
  ]

  @verdicts %{
    "completed" => "SUCCESS",
    "failed" => "FAILURE",
    "partial" => "PARTIAL",
    "timed_out" => "TIMEOUT",
    "cancelled" => "CANCELLED",
    "aborted" => "ABORTED",
    "unknown" => "UNKNOWN"
  }

  @doc "Machine-readable contract descriptor."
  def spec do
    %{
      "contract" => @contract,
      "authority" => IdentityAuthority.spec()["authority"],
      "opaque_id_acceptance" => "authority_first_writer_wins",
      "lifecycle" =>
        "started -> exactly_one(completed|failed|partial|timed_out|cancelled|aborted|unknown)",
      "failure_vocabulary" => @verdicts,
      "not_certifiable_statuses" => "all except completed",
      "distributed" => %{
        "declared_parent" => "optional parent_execution_id on start/terminal",
        "edge" => "PARENT_OF",
        "unresolved_parent" => "UNVERIFIED, never auto-attributed",
        "no_parent" => "root execution (not an orphan)"
      },
      "substitution" => "reject",
      "attempt_reuse" => "reject",
      "retry_policy" => "new_execution_id_per_attempt",
      "orphan_ended" => "unverifiable",
      "graph_join_binding" => "resolve_via_identity_authority"
    }
  end

  @doc "Fresh, empty lifecycle map (caller-owned)."
  def start_lifecycle, do: %{}

  @doc """
  Accept ONE normalized runtime event.

  Returns `{:ok, normalized_record, lifecycle2}` on success, or
  `{:error, reason, culprit}` where `reason` is one of:
    :substitution (test K)   id owned by a different producer
    :attempt_reuse (test L)  re-starting an already-open/closed execution id
                             within the caller-owned lifecycle window
    :orphan_ended            terminal event for an id the authority never saw
    :unknown_attempt         terminal event with no open started in this
                             lifecycle
    :closed_attempt          terminal event on an already-closed execution
  """
  def accept(event, lifecycle \\ %{})

  def accept(%{"event_type" => "started"} = event, lifecycle) do
    execution_id = fetch_id!(event)
    producer = fetch_producer!(event)

    case IdentityAuthority.claim(execution_id, producer) do
      {:ok, record} ->
        opened_at = DateTime.utc_now() |> DateTime.to_iso8601()

        {:ok, to_record(event, record, "started"),
         Map.put(lifecycle, execution_id, %{state: :open, producer: producer, opened_at: opened_at})}

      {:error, :duplicate, existing} ->
        cond do
          existing["producer"] != producer ->
            {:error, :substitution, existing}

          Map.has_key?(lifecycle, execution_id) ->
            {:error, :attempt_reuse, existing}

          true ->
            # Stage 3 instrumentation: the id was authority-MINTED by this same
            # producer (see TiannaraOS.Provenance.Producer). The claim is a
            # first-writer replay of the mint, so resolve-and-open instead of
            # rejecting. A re-start WITHIN the caller-owned lifecycle window
            # (or a folded series) still hits the :attempt_reuse branch above.
            opened_at = DateTime.utc_now() |> DateTime.to_iso8601()

            {:ok, to_record(event, existing, "started"),
             Map.put(lifecycle, execution_id, %{state: :open, producer: producer, opened_at: opened_at})}
        end
    end
  end

  def accept(%{"event_type" => event_type} = event, lifecycle) when event_type in @terminal_states do
    execution_id = fetch_id!(event)
    producer = fetch_producer!(event)

    case IdentityAuthority.resolve(execution_id) do
      {:error, :unregistered} ->
        {:error, :orphan_ended, %{"execution_id" => execution_id, "producer" => producer}}

      {:ok, record} ->
        if record["producer"] != producer do
          {:error, :substitution, record}
        else
          case Map.fetch(lifecycle, execution_id) do
            {:ok, %{state: :open, producer: ^producer}} ->
              closed_at = DateTime.utc_now() |> DateTime.to_iso8601()

              {:ok, to_record(event, record, event_type),
               Map.put(lifecycle, execution_id, %{state: :closed, producer: producer, closed_at: closed_at})}

            {:ok, %{state: :closed, producer: ^producer}} ->
              {:error, :closed_attempt, record}

            :error ->
              {:error, :unknown_attempt, record}
          end
        end
    end
  end

  @doc """
  Resolver binding for graph joins. Binds an opaque execution id to exactly one
  producer. Returns `{:ok, record}`, `{:error, :unregistered}`, or
  `{:error, :substitution, existing}` (test K) when the join would attribute
  the id to someone other than its owner.
  """
  def bind(execution_id, producer) do
    case IdentityAuthority.resolve(execution_id) do
      {:error, :unregistered} = err -> err

      {:ok, record} ->
        if record["producer"] == producer do
          {:ok, record}
        else
          {:error, :substitution, record}
        end
    end
  end

  @doc """
  Fold a chronological event list through accept/2 with ONE lifecycle.
  Returns `{:ok, normalized_records, lifecycle}` or
  `{:error, reason, culprit, event}` for the first violation.
  """
  def verify_series(records, lifecycle \\ %{}) do
    do_verify(records, lifecycle, [])
  end

  defp do_verify([], lifecycle, acc), do: {:ok, Enum.reverse(acc), lifecycle}

  defp do_verify([event | rest], lifecycle, acc) do
    case accept(event, lifecycle) do
      {:ok, record, lifecycle2} -> do_verify(rest, lifecycle2, [record | acc])
      {:error, reason, culprit} -> {:error, reason, culprit, event}
    end
  end

  @doc """
  Render a normalized lifecycle's records as forward-provenance envelope drafts
  (execution_started then execution_ended). Provided so Stage 3 producers and
  Stage 7 adversarial tests share one envelope shape; emits only, persists only
  on explicit producer responsibility.
  """
  def to_envelopes([%{"status" => _} | _] = records) do
    records
    |> Enum.with_index()
    |> Enum.map(fn {record, index} ->
      event_type = if index == 0, do: "execution_started", else: "execution_ended"

      Envelope.build(
        event_type: event_type,
        producer: record["producer"],
        body: Map.take(record, [
          "execution_id",
          "status",
          "parent_execution_id",
          "experiment_id",
          "campaign_id",
          "seed",
          "attempt",
          "failure",
          "input_manifest",
          "output_manifest"
        ])
      )
    end)
  end

  def to_envelopes(records), do: Enum.map(records, &to_envelopes([&1]))

  @doc "Normalize an opaque event into the contract record."
  def to_record(event, authority_record, event_type) do
    %{
      "execution_id" => authority_record["execution_id"],
      "producer" => authority_record["producer"],
      "id_format" => authority_record["id_format"],
      "authority" => authority_record["authority"],
      "status" => event_type,
      "parent_execution_id" => Map.get(event, "parent_execution_id"),
      "experiment_id" => Map.get(event, "experiment_id"),
      "campaign_id" => Map.get(event, "campaign_id"),
      "seed" => Map.get(event, "seed"),
      "attempt" => Map.get(event, "attempt", 1),
      "input_manifest" => Map.get(event, "input_manifest", []),
      "output_manifest" => Map.get(event, "output_manifest", []),
      "failure" => Map.get(event, "failure"),
      "at" => Map.get(event, "at", DateTime.utc_now() |> DateTime.to_iso8601())
    }
  end

  @doc """
  Map a recorded terminal status to the forward failure vocabulary
  (Stage 4, test M). SUCCESS/FAILURE/PARTIAL/UNKNOWN alone are insufficient for
  a runtime; TIMEOUT/CANCELLED/ABORTED complete the vocabulary. A status
  outside the legal terminal set maps to UNKNOWN and is NOT a legal terminal.
  """
  def failure_verdict(status), do: Map.get(@verdicts, status, "UNKNOWN")

  @doc """
  Only `completed` is certifiable. Every failure terminal - FAILURE(-&gt;failed),
  PARTIAL, TIMEOUT, CANCELLED, ABORTED, and the UNKNOWN status - is NOT
  CERTIFIABLE and is never silently upgraded to a certifiable outcome
  (certification authority, Stage 6, MUST refuse such records).
  """
  def certifiable?(status), do: status == "completed"

  @doc """
  Stage 4 distributed semantics (test P).

  A declared `parent_execution_id` yields a PARENT_OF edge ONLY when the parent
  resolves in the identity authority. An unresolvable parent returns
  `{:error, :unresolved_parent, context}`; the caller MUST treat the whole
  chain as UNVERIFIED. This function NEVER fabricates, guesses, or silently
  links a parent: there is no auto-attribution path.
  """
  def parent_edge(child_record) do
    case Map.fetch(child_record, "parent_execution_id") do
      {:ok, parent_id} when is_binary(parent_id) ->
        case IdentityAuthority.resolve(parent_id) do
          {:ok, parent_record} ->
            {:ok,
             %{
               "type" => "PARENT_OF",
               "from" => %{"kind" => "execution", "id" => parent_record["execution_id"]},
               "to" => %{"kind" => "execution", "id" => child_record["execution_id"]}
             }}

          {:error, :unregistered} ->
            {:error, :unresolved_parent,
             %{
               "parent_execution_id" => parent_id,
               "child_execution_id" => child_record["execution_id"],
               "producer" => child_record["producer"]
             }}
        end

      _ ->
        {:error, :no_parent, %{"child_execution_id" => child_record["execution_id"]}}
    end
  end

  @doc """
  Advisory verdict for a distributed execution (test P acceptance).

  * declared parent resolves   -> `"parent_resolved"` carrying the edge
  * declared parent unresolved -> `"UNVERIFIED"` (never auto-attributed)
  * no declared parent         -> `"root"` (a root execution, not an orphan)
  """
  def distributed_verdict(child_record) do
    case parent_edge(child_record) do
      {:ok, edge} -> %{"verdict" => "parent_resolved", "edge" => edge}
      {:error, :no_parent, _ctx} -> %{"verdict" => "root"}
      {:error, :unresolved_parent, ctx} -> %{"verdict" => "UNVERIFIED", "reason" => "unresolved_parent", "context" => ctx}
    end
  end

  @doc """
  Emit an immutable `edge_created` envelope carrying a PARENT_OF edge
  (distributed linkage). Emits only; persistence is an explicit producer
  responsibility, exactly like to_envelopes/1.
  """
  def to_parent_edge_envelope(%{"type" => "PARENT_OF"} = edge, producer) do
    Envelope.build(
      event_type: "edge_created",
      producer: producer,
      body: edge
    )
  end

  defp fetch_id!(event) do
    case Map.fetch(event, "execution_id") do
      {:ok, id} when is_binary(id) -> id
      _ -> raise ArgumentError, "runtime event missing binary execution_id"
    end
  end

  defp fetch_producer!(event) do
    case Map.fetch(event, "producer") do
      {:ok, p} when is_binary(p) -> p
      _ -> raise ArgumentError, "runtime event missing producer"
    end
  end
end