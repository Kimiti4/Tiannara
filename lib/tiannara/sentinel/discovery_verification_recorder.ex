defmodule Tiannara.Sentinel.DiscoveryVerificationRecorder do
  @moduledoc """
  Binds discovery verification to immutable lineage, evidence archiving, and
  the ACL/OAVL validation boundary.

  This module is deliberately an orchestration boundary: it never invents
  persistence, domain findings, experiment outcomes, ACL results, or OAVL
  results. Every external provider is explicit and missing providers fail
  closed.
  """

  alias Tiannara.Sentinel.DiscoveryVerificationGraph
  alias Tiannara.Sentinel.DomainVerification
  alias Tiannara.Sentinel.TheoryValidationGate

  @type writer :: (map() -> {:ok, map()} | {:error, term()})
  @type validator :: (map() -> {:ok, map()} | {:error, term()})

  @spec verify_and_record(map(), [atom()], (map() -> {:ok, map()} | map() | {:error, term()}), map()) ::
          {:ok, map()} | {:error, term()}
  def verify_and_record(discovery, related_domains, verifier, opts)
      when is_map(discovery) and is_list(related_domains) and is_map(opts) do
    with {:ok, writer} <- required_fun(opts, :archive_writer),
         {:ok, acl} <- required_fun(opts, :acl_validator),
         {:ok, oavl} <- required_fun(opts, :oavl_validator),
         {:ok, verification} <- DomainVerification.verify(discovery, related_domains, verifier),
         {:ok, discovery_node} <- append(discovery_node(discovery), writer),
         {:ok, domain_nodes} <- append_domain_results(discovery, verification, discovery_node, writer),
         {:ok, correction_nodes} <- append_corrections(discovery, verification, domain_nodes, writer),
         {:ok, evidence} <- build_validation_evidence(discovery, verification, domain_nodes),
         {:ok, validation} <- TheoryValidationGate.validate(evidence, acl, oavl),
         {:ok, acl_node} <- append(validation_node(:acl_audit, discovery, validation, domain_nodes, :acl), writer),
         {:ok, oavl_node} <- append(validation_node(:oavl_audit, discovery, validation, [acl_node], :oavl), writer) do
      {:ok, %{
        discovery: discovery_node,
        verification: verification,
        domain_nodes: domain_nodes,
        correction_nodes: correction_nodes,
        validation: validation,
        acl_node: acl_node,
        oavl_node: oavl_node,
        evidence: evidence,
        certification_eligible: false
      }}
    end
  end

  @doc """
  Records a domain-proposed correction without mutating the parent discovery.
  """
  @spec record_correction(map(), map(), map(), writer()) :: {:ok, map()} | {:error, term()}
  def record_correction(discovery, domain_result, correction, writer)
      when is_map(discovery) and is_map(domain_result) and is_map(correction) do
    with {:ok, enhancement} <-
           Tiannara.Sentinel.DiscoveryEnhancement.propose(discovery, domain_result, correction),
         {:ok, node} <-
           append(%{
             kind: :domain_correction,
             discovery_id: Map.fetch!(discovery, :id),
             parent_ids: parent_ids(domain_result),
             provenance: provenance(discovery, :domain_correction),
             status: :proposed,
             artifact: enhancement
           }, writer) do
      {:ok, node}
    end
  end

  @doc """
  Records a controlled enhancement experiment, including failed experiments.
  """
  @spec record_experiment(map(), map(), map(), writer()) :: {:ok, map()} | {:error, term()}
  def record_experiment(discovery, enhancement, experiment_result, writer)
      when is_map(discovery) and is_map(enhancement) and is_map(experiment_result) do
    status =
      case Map.get(experiment_result, :status) do
        value when value in [:pass, :passed, :success, :successful] -> :successful_experiment
        value when value in [:fail, :failed, :counterexample, :rejected] -> :failed_experiment
        _ -> :inconclusive_experiment
      end

    append(%{
      kind: :enhancement_experiment,
      discovery_id: Map.fetch!(discovery, :id),
      parent_ids: existing_parent_ids(enhancement),
      provenance: provenance(discovery, :enhancement_experiment),
      status: status,
      artifact: %{
        enhancement_id: Map.get(enhancement, :enhancement_id),
        experiment: experiment_result,
        certification_eligible: false
      }
    }, writer)
  end

  @doc """
  Records a revised discovery only after callers provide the completed
  re-verification/ACL/OAVL evidence. No status is inferred from confidence.
  """
  @spec record_revision(map(), map(), map(), writer()) :: {:ok, map()} | {:error, term()}
  def record_revision(discovery, revision, validation, writer)
      when is_map(discovery) and is_map(revision) and is_map(validation) do
    if Map.get(validation, :acl_status) == :passed and
         Map.get(validation, :oavl_status) == :passed do
      append(%{
        kind: :discovery_revision,
        discovery_id: Map.fetch!(discovery, :id),
        parent_ids: existing_parent_ids(revision),
        provenance: provenance(discovery, :discovery_revision),
        status: :revised,
        artifact: %{
          revision: revision,
          validation: validation,
          certification_eligible: false
        }
      }, writer)
    else
      {:error, :revision_requires_acl_oavl_pass}
    end
  end

  defp discovery_node(discovery) do
    %{
      kind: :discovery,
      discovery_id: Map.fetch!(discovery, :id),
      provenance: provenance(discovery, :discovery),
      status: Map.get(discovery, :validation_status, :recorded),
      artifact: discovery
    }
  end

  defp append_domain_results(discovery, verification, parent, writer) do
    verification.results
    |> Enum.sort_by(fn {domain, _} -> Atom.to_string(domain) end)
    |> Enum.reduce_while({:ok, []}, fn {domain, result}, {:ok, acc} ->
      node = %{
        kind: :domain_verification,
        discovery_id: Map.fetch!(discovery, :id),
        parent_ids: [parent.node_id],
        provenance: provenance(discovery, :domain_verification, domain),
        status: Map.get(result, :status, :unknown),
        artifact: %{
          domain: domain,
          result: result,
          independent: Map.get(result, :independent, false),
          newly_discovered_dependencies: Map.get(result, :new_dependencies, [])
        }
      }

      case append(node, writer) do
        {:ok, stored} -> {:cont, {:ok, [stored | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, nodes} -> {:ok, Enum.reverse(nodes)}
      error -> error
    end
  end

  defp append_corrections(discovery, verification, domain_nodes, writer) do
    nodes_by_domain = Map.new(domain_nodes, fn node ->
      {get_in(node, [:artifact, :domain]), node}
    end)

    verification.enhancements
    |> Enum.reduce_while({:ok, []}, fn enhancement, {:ok, acc} ->
      domain = Map.get(enhancement, :domain)
      parent = Map.get(nodes_by_domain, domain)

      if parent do
        node = %{
          kind: :domain_correction,
          discovery_id: Map.fetch!(discovery, :id),
          parent_ids: [parent.node_id],
          provenance: provenance(discovery, :domain_correction, domain),
          status: :proposed,
          artifact: enhancement
        }

        case append(node, writer) do
          {:ok, stored} -> {:cont, {:ok, [stored | acc]}}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      else
        {:halt, {:error, {:correction_domain_not_recorded, domain}}}
      end
    end)
    |> case do
      {:ok, nodes} -> {:ok, Enum.reverse(nodes)}
      error -> error
    end
  end

  defp build_validation_evidence(discovery, verification, domain_nodes) do
    {:ok, %{
      evidence_id: "dve-" <> Integer.to_string(System.unique_integer([:positive])),
      theory_id: Map.fetch!(discovery, :id),
      outcome: verification.all_domains_passed,
      observations: Enum.map(domain_nodes, &Map.get(&1, :artifact)),
      counterevidence: collect_counterevidence(verification),
      assumptions: Map.get(discovery, :assumptions, []),
      provenance: provenance(discovery, :acl_oavl_validation),
      execution_mode: :real_execution,
      evidence_class: :real,
      domain_verification: verification
    }}
  end

  defp validation_node(kind, discovery, validation, parents, stage) do
    %{
      kind: kind,
      discovery_id: Map.fetch!(discovery, :id),
      parent_ids: Enum.map(parents, & &1.node_id),
      provenance: provenance(discovery, kind),
      status: Map.get(validation, :"#{stage}_status", :unknown),
      artifact: Map.take(validation, [
        :acl_status, :oavl_status, :acl_result, :oavl_result,
        :validation_stage, :certification_eligible
      ])
    }
  end

  defp append(node, writer) do
    DiscoveryVerificationGraph.append_with_archive(node, writer)
  end

  defp collect_counterevidence(verification) do
    verification.results
    |> Map.values()
    |> Enum.flat_map(&Map.get(&1, :counterevidence, []))
  end

  defp provenance(discovery, kind, domain \ nil) do
    %{
      source: :discovery_verification_recorder,
      artifact_kind: kind,
      discovery_id: Map.fetch!(discovery, :id),
      domain: domain,
      recorded_at: DateTime.utc_now()
    }
  end

  defp existing_parent_ids(map) do
    case Map.get(map, :parent_ids, []) do
      ids when is_list(ids) -> ids
      _ -> []
    end
  end

  defp parent_ids(result) do
    existing_parent_ids(result)
  end

  defp required_fun(opts, key) do
    case Map.get(opts, key) do
      fun when is_function(fun, 1) -> {:ok, fun}
      _ -> {:error, {key, :provider_unavailable}}
    end
  end
end
