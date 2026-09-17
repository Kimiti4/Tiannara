defmodule TiannaraRuntime.WorldModel.Composition.Engines.CompositionEngine do
  @moduledoc """
  Phase 17.6.9 — CompositionEngine (main orchestrator).
  Orchestrates the full composition pipeline: registration → resolution →
  sync derivation → graph construction → consistency → archaeology → math → certification.
  """

  alias TiannaraRuntime.WorldModel.Composition.Engines.InterfaceRegistry
  alias TiannaraRuntime.WorldModel.Composition.Engines.SharedVariableResolver
  alias TiannaraRuntime.WorldModel.Composition.Engines.SynchronizationEngine
  alias TiannaraRuntime.WorldModel.Composition.Engines.WorldGraphBuilder
  alias TiannaraRuntime.WorldModel.Composition.Engines.ConsistencyVerificationEngine
  alias TiannaraRuntime.WorldModel.Composition.Engines.CompositionArchaeology
  alias TiannaraRuntime.WorldModel.Composition.Engines.MathVerificationEngine
  alias TiannaraRuntime.WorldModel.Composition.ComposedWorldModel
  alias TiannaraRuntime.WorldModel.Composition.CompositionCertificate

  def compose(models, domain_definitions, opts \\ []) do
    model_ids = Enum.map(models, & &1.world_model_id)

    with {:ok, interfaces} <- InterfaceRegistry.register(models, domain_definitions),
         {:ok, interfaces} <- InterfaceRegistry.validate(interfaces, model_ids),
         {:ok, variables} <- SharedVariableResolver.resolve(interfaces),
         {:ok, sync_rules} <- SynchronizationEngine.derive(interfaces, variables),
         {:ok, graph} <- WorldGraphBuilder.build(models, interfaces, variables, sync_rules),
         {:ok, consistency} <- ConsistencyVerificationEngine.verify(graph),
         {:ok, evidence} <- CompositionArchaeology.record(%{composition_id: "pending", parent_model_ids: model_ids, interfaces: interfaces, sync_rules: sync_rules}),
         {:ok, proof_hash, _math_details} <- MathVerificationEngine.verify(graph) do
      certify_composition(models, interfaces, variables, sync_rules, graph, consistency, evidence, proof_hash, opts)
    else
      {:error, stage, reason} when is_atom(stage) ->
        {:error, stage, reason}
      {:error, reason} when is_binary(reason) ->
        {:error, :pipeline, reason}
      {:error, reason} when is_map(reason) ->
        {:error, :verification, reason}
    end
  end

  def certify_composition(models, interfaces, variables, sync_rules, graph, consistency, evidence, proof_hash, opts) do
    name = Keyword.get(opts, :name, "composed_model_#{DateTime.utc_now() |> DateTime.to_unix()}")

    model = %ComposedWorldModel{
      name: name,
      parent_model_ids: Enum.map(models, & &1.world_model_id),
      world_graph: graph,
      shared_variables: variables,
      sync_rules: sync_rules,
      interfaces: interfaces,
      evidence_roots: [evidence.evidence_id],
      archaeology_root: evidence.evidence_id,
      created_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    fingerprint = compute_fingerprint(model)
    model = %{model | replay_fingerprint: fingerprint}

    id_canonical = model |> Map.from_struct() |> Map.drop([:composition_id, :certificate, :replay_fingerprint]) |> deep_struct_to_map()
    model = %{model | composition_id: ComposedWorldModel.generate_id(id_canonical)}

    model_ids = Enum.map(models, & &1.world_model_id)

    checks = [
      check_models_certified(model_ids),
      check_interfaces_registered(interfaces),
      check_variables_resolved(variables),
      check_sync_rules_complete(sync_rules, interfaces),
      check_graph_acyclic(consistency),
      check_math_verified(proof_hash)
    ]

    overall = if Enum.all?(checks, &(&1.status == :pass)), do: :pass, else: :fail

    certificate = %CompositionCertificate{
      certificate_id: CompositionCertificate.generate_id(%{composition_id: model.composition_id}),
      composition_id: model.composition_id,
      checks: checks,
      overall: overall,
      issued_by: :composition_engine,
      issued_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    model = %{model | certificate: certificate}

    {:ok, model, certificate}
  end

  def replay(composition) do
    computed_fingerprint = compute_fingerprint(composition)
    stored_fingerprint = composition.replay_fingerprint

    if computed_fingerprint == stored_fingerprint do
      {:ok, :replay_verified, composition}
    else
      {:error, :replay_mismatch, %{expected: stored_fingerprint, got: computed_fingerprint}}
    end
  end

  defp check_models_certified(model_ids) do
    non_nil = Enum.reject(model_ids, &is_nil/1)
    count = length(non_nil)
    status = if count > 0, do: :pass, else: :fail
    %{check: :models_certified, status: status, model_count: count}
  end

  defp check_interfaces_registered(interfaces) do
    count = length(interfaces)
    all_valid = Enum.all?(interfaces, fn i -> i.interface_id != nil end)
    status = if count > 0 and all_valid, do: :pass, else: :fail
    %{check: :interfaces_registered, status: status, interface_count: count}
  end

  defp check_variables_resolved(variables) do
    count = length(variables)
    all_resolved = Enum.all?(variables, fn v -> v.variable_id != nil end)
    %{check: :variables_resolved, status: if(all_resolved, do: :pass, else: :fail), variable_count: count}
  end

  defp check_sync_rules_complete(sync_rules, interfaces) do
    sync_count = length(sync_rules)
    interface_vars = Enum.flat_map(interfaces, & &1.shared_variables)
    expected = length(Enum.uniq(interface_vars))
    coverage = if expected > 0, do: sync_count / expected, else: 1.0
    status = if coverage >= 1.0, do: :pass, else: :fail
    %{check: :sync_rules_complete, status: status, sync_count: sync_count, expected_variables: expected}
  end

  defp check_graph_acyclic(consistency) do
    acyclic_check = Enum.find(consistency.checks || [], fn c -> c.check == :acyclic end)
    status = if acyclic_check && acyclic_check.status == :pass, do: :pass, else: :fail
    %{check: :graph_acyclic, status: status}
  end

  defp check_math_verified(proof_hash) do
    status = if proof_hash && String.length(proof_hash) > 0, do: :pass, else: :fail
    %{check: :math_verified, status: status, proof_hash: proof_hash}
  end

  defp compute_fingerprint(composition) do
    excluded = [:composition_id, :archaeology_root, :created_at, :metadata, :replay_fingerprint, :certificate]

    canonical =
      composition
      |> Map.from_struct()
      |> Map.drop(excluded)
      |> deep_struct_to_map()

    "fp_" <>
      (:crypto.hash(:sha256, Jason.encode!(canonical))
       |> Base.encode16(case: :lower))
  end

  defp deep_struct_to_map(value) when is_struct(value) do
    value
    |> Map.from_struct()
    |> Enum.map(fn {k, v} -> {k, deep_struct_to_map(v)} end)
    |> Map.new()
  end

  defp deep_struct_to_map(value) when is_map(value) do
    Enum.map(value, fn {k, v} -> {k, deep_struct_to_map(v)} end) |> Map.new()
  end

  defp deep_struct_to_map(value) when is_list(value) do
    Enum.map(value, &deep_struct_to_map/1)
  end

  defp deep_struct_to_map(value), do: value
end
