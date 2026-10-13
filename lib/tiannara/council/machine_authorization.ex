defmodule Tiannara.Council.MachineAuthorization do
  @moduledoc """
  Machine-class authorization object (model M2).

  ONE struct concept for machine authority: the existing `%Tiannara.Council.Authorization{}`
  becomes the DECISION PAYLOAD of the authorization, not the authorization itself —
  it gains granted_at/ttl/effect_id/lineage by being wrapped, not by mutation.

  Fields (M2):
    - authorization_id: unique, monotonically minted, REGISTRY-RECORDED (M7 via
      `Tiannara.Omega.MintRegistry`) — an id that was never registered is refused
      at the sink regardless of how valid the struct looks (D127.6).
    - authority_class: always `:machine`
    - authority_ref: legacy reference to the policy that produced the decision
      (`policy_applied`)
    - council_decision_ref: digest of the council decision payload at mint,
      recorded IN THE MINT REGISTRY (step-9 residual R-1 closed): the registry
      copy is compared at bind, so a struct whose decision payload was rewritten
      and rehashed cannot pass — the attacker cannot alter the registry's
      anchored digest. Also pinned inside `content_hash` (G4).
    - status: `:granted` at mint; consumption/revocation are registry-recorded
      transitions (M4); mint refuses non-permitted decisions
    - effect_id: `nil` until one-shot bind (M3); required before consumption
    - granted_at/ttl: sink-enforced expiry for machine decisions (G3); machine
      decisions expire exactly like human grants
    - decision_type: the operation class authorized (G4 checks it at the sink)
    - content_hash: immutability pin over the mint-time core (decision,
      decision_type, granted_at, ttl, council_decision_ref) — the sink
      re-verifies it (G4) so naive struct mutation (widened ttl, rewritten
      decision, backdated grant) is refused. The hash algorithm is public: the
      rehash-capable variant is blocked by the registry-anchored
      council_decision_ref comparison at bind (R-1), not by secrecy.
    - lineage: append-only transition record (mint, bind)

  Binding is exactly as strict as the human path (I-B 164-184): granted + nil
  only, one-shot, registry-recorded, `{:error, {:already_bound, existing}}` on
  a second bind.

  Constitutional basis: Safety and Reliability, "Capability must never outpace
  verification", "Maintain audit trails".
  """

  alias Tiannara.Council.Authorization
  alias Tiannara.Omega.{EffectIdentity, MintRegistry}

  defstruct [
    :authorization_id,
    :authority_class,
    :authority_ref,
    :council_decision_ref,
    :status,
    :effect_id,
    :decision_type,
    :granted_at,
    :ttl,
    :content_hash,
    :decision,
    lineage: []
  ]

  @type status :: :granted | :denied | :consumed | :expired | :revoked
  @type t :: %__MODULE__{
          authorization_id: atom() | String.t(),
          authority_class: :machine,
          authority_ref: atom() | nil,
          council_decision_ref: String.t() | nil,
          status: status(),
          effect_id: String.t() | nil,
          decision_type: atom(),
          granted_at: DateTime.t(),
          ttl: integer(),
          content_hash: String.t(),
          decision: Authorization.t(),
          lineage: [{atom(), DateTime.t(), map()}]
        }

  @default_ttl_seconds 3600

  @doc """
  Wraps a permitted council decision into a machine-class authorization and
  records it in the mint registry (M7). The registry write happens first
  (fail-closed): an unavailable registry never yields a grantable authorization.

  Options: `:decision_type` (required, the operation class authorized),
  `:ttl` (seconds, default #{@default_ttl_seconds}).
  """
  @spec mint(Authorization.t(), keyword()) :: {:ok, t()} | {:error, term()}
  def mint(%Authorization{} = decision, opts) when is_list(opts) do
    case Keyword.fetch(opts, :decision_type) do
      {:ok, decision_type} when is_atom(decision_type) and not is_nil(decision_type) ->
        do_mint(decision, decision_type, Keyword.get(opts, :ttl, @default_ttl_seconds))

      {:ok, other} ->
        {:error, {:invalid_decision_type, other}}

      :error ->
        {:error, :decision_type_required}
    end
  end

  def mint(_decision, _opts), do: {:error, :invalid_decision}

  defp do_mint(decision, decision_type, ttl) when is_integer(ttl) do
    cond do
      not Authorization.permitted?(decision) ->
        {:error, :decision_not_permitted}

      is_nil(decision.decided_at) ->
        {:error, :invalid_decision}

      true ->
        id = mint_id()
        decision_ref = decision_ref(decision)

        case record_mint(id, decision_ref) do
          :ok ->
            now = DateTime.utc_now()

            {:ok,
             %__MODULE__{
               authorization_id: id,
               authority_class: :machine,
               authority_ref: decision.policy_applied,
               council_decision_ref: decision_ref,
               status: :granted,
               effect_id: nil,
               decision_type: decision_type,
               granted_at: now,
               ttl: ttl,
               content_hash: hash_core(decision, decision_type, now, ttl, decision_ref),
               decision: decision,
               lineage: [{:minted, now, %{decision_type: decision_type}}]
             }}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  defp do_mint(_decision, _decision_type, _ttl), do: {:error, :invalid_ttl}

  @doc """
  One-shot binding of a granted, unbound authorization to an effect's canonical
  descriptor (M3). The binding is recorded in the mint registry BEFORE the
  struct is updated, so a registry failure leaves the authorization unbound.
  """
  @spec bind_effect(t(), map()) :: {:ok, t()} | {:error, term()}
  def bind_effect(%__MODULE__{status: :granted, effect_id: nil} = auth, descriptor)
      when is_map(descriptor) do
    case EffectIdentity.effect_id(descriptor) do
      {:ok, effect_id} ->
        now = DateTime.utc_now()

        case MintRegistry.record_bind(auth.authorization_id, effect_id,
               council_decision_ref: auth.council_decision_ref
             ) do
          :ok ->
            {:ok,
             %__MODULE__{
               auth
               | effect_id: effect_id,
                 lineage: auth.lineage ++ [{:bound, now, %{effect_id: effect_id}}]
             }}

          :registry_unavailable ->
            {:error, :authorization_registry_unavailable}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, {:invalid_descriptor, reason}}
    end
  end

  def bind_effect(%__MODULE__{effect_id: existing}, _descriptor),
    do: {:error, {:already_bound, existing}}

  def bind_effect(%__MODULE__{status: status}, _descriptor),
    do: {:error, {:authorization_not_granted, status}}

  def bind_effect(_authorization, _descriptor), do: {:error, :invalid_authorization}

  @doc "Sink-side expiry check (G3) against granted_at + ttl, for both authority classes."
  @spec expired?(t()) :: boolean()
  def expired?(%__MODULE__{granted_at: %DateTime{} = granted_at, ttl: ttl})
      when is_integer(ttl),
      do: DateTime.diff(DateTime.utc_now(), granted_at) > ttl

  def expired?(_authorization), do: true

  @doc """
  Recomputes the immutability pin over the authorization's mint-time core
  (decision, decision_type, granted_at, ttl, council_decision_ref). The sink
  compares this against the stored `content_hash` at G4.
  """
  @spec content_hash(t()) :: String.t()
  def content_hash(%__MODULE__{} = auth),
    do: hash_core(auth.decision, auth.decision_type, auth.granted_at, auth.ttl, auth.council_decision_ref)

  defp hash_core(decision, decision_type, granted_at, ttl, council_decision_ref) do
    %{
      decision: decision,
      decision_type: decision_type,
      granted_at: granted_at,
      ttl: ttl,
      council_decision_ref: council_decision_ref
    }
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp decision_ref(%Authorization{} = decision) do
    decision
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp record_mint(id, decision_ref) do
    case MintRegistry.record_mint(id, council_decision_ref: decision_ref) do
      :ok -> :ok
      :registry_unavailable -> {:error, :authorization_registry_unavailable}
      {:error, reason} -> {:error, reason}
    end
  end

  defp mint_id do
    rand = :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
    :"mauth-#{System.unique_integer([:monotonic])}_#{rand}"
  end
end
