defmodule Tiannara.Omega.GovernedEffectSink do
  @moduledoc """
  ONE bounded governed terminal sink (Wave 3 Step 2).

  Establishes the single missing organism-loop edge for exactly one sink:

      authorization A → effect E → sink invocation(E) → observed result(E)
                    → audit/provenance(E)

  ## Selected sink

  `Tiannara.CEL.Services.EventStore.append/2` into topic `"governed.effect"` —
  an append-only, offset-serialized, DETS-durable event inside Tiannara's
  controlled execution domain (no external-world mutation, naturally
  non-deterministic-free, reversible only by store rotation). The terminal
  result is independently inspectable afterwards via `read_topic/1`.
  Governance requires a second, independent record: `Tiannara.Council.AuditLog.append/3`
  (SHA-256 hash-chained). A governed-success result is returned ONLY if the
  audit record was written.

  ## Identity chain (canonical representation `effect-v1-<sha256hex>`)

  The effect identity comes exclusively from `Tiannara.Omega.EffectIdentity`
  (canonical semantic descriptor → canonical JSON → sha256). The authorization
  carries its bound `effect_id` (see `Authorization.bind_effect/2` /
  `valid_for_effect?/2`). The five compared identities are:

  1. authorization's effect identity   — `grant.effect_id`
  2. sink-request effect identity      — recomputed from the request descriptor
  3. executed-effect identity          — event as STORED (read-back)
  4. result effect identity            — `result.sink.effect_id`
  5. audit/provenance effect identity  — `AuditLog` entry payload

  ## Fail-closed contract (N1-N9)

  Gate order (all pre-sink except N6/N7):

      N1 missing authorization        -> {:error, :authorization_required}
      N4 not granted                  -> {:error, :authorization_not_granted}
      N8 registry verification        -> {:error, :authorization_not_registered}
                                         {:error, :already_consumed}
                                         {:error, :authorization_registry_unavailable}
      N4 expired                      -> {:error, :authorization_expired}
      N4 identity                     -> {:error, :identity_required}
                                         {:error, :identity_not_authenticated}
                                         {:error, :identity_human_mismatch}
      N5 missing effect identity      -> {:error, :effect_binding_required}
                                         malformed descriptor
                                         -> {:error, {:invalid_effect_descriptor, reason}}
      N2/N3 wrong or altered effect   -> {:error, :effect_id_mismatch}
      N8 registry binding mismatch    -> {:error, :registry_binding_mismatch}
      N9 one-shot consumption (CAS)   -> {:error, :already_consumed}
      sink invocation                 -> {:error, {:sink_failed, reason}}
      N6 result identity mismatch     -> {:error, :result_identity_mismatch}
      N7 audit/provenance failure     -> {:error, {:audit_not_recorded, reason, detail}}
      full chain                      -> {:ok, result}

  N8 verifies the grant against the durable `Tiannara.Omega.MintRegistry`
  (model M7): a structurally valid authorization that was never minted through
  the registry, or was already consumed, is refused before any other stateful
  check; the registry-recorded one-shot binding must also equal the grant's
  `effect_id`, so rewriting that field on a plain struct cannot re-point an
  authorization at a different effect. N9 is an atomic granted -> consumed
  compare-and-set immediately before the sink invocation: of N concurrent
  presentations of one grant, exactly one reaches the sink. Registry
  unavailability is fail-closed, never permissive.

  N6/N7 occur AFTER the sink event is written: the contract fails closed on
  the *governed-success claim* (the written event stays observable but is not
  claimed as a governed effect). N1-N5, N8 and N9 never reach the sink.

  ## Bounded claims (explicit non-claims)

  This module closes ONE sink path only. It does NOT provide universal
  authorization integrity, cancellation/revocation, expiry redesign,
  cryptographic non-repudiation, WAL-grade durability, or global D165 closure.
  The `:sink` / `:audit` options are verification seams used by the focused
  tests; the production call path supplies neither.
  """

  alias Tiannara.CEL.Services.EventStore
  alias Tiannara.Council.AuditLog
  alias Tiannara.Omega.EffectIdentity
  alias Tiannara.Omega.HumanDelivery.Authorization
  alias Tiannara.Omega.HumanDelivery.AuthenticatedHumanIdentity
  alias Tiannara.Omega.MintRegistry

  @topic "governed.effect"
  @authority_scope "omega:governed_effect_sink"
  @operation "execute_governed_effect"
  @audit_action :governed_effect_executed

  @type result :: %{
          authorization_id: atom(),
          explanation_id: atom() | String.t() | nil,
          effect_id: String.t(),
          actor: term(),
          effect_descriptor: map(),
          sink: %{
            topic: String.t(),
            offset: non_neg_integer(),
            effect_id: term(),
            authorization_id: term()
          },
          audit: %{seq: non_neg_integer(), hash: String.t(), action: atom()},
          governed: true
        }

  @doc "The single topic this sink writes to."
  def topic, do: @topic

  @doc """
  Build the canonical effect descriptor for this sink. All values must be
  canonically representable (string/int/float/bool/nil/map/list); keys may be
  atoms or strings (normalized to strings by `EffectIdentity`).
  """
  def effect_descriptor(principal, target, parameters)
      when is_map(target) and is_map(parameters) do
    %{
      principal: to_string(principal),
      authority_scope: @authority_scope,
      operation: @operation,
      target: target,
      parameters: parameters,
      environment: %{},
      intent: %{kind: "governed_terminal_sink_execution"},
      semantic_version: "1",
      identity_version: EffectIdentity.identity_version()
    }
  end

  @doc """
  Execute the governed path for a bound authorization. See the module doc for
  the exact gate order and error contract.
  """
  @spec execute(Authorization.t(), map(), keyword()) :: {:ok, result()} | {:error, term()}
  def execute(grant, descriptor, opts \\ [])

  def execute(%Authorization{} = grant, descriptor, opts) when is_map(descriptor) do
    with :ok <- check_authorization_present(grant),
         :ok <- check_granted(grant),
         :ok <- check_registered(grant),
         :ok <- check_not_expired(grant),
         :ok <- check_identity(grant, Keyword.get(opts, :identity)),
         :ok <- check_bound(grant),
         {:ok, normalized} <- normalize_descriptor(descriptor),
         :ok <- check_effect_match(grant, descriptor),
         :ok <- check_registry_binding(grant),
         :ok <- consume_once(grant),
         {:ok, sink_result} <- invoke_sink(grant, normalized, opts),
         :ok <- check_result_identity(grant, sink_result),
         {:ok, audit_entry} <- record_audit(grant, normalized, sink_result, opts) do
      {:ok,
       %{
         authorization_id: grant.authorization_id,
         explanation_id: grant.explanation_id,
         effect_id: grant.effect_id,
         actor: grant.human_id,
         effect_descriptor: normalized,
         sink: sink_result,
         audit: %{seq: audit_entry.seq, hash: audit_entry.hash, action: audit_entry.action},
         governed: true
       }}
    end
  end

  def execute(%Authorization{}, descriptor, _opts) when not is_map(descriptor),
    do: {:error, {:invalid_effect_descriptor, :descriptor_must_be_a_map}}

  def execute(_grant, _descriptor, _opts), do: {:error, :authorization_required}

  # ------------------------------------------------------------ gates (N*) --

  defp check_authorization_present(%Authorization{}), do: :ok

  defp check_granted(%Authorization{status: :granted}), do: :ok
  defp check_granted(%Authorization{}), do: {:error, :authorization_not_granted}

  defp check_registered(grant) do
    case MintRegistry.status(grant.authorization_id) do
      :granted -> :ok
      :consumed -> {:error, :already_consumed}
      :not_registered -> {:error, :authorization_not_registered}
      :registry_unavailable -> {:error, :authorization_registry_unavailable}
    end
  end

  defp check_not_expired(grant) do
    if Authorization.expired?(grant), do: {:error, :authorization_expired}, else: :ok
  end

  defp check_identity(_grant, nil), do: {:error, :identity_required}

  defp check_identity(grant, %AuthenticatedHumanIdentity{} = identity) do
    cond do
      not AuthenticatedHumanIdentity.authenticated?(identity) ->
        {:error, :identity_not_authenticated}

      identity.human_id != grant.human_id ->
        {:error, :identity_human_mismatch}

      true ->
        :ok
    end
  end

  defp check_identity(_grant, _other), do: {:error, :identity_required}

  defp check_bound(%Authorization{effect_id: effect_id}) when is_binary(effect_id), do: :ok
  defp check_bound(%Authorization{}), do: {:error, :effect_binding_required}

  defp normalize_descriptor(descriptor) do
    case EffectIdentity.new(descriptor) do
      {:ok, normalized} -> {:ok, normalized}
      {:error, reason} -> {:error, {:invalid_effect_descriptor, reason}}
    end
  end

  defp check_effect_match(grant, descriptor) do
    if Authorization.valid_for_effect?(grant, descriptor) do
      :ok
    else
      {:error, :effect_id_mismatch}
    end
  end

  defp check_registry_binding(grant) do
    case MintRegistry.binding(grant.authorization_id) do
      {:ok, registry_effect_id} ->
        if registry_effect_id == grant.effect_id do
          :ok
        else
          {:error, :registry_binding_mismatch}
        end

      :not_bound ->
        {:error, :registry_binding_mismatch}

      :not_registered ->
        {:error, :authorization_not_registered}

      :registry_unavailable ->
        {:error, :authorization_registry_unavailable}
    end
  end

  defp consume_once(grant) do
    case MintRegistry.consume(grant.authorization_id, grant.effect_id) do
      :ok -> :ok
      {:error, :already_consumed} -> {:error, :already_consumed}
      {:error, :not_registered} -> {:error, :authorization_not_registered}
      :registry_unavailable -> {:error, :authorization_registry_unavailable}
    end
  end

  # ------------------------------------------------------------- execution --

  defp invoke_sink(grant, normalized, opts) do
    effect_id = grant.effect_id

    event = %{
      effect_id: effect_id,
      authorization_id: grant.authorization_id,
      explanation_id: grant.explanation_id,
      actor: grant.human_id,
      principal: Map.get(normalized, "principal"),
      operation: Map.get(normalized, "operation"),
      effect_descriptor: normalized,
      payload: Keyword.get(opts, :payload, %{}),
      executed_at: DateTime.utc_now()
    }

    sink_fun = Keyword.get(opts, :sink, &default_sink/2)

    try do
      case sink_fun.(effect_id, event) do
        {:ok, %{} = result} -> {:ok, result}
        {:error, reason} -> {:error, {:sink_failed, reason}}
        other -> {:error, {:sink_failed, {:unexpected_sink_result, other}}}
      end
    catch
      kind, reason -> {:error, {:sink_failed, {kind, reason}}}
    end
  end

  defp default_sink(_effect_id, event) do
    case EventStore.append(@topic, event) do
      {:ok, offset} ->
        stored = readback(offset)

        {:ok,
         %{
           topic: @topic,
           offset: offset,
           effect_id: Map.get(stored, :effect_id),
           authorization_id: Map.get(stored, :authorization_id),
           stored_event: stored
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp readback(offset) do
    EventStore.read_topic(@topic)
    |> Enum.find_value(fn
      {^offset, event, _ts} when is_map(event) -> event
      _ -> nil
    end) || %{}
  end

  defp check_result_identity(grant, result) do
    stored_effect_id = Map.get(result, :effect_id)
    stored_authorization_id = Map.get(result, :authorization_id)

    if stored_effect_id == grant.effect_id and stored_authorization_id == grant.authorization_id do
      :ok
    else
      {:error, :result_identity_mismatch}
    end
  end

  # ------------------------------------------------------------------ audit --

  defp record_audit(grant, normalized, sink_result, opts) do
    payload = %{
      effect_id: grant.effect_id,
      authorization_id: grant.authorization_id,
      explanation_id: grant.explanation_id,
      actor: grant.human_id,
      principal: Map.get(normalized, "principal"),
      operation: Map.get(normalized, "operation"),
      sink_topic: Map.get(sink_result, :topic),
      sink_offset: Map.get(sink_result, :offset),
      stored_effect_id: Map.get(sink_result, :effect_id),
      executed_at: Map.get(sink_result, :stored_event, %{})[:executed_at]
    }

    audit_fun = Keyword.get(opts, :audit, &default_audit/1)

    try do
      case audit_fun.(payload) do
        {:ok, %{} = entry} ->
          {:ok, entry}

        {:error, reason} ->
          {:error, {:audit_not_recorded, reason, audit_detail(sink_result)}}

        other ->
          {:error,
           {:audit_not_recorded, {:unexpected_audit_result, other}, audit_detail(sink_result)}}
      end
    catch
      kind, reason ->
        {:error, {:audit_not_recorded, {kind, reason}, audit_detail(sink_result)}}
    end
  end

  defp default_audit(payload) do
    AuditLog.append(@audit_action, payload.actor, payload)
  end

  defp audit_detail(sink_result) do
    %{
      executed: true,
      governed: false,
      topic: Map.get(sink_result, :topic),
      offset: Map.get(sink_result, :offset),
      stored_effect_id: Map.get(sink_result, :effect_id)
    }
  end
end
