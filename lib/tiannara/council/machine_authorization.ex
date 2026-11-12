defmodule Tiannara.Council.MachineAuthorization do
  @moduledoc """
  Machine-class authorization object (model M2; RL-565 / CP19.20).

  A machine grant is the decision payload wrapped with effect-binding state.
  It is **not** proof of Council issuance: the proof is a Council-signed
  `Tiannara.Council.DecisionReceipt` whose receipt ID is consumed atomically
  with this grant in `Tiannara.Omega.MintRegistry`.

  Fields:

    * `authorization_id` — server-generated machine grant identity
    * `authority_class` — always `:machine`
    * `authority_ref` — policy that produced the decision (advisory display)
    * `council_decision_ref` — canonical digest of the exact Council decision;
      the registry-anchored decision digest is the authority
    * `receipt_id` — Council receipt consumed by this grant
    * `scope_digest` — canonical operation/target scope digest issued by Council
    * `status` — `:granted` at mint; terminal transition is registry-recorded
    * `effect_id` — `nil` until one-shot binding
    * `granted_at`/`ttl` — grant lifetime
    * `decision_type` — operation class authorized
    * `content_hash` — local tamper-evidence pin (never the authority)
    * `decision` — the exact `%Council.Authorization{}` Council produced
    * `lineage` — append-only transition record

  `mint/2` is retained only as a fail-closed compatibility clause and always
  returns `{:error, :council_decision_proof_required}`. Machine authority
  requires `Council.decide/3` and `mint/3` with the returned receipt.
  """

  alias Tiannara.Council.{Authorization, DecisionDigest, DecisionReceipt, EmergencyState}
  alias Tiannara.Omega.{EffectIdentity, MintRegistry}

  defstruct [
    :authorization_id,
    :authority_class,
    :authority_ref,
    :council_decision_ref,
    :receipt_id,
    :scope_digest,
    :actor,
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
          receipt_id: String.t() | nil,
          scope_digest: String.t() | nil,
          actor: atom() | String.t() | nil,
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
  Fail-closed compatibility clause. A plain decision struct is not Council
  authority, so this clause never mints.
  """
  @spec mint(Authorization.t(), keyword()) :: {:error, :council_decision_proof_required}
  def mint(%Authorization{}, opts) when is_list(opts), do: {:error, :council_decision_proof_required}
  def mint(_decision, _opts), do: {:error, :council_decision_proof_required}

  @doc """
  Mints a machine grant only after verifying a genuine, unexpired, one-time
  Council receipt for the exact decision, type and scope. The receipt is
  consumed atomically with the grant record; a second mint from the same
  receipt is refused.

  Options: `:decision_type` (required atom), `:scope` (required exact
  operation/target map), `:ttl` (seconds, default #{@default_ttl_seconds}).
  """
  @spec mint(Authorization.t(), DecisionReceipt.t() | nil, keyword()) ::
          {:ok, t()} | {:error, term()}
  def mint(%Authorization{} = decision, %DecisionReceipt{} = receipt, opts) when is_list(opts) do
    with {:ok, decision_type} <- decision_type_from(opts),
         {:ok, scope} <- scope_from(opts),
         {:ok, ttl} <- ttl_from(opts) do
      do_mint(decision, receipt, decision_type, scope, ttl)
    end
  end

  def mint(%Authorization{}, nil, _opts), do: {:error, :council_decision_proof_required}
  def mint(%Authorization{}, _receipt, _opts), do: {:error, :council_decision_receipt_invalid}
  def mint(_decision, _receipt, _opts), do: {:error, :invalid_decision}

  defp do_mint(decision, receipt, decision_type, scope, ttl) do
    with :ok <- verify_receipt(receipt, decision, decision_type, scope),
         :ok <- check_not_expired(receipt),
         :ok <- check_emergency(),
         :ok <- check_permitted(decision),
         :ok <- check_receipt_status(receipt) do
      now = DateTime.utc_now()
      id = mint_id()

      grant = %__MODULE__{
        authorization_id: id,
        authority_class: :machine,
        authority_ref: decision.policy_applied,
        council_decision_ref: receipt.decision_digest,
        receipt_id: receipt.receipt_id,
        scope_digest: receipt.scope_digest,
        actor: receipt.actor,
        status: :granted,
        effect_id: nil,
        decision_type: decision_type,
        granted_at: now,
        ttl: ttl,
        decision: decision,
        lineage: [
          {:minted, now,
           %{
             decision_type: decision_type,
             receipt_id: receipt.receipt_id,
             decision_digest: receipt.decision_digest,
             scope_digest: receipt.scope_digest
           }}
        ]
      }

      grant = %__MODULE__{grant | content_hash: content_hash(grant)}

      case MintRegistry.issue_machine(grant, receipt, scope) do
        :ok -> {:ok, grant}
        :registry_unavailable -> {:error, :authorization_registry_unavailable}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp verify_receipt(receipt, decision, decision_type, scope) do
    with :ok <- DecisionReceipt.verify(receipt),
         :ok <- digest_matches(receipt, decision),
         :ok <- type_matches(receipt, decision_type),
         :ok <- scope_matches(receipt, scope),
         :ok <- policy_matches(receipt),
         :ok <- constitution_matches(receipt) do
      :ok
    end
  end

  defp digest_matches(receipt, decision) do
    if receipt.decision_digest == DecisionDigest.decision(decision) do
      :ok
    else
      {:error, :council_decision_digest_mismatch}
    end
  rescue
    _ -> {:error, :council_decision_digest_mismatch}
  end

  defp type_matches(receipt, decision_type) do
    if receipt.decision_type == decision_type do
      :ok
    else
      {:error, :council_decision_type_mismatch}
    end
  end

  defp scope_matches(receipt, scope) do
    if receipt.scope_digest == DecisionDigest.scope_digest(scope) do
      :ok
    else
      {:error, :council_scope_mismatch}
    end
  rescue
    _ -> {:error, :council_scope_mismatch}
  end

  defp policy_matches(receipt) do
    case Tiannara.Council.policy_version() do
      nil -> {:error, :council_receipt_unavailable}
      version when version == receipt.policy_version -> :ok
      _other -> {:error, :council_receipt_policy_mismatch}
    end
  end

  defp constitution_matches(receipt) do
    case Tiannara.Council.constitution_version() do
      nil -> {:error, :council_receipt_unavailable}
      version when version == receipt.constitution_version -> :ok
      _other -> {:error, :council_receipt_policy_mismatch}
    end
  end

  defp check_not_expired(receipt) do
    if DecisionReceipt.expired?(receipt),
      do: {:error, :council_decision_receipt_expired},
      else: :ok
  end

  defp check_emergency do
    if EmergencyState.active?(), do: {:error, :council_emergency_active}, else: :ok
  end

  defp check_permitted(decision) do
    if Authorization.permitted?(decision) or Authorization.conditional_grant?(decision),
      do: :ok,
      else: {:error, :decision_not_permitted}
  end

  defp check_receipt_status(receipt) do
    case MintRegistry.receipt_status(receipt.receipt_id) do
      :issued -> :ok
      :consumed -> {:error, :council_decision_receipt_consumed}
      :not_registered -> {:error, :council_decision_receipt_invalid}
      :registry_corrupt -> {:error, :registry_corrupt}
      :registry_unavailable -> {:error, :authorization_registry_unavailable}
    end
  end

  @doc """
  One-shot binding of a granted machine grant to an effect's canonical
  descriptor. The registry re-verifies the grant digest, decision digest,
  operation type and exact scope before recording the bound grant digest.
  """
  @spec bind_effect(t(), map()) :: {:ok, t()} | {:error, term()}
  def bind_effect(%__MODULE__{status: :granted, effect_id: nil} = auth, descriptor)
      when is_map(descriptor) do
    with {:ok, effect_id} <- effect_id(descriptor),
         {:ok, scope} <- descriptor_scope(descriptor) do
      case check_bind_emergency() do
        :ok -> do_bind(auth, descriptor, effect_id, scope)
        {:error, reason} -> {:error, reason}
      end
    end
  end

  def bind_effect(%__MODULE__{effect_id: existing}, _descriptor),
    do: {:error, {:already_bound, existing}}

  def bind_effect(%__MODULE__{status: status}, _descriptor),
    do: {:error, {:authorization_not_granted, status}}

  def bind_effect(_authorization, _descriptor), do: {:error, :invalid_authorization}

  defp effect_id(descriptor) do
    case EffectIdentity.effect_id(descriptor) do
      {:ok, effect_id} -> {:ok, effect_id}
      {:error, reason} -> {:error, {:invalid_descriptor, reason}}
    end
  end

  defp do_bind(auth, _descriptor, effect_id, scope) do
    case MintRegistry.bind_machine(auth, effect_id, scope) do
      :ok ->
        now = DateTime.utc_now()

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
  end

  defp descriptor_scope(descriptor) do
    scope = %{
      operation: Map.get(descriptor, :operation),
      target: Map.get(descriptor, :target)
    }

    if DecisionDigest.valid_scope?(scope) do
      {:ok, DecisionDigest.normalize_scope!(scope)}
    else
      {:error, {:invalid_descriptor, :invalid_scope}}
    end
  end

  defp check_bind_emergency do
    if EmergencyState.active?(), do: {:error, :council_emergency_active}, else: :ok
  end

  @doc "Sink-side expiry check against granted_at + ttl."
  @spec expired?(t()) :: boolean()
  def expired?(%__MODULE__{granted_at: %DateTime{} = granted_at, ttl: ttl})
      when is_integer(ttl),
      do: DateTime.diff(DateTime.utc_now(), granted_at) > ttl

  def expired?(_authorization), do: true

  @doc """
  Local tamper-evidence pin over the grant's mint-time core. This is not the
  authority: the registry-anchored grant/decision digests are.
  """
  @spec content_hash(t()) :: String.t()
  def content_hash(%__MODULE__{} = auth) do
    DecisionDigest.digest(:machine_grant_content, %{
      authorization_id: auth.authorization_id,
      authority_class: auth.authority_class,
      decision: auth.decision,
      decision_type: auth.decision_type,
      granted_at: auth.granted_at,
      ttl: auth.ttl,
      council_decision_ref: auth.council_decision_ref,
      receipt_id: auth.receipt_id,
      scope_digest: auth.scope_digest
    })
  end

  defp decision_type_from(opts) do
    case Keyword.fetch(opts, :decision_type) do
      {:ok, decision_type} when is_atom(decision_type) and not is_nil(decision_type) ->
        {:ok, decision_type}

      {:ok, other} ->
        {:error, {:invalid_decision_type, other}}

      :error ->
        {:error, :decision_type_required}
    end
  end

  defp scope_from(opts) do
    scope = Keyword.get(opts, :scope)

    if DecisionDigest.valid_scope?(scope) do
      {:ok, DecisionDigest.normalize_scope!(scope)}
    else
      {:error, :invalid_scope}
    end
  rescue
    _ -> {:error, :invalid_scope}
  end

  defp ttl_from(opts) do
    case Keyword.get(opts, :ttl, @default_ttl_seconds) do
      ttl when is_integer(ttl) -> {:ok, ttl}
      _ -> {:error, :invalid_ttl}
    end
  end

  defp mint_id do
    rand = :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
    :"mauth-#{System.unique_integer([:monotonic])}_#{rand}"
  end
end
