defmodule Tiannara.Omega.DeploymentGateway do
  @moduledoc """
  The SINGLE, MANDATORY path to deployment. There is NO alternate deployment
  API. Every deployment MUST pass through this gateway and satisfy ALL checks:

      Candidate
        ├── not already deployed (registry idempotency)?
        ├── certification valid?
        ├── lineage valid?
        ├── constitutional gates valid?
        ├── authorization grant present?
        ├── grant matches candidate/explanation?
        ├── grant unexpired?
        ├── candidate not mutated after authorization?
        ├── grant registered in the durable MintRegistry?
        ├── grant bound to this deployment's canonical effect identity?
        ├── MintRegistry binding agrees with the grant binding?
        ├── one-shot consumption CAS (exactly one deployment per grant)?
        ├── transition, record, registry entry
        ├── audit edge written (fail-closed)?
        ▼
      Deployment

  AUTHORITY BOUNDARY (constitutional): this gateway is the only code path that
  can transition a candidate to `:deployed`. Any attempt to deploy without a
  valid, matching, unexpired grant is rejected. This is the enforcement that
  makes "deployment requires human authorization" structurally true, not merely
  asserted by the HumanDelivery module.

  MANDATORY REGISTRY (model M7): the MintRegistry gates are unconditional —
  they do not depend on the optional `registry_path`. A grant that was never
  minted through the human path (no durable mint record), is not bound to this
  effect, or was already consumed, is refused even when the DeploymentRegistry
  replay file is absent. There is no nil-bypass.

  CONSUMPTION (model M4): `MintRegistry.consume/2` is an atomic granted ->
  consumed CAS performed before the state transition, so of N presentations
  of one grant exactly one deployment can commit (at-most-once).

  AUDIT (model M8): a successful deployment is appended to the Council
  AuditLog; if that append fails the gateway returns an error (fail-closed) —
  an unrecorded deployment is never reported as committed.

  Constitutional basis: augmentation clause, Safety and Reliability ("Capability
  must never outpace verification"), "Maintain audit trails", Security by
  design.
  """

  alias Tiannara.Council.AuditLog
  alias Tiannara.Omega.PatchGenerator.Candidate
  alias Tiannara.Omega.HumanDelivery.{Authorization, AuthenticatedHumanIdentity}
  alias Tiannara.Omega.DeploymentGateway.DeploymentRecord
  alias Tiannara.Omega.DeploymentGateway.DeploymentRegistry
  alias Tiannara.Omega.{EffectIdentity, MintRegistry}

  @authority_scope "omega:deployment_gateway"
  @operation "deploy"
  @principal "tiannara.deployment_gateway"
  @audit_action :deployment_committed

  @doc """
  The ONLY deployment function. Requires a candidate, a certification, a
  lineage record, and a valid AuthorizationGrant tied to an authenticated
  human identity. Rejects if any check fails.

  `registry_path` (optional) enables replay protection: a grant whose
  authorization_id has already been recorded as deployed is rejected, and a
  successful deployment is recorded in the registry. The MintRegistry gates
  (registration, binding, consumption) are enforced regardless of
  `registry_path`.
  """
  def deploy(candidate, certification, lineage, grant, identity, registry_path \\ nil) do
    # Serialize the whole check→commit critical section so two concurrent
    # deployments of the same grant cannot both pass all checks before either
    # records (at-most-one-deployment invariant).
    with_lock(registry_path, fn ->
      do_deploy(candidate, certification, lineage, grant, identity, registry_path)
    end)
  end

  defp do_deploy(candidate, certification, lineage, grant, identity, registry_path) do
    effect_identity = effect_identity(candidate)

    with :ok <- check_not_already_deployed(grant, effect_identity, registry_path),
         :ok <- check_candidate_status(candidate),
         :ok <- check_certification(certification),
         :ok <- check_lineage(lineage),
         :ok <- check_grant_present(grant),
         :ok <- check_grant_matches(grant, candidate),
         :ok <- check_grant_unexpired(grant),
         :ok <- check_identity_authenticated(identity, grant),
         :ok <- check_candidate_unmutated(candidate, grant),
         :ok <- check_registered(grant),
         :ok <- check_bound(grant),
         :ok <- check_effect_match(grant, effect_identity),
         :ok <- check_registry_binding(grant),
         :ok <- consume_once(grant, effect_identity),
         {:ok, deployed_candidate} <- Candidate.deploy_transition(candidate) do
      record = %DeploymentRecord{
        deployment_id: make_id(),
        candidate_id: candidate.id,
        granted_by: identity.human_id,
        authorization_id: grant.authorization_id,
        effect_identity: effect_identity,
        deployed_at: System.system_time(:second),
        lineage: lineage,
        status: :deployed
      }

      if registry_path,
        do:
          DeploymentRegistry.record_deployment(
            grant.authorization_id,
            effect_identity,
            record.deployment_id,
            registry_path
          )

      case record_audit(grant, effect_identity, record, candidate) do
        :ok -> {:ok, record, deployed_candidate}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  # --- enforcement checks -------------------------------------------------

  # At-most-one-deployment lock. `:global.trans/2` does not serialize on a
  # non-distributed node, so we use an atomic ETS mutex instead: the lock row
  # is claimed with insert_new (atomic), released in an `after` block.
  @lock_table :deployment_gateway_locks

  defp with_lock(registry_path, fun) when is_function(fun, 0) do
    table = ensure_lock_table()
    key = {:deploy, registry_path}
    claim(table, key, self())

    try do
      fun.()
    after
      :ets.delete(table, key)
    end
  end

  defp ensure_lock_table do
    case :ets.whereis(@lock_table) do
      :undefined ->
        # The table must survive its creator (a task that dies after the
        # deploy), so we give it a long-lived heir process.
        keeper =
          spawn(fn ->
            receive do
              :stop -> :ok
            end
          end)

        try do
          :ets.new(@lock_table, [:named_table, :public, :set, {:heir, keeper, nil}])
        rescue
          ArgumentError ->
            # Another process won the creation race; use its table.
            Process.sleep(1)
            ensure_lock_table()
        end

      tid ->
        tid
    end
  end

  defp claim(table, key, pid) do
    case :ets.insert_new(table, {key, pid}) do
      true ->
        :ok

      false ->
        # Steal the lock if the previous holder is dead; otherwise retry.
        case :ets.lookup(table, key) do
          [{^key, holder}] when is_pid(holder) ->
            if Process.alive?(holder) do
              Process.sleep(1)
              claim(table, key, pid)
            else
              :ets.delete(table, key)
              claim(table, key, pid)
            end

          _ ->
            Process.sleep(1)
            claim(table, key, pid)
        end
    end
  end

  defp check_not_already_deployed(_grant, _effect_identity, nil), do: :ok

  defp check_not_already_deployed(%Authorization{} = grant, effect_identity, registry_path) do
    case DeploymentRegistry.deployment_status(
           grant.authorization_id,
           effect_identity,
           registry_path
         ) do
      :not_deployed -> :ok
      :same_effect -> {:error, :grant_already_used}
      :different_effect -> {:error, :authorization_effect_mismatch}
    end
  end

  defp check_not_already_deployed(_, _effect_identity, _), do: :ok

  defp check_candidate_status(%Candidate{status: :approved}), do: :ok

  defp check_candidate_status(%Candidate{status: status}),
    do: {:error, {:candidate_not_approved, status}}

  defp check_certification(%{verdict: :certified} = certification) do
    # Evidence chain integrity: a certification whose evidence is explicitly
    # corrupted (or invalidly shaped) must not be trusted.
    case Map.get(certification, :evidence) do
      nil -> :ok
      :corrupted -> {:error, :evidence_corrupted}
      evidence when is_list(evidence) -> :ok
      _ -> {:error, :evidence_invalid}
    end
  end

  defp check_certification(_), do: {:error, :certification_invalid}

  defp check_lineage(lineage) when is_list(lineage) and length(lineage) > 0, do: :ok
  defp check_lineage(_), do: {:error, :lineage_invalid}

  defp check_grant_present(nil), do: {:error, :authorization_grant_required}
  defp check_grant_present(%Authorization{}), do: :ok
  defp check_grant_present(_), do: {:error, :authorization_grant_required}

  defp check_grant_matches(%Authorization{} = grant, %Candidate{} = candidate) do
    if Authorization.valid_for?(grant, candidate.proposal_id) do
      :ok
    else
      {:error, :grant_does_not_match_candidate}
    end
  end

  defp check_grant_unexpired(%Authorization{} = grant) do
    if Authorization.expired?(grant) do
      {:error, :grant_expired}
    else
      :ok
    end
  end

  defp check_identity_authenticated(
         %AuthenticatedHumanIdentity{} = identity,
         %Authorization{} = grant
       ) do
    cond do
      not AuthenticatedHumanIdentity.authenticated?(identity) ->
        {:error, :identity_not_authenticated}

      identity.human_id != grant.human_id ->
        {:error, :identity_does_not_match_grant}

      true ->
        :ok
    end
  end

  defp check_identity_authenticated(_, _), do: {:error, :identity_not_authenticated}

  defp check_candidate_unmutated(%Candidate{} = candidate, %Authorization{} = grant) do
    # The candidate's content hash at authorization time must match now.
    # This prevents mutation after authorization.
    if Map.get(grant, :candidate_content_hash) == content_hash(candidate) do
      :ok
    else
      {:error, :candidate_mutated_after_authorization}
    end
  end

  # --- mint-registry gates (M4/M7; unconditional — no nil-path bypass) ----

  defp check_registered(grant) do
    case MintRegistry.status(grant.authorization_id) do
      :granted -> :ok
      :consumed -> {:error, :already_consumed}
      :not_registered -> {:error, :authorization_not_registered}
      :registry_unavailable -> {:error, :authorization_registry_unavailable}
    end
  end

  defp check_bound(%Authorization{effect_id: effect_id}) when is_binary(effect_id), do: :ok
  defp check_bound(%Authorization{}), do: {:error, :effect_binding_required}

  defp check_effect_match(%Authorization{effect_id: effect_id}, effect_identity) do
    if effect_id == effect_identity do
      :ok
    else
      {:error, :effect_id_mismatch}
    end
  end

  defp check_registry_binding(%Authorization{} = grant) do
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

  defp consume_once(%Authorization{} = grant, effect_identity) do
    case MintRegistry.consume(grant.authorization_id, effect_identity) do
      :ok -> :ok
      {:error, :already_consumed} -> {:error, :already_consumed}
      {:error, :not_registered} -> {:error, :authorization_not_registered}
      {:error, :registry_binding_mismatch} -> {:error, :registry_binding_mismatch}
      :registry_unavailable -> {:error, :authorization_registry_unavailable}
    end
  end

  # --- audit edge (M8; fail-closed) ---------------------------------------

  defp record_audit(grant, effect_identity, record, candidate) do
    payload = %{
      effect_identity: effect_identity,
      authorization_id: grant.authorization_id,
      explanation_id: grant.explanation_id,
      actor: grant.human_id,
      deployment_id: record.deployment_id,
      candidate_id: candidate.id,
      proposal_id: candidate.proposal_id,
      deployed_at: record.deployed_at
    }

    try do
      case AuditLog.append(@audit_action, grant.human_id, payload) do
        {:ok, %{} = _entry} ->
          :ok

        {:error, reason} ->
          {:error, {:audit_not_recorded, reason, audit_detail(record)}}

        other ->
          {:error, {:audit_not_recorded, {:unexpected_audit_result, other}, audit_detail(record)}}
      end
    catch
      kind, reason -> {:error, {:audit_not_recorded, {kind, reason}, audit_detail(record)}}
    end
  end

  defp audit_detail(record) do
    %{
      deployed: true,
      deployment_id: record.deployment_id,
      authorization_id: record.authorization_id,
      effect_identity: record.effect_identity
    }
  end

  @doc "Compute a content hash for a candidate (for mutation detection)."
  def content_hash(%Candidate{content: content}) do
    content
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  @doc """
  The canonical semantic descriptor for a candidate-deployment effect
  (model M1). All values are canonically representable; identity is derived
  from this descriptor only.
  """
  def effect_descriptor(%Candidate{} = candidate) do
    %{
      principal: @principal,
      authority_scope: @authority_scope,
      operation: @operation,
      target: %{
        candidate_id: to_string(candidate.id),
        proposal_id: to_string(candidate.proposal_id)
      },
      parameters: %{candidate_content_hash: content_hash(candidate)},
      environment: %{},
      intent: %{kind: "candidate_deployment"},
      semantic_version: "1",
      identity_version: EffectIdentity.identity_version()
    }
  end

  @doc "Compute the semantic identity of a deployment effect (canonical, M1)."
  def effect_identity(%Candidate{} = candidate) do
    case EffectIdentity.effect_id(effect_descriptor(candidate)) do
      {:ok, effect_id} ->
        effect_id

      {:error, reason} ->
        raise ArgumentError, "invalid deployment effect descriptor: #{inspect(reason)}"
    end
  end

  defp make_id, do: :"deploy-#{System.unique_integer([:monotonic])}"
end
