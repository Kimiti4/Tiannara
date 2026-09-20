defmodule Tiannara.Omega.DeploymentGateway do
  @moduledoc """
  The single mandatory path to candidate deployment.

  Deployment requires a certificate resolved from the canonical provenance
  issuance registry, non-empty lineage, a granted and unexpired
  AuthorizationGrant bound to the candidate, an authenticated human identity,
  and an unchanged candidate content hash.
  """

  alias Tiannara.Omega.PatchGenerator.Candidate
  alias Tiannara.Omega.HumanDelivery.{Authorization, AuthenticatedHumanIdentity}
  alias Tiannara.Omega.DeploymentGateway.DeploymentRecord
  alias Tiannara.Omega.DeploymentGateway.DeploymentRegistry
  alias TiannaraOS.Provenance.CertificateIssuance

  def deploy(candidate, certification, lineage, grant, identity, registry_path \ nil) do
    with_lock(registry_path, fn ->
      do_deploy(candidate, certification, lineage, grant, identity, registry_path)
    end)
  end

  defp do_deploy(candidate, certification, lineage, grant, identity, registry_path) do
    with :ok <- check_not_already_deployed(grant, registry_path),
         :ok <- check_candidate_status(candidate),
         {:ok, _certificate} <- check_certification(certification),
         :ok <- check_lineage(lineage),
         :ok <- check_grant_present(grant),
         :ok <- check_grant_matches(grant, candidate),
         :ok <- check_grant_unexpired(grant),
         :ok <- check_identity_authenticated(identity, grant),
         :ok <- check_candidate_unmutated(candidate, grant),
         {:ok, deployed_candidate} <- Candidate.deploy_transition(candidate) do
      record = %DeploymentRecord{
        deployment_id: make_id(),
        candidate_id: candidate.id,
        granted_by: identity.human_id,
        authorization_id: grant.authorization_id,
        deployed_at: System.system_time(:second),
        lineage: lineage,
        status: :deployed
      }

      if registry_path do
        :ok =
          DeploymentRegistry.record_deployment(
            grant.authorization_id,
            record.deployment_id,
            registry_path
          )
      end

      {:ok, record, deployed_candidate}
    end
  end

  @lock_table :deployment_gateway_locks

  defp with_lock(registry_path, fun) do
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
        try do
          :ets.new(@lock_table, [:named_table, :public, :set])
        rescue
          ArgumentError -> @lock_table
        end

      _ ->
        @lock_table
    end
  end

  defp claim(table, key, pid) do
    case :ets.insert_new(table, {key, pid}) do
      true ->
        :ok

      false ->
        case :ets.lookup(table, key) do
          [{^key, holder}] when is_pid(holder) and not Process.alive?(holder) ->
            :ets.delete(table, key)
            claim(table, key, pid)

          _ ->
            Process.sleep(1)
            claim(table, key, pid)
        end
    end
  end

  defp check_not_already_deployed(_grant, nil), do: :ok

  defp check_not_already_deployed(%Authorization{} = grant, registry_path) do
    if DeploymentRegistry.already_deployed?(grant.authorization_id, registry_path),
      do: {:error, :grant_already_used},
      else: :ok
  end

  defp check_not_already_deployed(_, _), do: :ok

  defp check_candidate_status(%Candidate{status: :approved}), do: :ok

  defp check_candidate_status(%Candidate{status: status}),
    do: {:error, {:candidate_not_approved, status}}

  defp check_certification(certificate_id) when is_binary(certificate_id) do
    case CertificateIssuance.resolve(certificate_id) do
      {:ok, %{"certificate_id" => ^certificate_id, "state" => state} = record}
      when state in ["VALID", "SUSPENDED"] ->
        {:ok, record}

      {:ok, record} ->
        {:error, {:certificate_not_deployable, record["state"]}}

      {:error, :unregistered} ->
        {:error, :certificate_unregistered}
    end
  end

  defp check_certification(_), do: {:error, :canonical_certificate_required}

  defp check_lineage(lineage) when is_list(lineage) and length(lineage) > 0, do: :ok
  defp check_lineage(_), do: {:error, :lineage_invalid}

  defp check_grant_present(%Authorization{}), do: :ok
  defp check_grant_present(_), do: {:error, :authorization_grant_required}

  defp check_grant_matches(%Authorization{} = grant, %Candidate{} = candidate) do
    if Authorization.valid_for?(grant, candidate.proposal_id),
      do: :ok,
      else: {:error, :grant_does_not_match_candidate}
  end

  defp check_grant_unexpired(%Authorization{} = grant) do
    if Authorization.expired?(grant), do: {:error, :grant_expired}, else: :ok
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
    if Map.get(grant, :candidate_content_hash) == content_hash(candidate),
      do: :ok,
      else: {:error, :candidate_mutated_after_authorization}
  end

  def content_hash(%Candidate{content: content}) do
    content
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp make_id, do: "deploy-#{System.unique_integer([:monotonic])}"
end