defmodule Tiannara.Sentinel.DiscoveryEvidenceRecorder do
  @moduledoc """
  Binds domain verification artifacts to the immutable discovery-verification
  graph and the append-only evidence archive.

  Persistence is always explicit: this module never pretends the in-memory graph
  or MathematicalEvidenceArchive is durable. The caller supplies the archive
  writer plus ACL/OAVL validators.
  """

  alias Tiannara.Sentinel.DiscoveryVerificationGraph
  alias Tiannara.Sentinel.TheoryValidationGate

  @type writer :: (map() -> {:ok, map()} | {:error, term()})
  @type validator :: (map() -> {:ok, map()} | {:error, term()})

  @spec record_verification(map(), writer(), validator(), validator()) ::
          {:ok, map()} | {:error, term()}
  def record_verification(verification, archive_writer, acl_validator, oavl_validator)
      when is_map(verification) do
    with :ok <- require_function(archive_writer, :archive_writer, 1),
         :ok <- require_function(acl_validator, :acl_validator, 1),
         :ok <- require_function(oavl_validator, :oavl_validator, 1),
         {:ok, discovery_node} <- append_node(%{
           kind: :discovery,
           discovery_id: Map.fetch!(verification, :discovery_id),
           status: :recorded,
           provenance: provenance(verification),
           artifact: Map.take(verification, [:discovery_id, :primary_domain])
         }, archive_writer),
         {:ok, domain_nodes} <-
           append_domain_results(verification, discovery_node, archive_writer),
         {:ok, audit} <- audit_verification(verification, domain_nodes, acl_validator, oavl_validator),
         {:ok, audit_nodes} <- append_audit_nodes(audit, discovery_node, domain_nodes, archive_writer) do
      {:ok, %{
        discovery: discovery_node,
        domain_results: domain_nodes,
        audit: audit,
        audit_nodes: audit_nodes,
        certification_eligible: false,
        epistemic_boundary: :recorded_domain_verification
      }}
    end
  end

  def record_verification(_, _, _, _), do: {:error, :invalid_verification_record}

  defp append_domain_results(verification, discovery_node, archive_writer) do
    results = Map.get(verification, :results, %{})

    Enum.reduce_while(results, {:ok, []}, fn {domain, result}, {:ok, acc} ->
      node = %{
        kind: :domain_verification,
        discovery_id: verification.discovery_id,
        parent_ids: [discovery_node.graph.node_id],
        status: Map.get(result, :status, :recorded),
        provenance: provenance(verification, domain),
        artifact: result
      }

      case append_node(node, archive_writer) do
        {:ok, stored} -> {:cont, {:ok, acc ++ [stored]}}
        {:error, reason} -> {:halt, {:error, {:domain_result_record_failed, domain, reason}}}
      end
    end)
  end

  defp audit_verification(verification, domain_nodes, acl_validator, oavl_validator) do
    evidence = %{
      evidence_id: "domain-verification:" <> to_string(verification.discovery_id),
      theory_id: verification.discovery_id,
      outcome: verification,
      observations: Enum.map(domain_nodes, & &1.graph.artifact),
      counterevidence: collect_counterevidence(verification),
      assumptions: Map.get(verification, :assumptions, []),
      provenance: provenance(verification),
      execution_mode: Map.get(verification, :execution_mode, :real_execution),
      evidence_class: Map.get(verification, :evidence_class, :real)
    }

    TheoryValidationGate.validate(evidence, acl_validator, oavl_validator)
  end

  defp append_audit_nodes(audit, discovery_node, domain_nodes, archive_writer) do
    parent_ids = [discovery_node.graph.node_id | Enum.map(domain_nodes, & &1.graph.node_id)]

    Enum.reduce([{:acl_audit, audit.acl_result}, {:oavl_audit, audit.oavl_result}],
      {:ok, []},
      fn {kind, artifact}, {:ok, acc} ->
        node = %{
          kind: kind,
          discovery_id: discovery_node.graph.discovery_id,
          parent_ids: parent_ids,
          status: Map.get(artifact, :status, :recorded),
          provenance: %{source: :theory_validation_gate, validation_stage: audit.validation_stage},
          artifact: artifact
        }

        case append_node(node, archive_writer) do
          {:ok, stored} -> {:cont, {:ok, acc ++ [stored]}}
          {:error, reason} -> {:halt, {:error, {kind, reason}}}
        end
      end)
  end

  defp append_node(node, archive_writer) do
    DiscoveryVerificationGraph.append_with_archive(node, archive_writer)
  end

  defp collect_counterevidence(verification) do
    verification
    |> Map.get(:results, %{})
    |> Enum.flat_map(fn {_domain, result} -> Map.get(result, :counterevidence, []) end)
  end

  defp provenance(verification, domain \\ nil) do
    base = %{
      source: :domain_verification,
      discovery_id: Map.get(verification, :discovery_id),
      primary_domain: Map.get(verification, :primary_domain)
    }

    if domain, do: Map.put(base, :verification_domain, domain), else: base
  end

  defp require_function(fun, _name, arity) when is_function(fun, arity), do: :ok
  defp require_function(_, name, arity), do: {:error, {name, :unavailable, arity}}
end
