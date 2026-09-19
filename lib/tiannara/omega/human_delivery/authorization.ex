defmodule Tiannara.Omega.HumanDelivery.Authorization do
  @moduledoc """
  The mandatory human-authorization gate.

  AUTHORITY BOUNDARY (constitutional): a deployment candidate can ONLY be
  deployed with an `AuthorizationGrant`, and a grant can ONLY be minted by an
  explicit human decision carrying a `human_id`. There is NO code path that
  produces a valid grant without a human.

  State machine:
      :prepared → :pending_authorization → :granted | :denied | :expired

  Constitutional basis: augmentation clause, Safety and Reliability ("Capability
  must never outpace verification"), "Maintain audit trails".

  Effect boundary: a grant may be minted bound to the canonical identity of a
  specific consequential effect (see `Tiannara.Omega.EffectIdentity`). A grant
  names either no effect or exactly one; a grant that names no effect can never
  be valid for a specific effect. This prevents an authorization granted for one
  effect from being replayed against a different effect.
  """

  alias Tiannara.Omega.EffectIdentity
  alias Tiannara.Omega.HumanDelivery.Explanation

  @enforce_keys [:authorization_id, :explanation_id]
  defstruct [
    :authorization_id,
    :explanation_id,
    :human_id,
    :granted_at,
    :ttl,
    :candidate_content_hash,
    :effect_id,
    :decision,
    :reason,
    :lineage,
    status: :prepared
  ]

  @type t :: %__MODULE__{}

  @default_ttl 3600

  @legal_transitions %{
    prepared: [:pending_authorization],
    pending_authorization: [:granted, :denied, :expired],
    granted: [:expired],
    denied: [],
    expired: []
  }

  def legal_transitions, do: @legal_transitions

  @doc "Prepare an authorization request for an explanation."
  def prepare(%Explanation{} = explanation) do
    {:ok,
     %__MODULE__{
       authorization_id: make_id(),
       explanation_id: explanation.explanation_id,
       status: :prepared,
       lineage: [explanation.explanation_id]
     }}
  end

  def prepare(%{explanation_id: explanation_id}) when not is_nil(explanation_id) do
    {:ok,
     %__MODULE__{
       authorization_id: make_id(),
       explanation_id: explanation_id,
       status: :prepared,
       lineage: [explanation_id]
     }}
  end

  @doc "Move a prepared authorization to pending (awaiting human)."
  def request(%__MODULE__{status: :prepared} = auth) do
    {:ok, %{auth | status: :pending_authorization}}
  end

  def request(%__MODULE__{status: status}),
    do: {:error, {:illegal_transition, from: status, to: :pending_authorization}}

  @doc """
  Mint an AuthorizationGrant. This is the ONLY way to produce a valid grant, and
  it REQUIRES a human_id. There is no autonomous path to authorization.
  """
  def human_grant(%__MODULE__{status: :pending_authorization} = auth, human_id)
      when not is_nil(human_id) do
    human_grant(auth, human_id, [])
  end

  def human_grant(%__MODULE__{status: :pending_authorization}, nil),
    do: {:error, :human_id_required}

  def human_grant(%__MODULE__{status: status}, _human_id),
    do: {:error, {:illegal_transition, from: status, to: :granted}}

  @doc """
  Mint an AuthorizationGrant with an optional TTL and candidate content hash.
  The content hash binds the grant to the candidate's state at authorization
  time, preventing post-authorization mutation.

  The `:effect_descriptor` option binds the grant to the canonical identity of
  the consequential effect being authorized. Binding is enforced at mint time:
  an invalid descriptor prevents the grant from being minted.
  """
  def human_grant(%__MODULE__{status: :pending_authorization} = auth, human_id, opts)
      when not is_nil(human_id) do
    ttl = Keyword.get(opts, :ttl, @default_ttl)
    candidate_content_hash = Keyword.get(opts, :candidate_content_hash)

    with {:ok, effect_id} <- bind_effect(Keyword.get(opts, :effect_descriptor)) do
      {:ok,
       %{
         auth
         | status: :granted,
           human_id: human_id,
           decision: :granted,
           granted_at: System.system_time(:second),
           ttl: ttl,
           candidate_content_hash: candidate_content_hash,
           effect_id: effect_id,
           lineage: auth.lineage ++ [{:granted_by, human_id}]
       }}
    end
  end

  def human_grant(%__MODULE__{status: :pending_authorization}, nil, _opts),
    do: {:error, :human_id_required}

  def human_grant(%__MODULE__{status: status}, _human_id, _opts),
    do: {:error, {:illegal_transition, from: status, to: :granted}}

  @doc "Deny an authorization request. A reason is required for accountability."
  def human_deny(%__MODULE__{status: :pending_authorization} = auth, reason)
      when not is_nil(reason) do
    {:ok,
     %{
       auth
       | status: :denied,
         decision: :denied,
         reason: reason,
         lineage: auth.lineage ++ [{:denied_for, reason}]
     }}
  end

  def human_deny(%__MODULE__{status: :pending_authorization}, nil),
    do: {:error, :reason_required}

  def human_deny(%__MODULE__{status: status}, _reason),
    do: {:error, {:illegal_transition, from: status, to: :denied}}

  @doc """
  The check a deployer MUST perform. Returns true only if the grant is granted
  AND matches the explanation being deployed.
  """
  def valid_for?(%__MODULE__{status: :granted, explanation_id: eid}, explanation_id),
    do: eid == explanation_id

  def valid_for?(_auth, _explanation_id), do: false

  @doc """
  The deployer's effect-boundary check. A grant is valid for an effect only if
  it was minted bound to that exact canonical effect identity. A grant that
  names no effect can never authorize a specific effect.
  """
  def valid_for_effect?(%__MODULE__{status: :granted, effect_id: effect_id}, descriptor)
      when is_binary(effect_id) do
    EffectIdentity.verify(descriptor, effect_id) == :ok
  end

  def valid_for_effect?(_auth, _descriptor), do: false

  @doc """
  Returns true if the grant has expired. A grant is expired if it is granted and
  the current time exceeds granted_at + ttl.
  """
  def expired?(grant, now \\ nil)

  def expired?(%__MODULE__{status: :granted, granted_at: at, ttl: ttl}, now)
      when not is_nil(at) do
    now = now || System.system_time(:second)
    not is_nil(ttl) and now > at + ttl
  end

  def expired?(_auth, _now), do: false

  @doc """
  Transition a granted authorization to :expired. Only valid if the grant has
  actually expired (per expired?/2). This is the ONLY path to :expired.
  """
  def expire(auth, now \\ nil)

  def expire(%__MODULE__{status: :granted} = auth, now) do
    if expired?(auth, now) do
      {:ok, %{auth | status: :expired, lineage: auth.lineage ++ [:expired]}}
    else
      {:error, :not_yet_expired}
    end
  end

  def expire(%__MODULE__{status: status}, _now),
    do: {:error, {:illegal_transition, from: status, to: :expired}}

  defp bind_effect(nil), do: {:ok, nil}

  defp bind_effect(descriptor) when is_map(descriptor) do
    case EffectIdentity.effect_id(descriptor) do
      {:ok, effect_id} -> {:ok, effect_id}
      {:error, reason} -> {:error, {:invalid_effect_descriptor, reason}}
    end
  end

  defp bind_effect(_descriptor),
    do: {:error, {:invalid_effect_descriptor, :descriptor_must_be_a_map}}

  defp make_id, do: :"auth-#{System.unique_integer([:monotonic])}"
end
