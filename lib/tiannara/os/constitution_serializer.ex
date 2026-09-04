defmodule TiannaraOS.ConstitutionSerializer do
  @moduledoc """
  ConstitutionSerializer - Serializes constitutional components for manifest generation.

  This module creates canonical JSON representations of constitutional components
  and computes their SHA256 hashes for the Software Bill of Materials (SBOM).

  ## Constitutional Role

  ConstitutionSerializer ensures:
  1. Deterministic serialization (same input → same output)
  2. Content-derived hashing (hash from actual data, not metadata)
  3. Complete SBOM generation (all component hashes in one place)

  ## Usage

      # Build complete manifest
      manifest = ConstitutionSerializer.build_manifest()

      # Hash individual component
      hash = ConstitutionSerializer.hash_component(:scientific_capital_policy)
  """

  @type component_name :: :scientific_capital_definition | :scientific_capital_policy |
                          :scientific_capital_ledger | :constitutional_invariant_registry |
                          :structural_validation_gate | :constitutional_executor |
                          :metric_provenance_resolver

  @doc """
  Serialize a constitutional component to canonical JSON.

  Returns deterministic JSON representation suitable for hashing.

  ## Parameters

  - `component`: Component name atom

  ## Returns

  - Canonical JSON string

  ## Examples

      iex> json = ConstitutionSerializer.serialize(:scientific_capital_policy)
      iex> String.contains?(json, "coefficients")
      true
  """
  @spec serialize(component_name()) :: String.t()
  def serialize(:scientific_capital_definition) do
    alias TiannaraOS.ScientificCapitalDefinition

    definition_data = %{
      canonical_sources: ScientificCapitalDefinition.canonical_sources(),
      contribution_fields: ScientificCapitalDefinition.all_contribution_fields(),
      metadata: %{
        module: "TiannaraOS.ScientificCapitalDefinition",
        type: "definition"
      }
    }

    canonical_json(definition_data)
  end

  def serialize(:scientific_capital_policy) do
    alias TiannaraOS.ScientificCapitalPolicy

    policy = ScientificCapitalPolicy.load()

    policy_data = %{
      coefficients: extract_coefficients(policy),
      rules: extract_rules(policy),
      constraints: extract_constraints(policy),
      metadata: %{
        version: policy.version,
        module: "TiannaraOS.ScientificCapitalPolicy",
        type: "policy"
      }
    }

    canonical_json(policy_data)
  end

  def serialize(:scientific_capital_ledger) do
    alias TiannaraOS.Kernel.ScientificCapitalLedger

    ledger_state = ScientificCapitalLedger.get_state()

    ledger_data = %{
      transactions: Map.get(ledger_state, :transactions, []),
      balances: Map.get(ledger_state, :balances, %{}),
      metadata: %{
        module: "TiannaraOS.ScientificCapitalLedger",
        type: "ledger"
      }
    }

    canonical_json(ledger_data)
  end

  def serialize(:constitutional_invariant_registry) do
    alias TiannaraOS.Kernel.ConstitutionalInvariantRegistry

    invariants = ConstitutionalInvariantRegistry.list_invariants()

    registry_data = %{
      invariants: Enum.map(invariants, &extract_invariant/1),
      metadata: %{
        module: "TiannaraOS.ConstitutionalInvariantRegistry",
        type: "registry"
      }
    }

    canonical_json(registry_data)
  end

  def serialize(:structural_validation_gate) do
    # Minimal serialization - gate is stateless
    gate_data = %{
      invariants_checked: [
        :replay_determinism,
        :conservation_laws,
        :temporal_separation,
        :reward_leakage,
        :seed_independence,
        :metric_independence,
        :lifecycle_completeness,
        :rollback_completeness
      ],
      metadata: %{
        module: "TiannaraOS.StructuralValidationGate",
        type: "gate"
      }
    }

    canonical_json(gate_data)
  end

  def serialize(:constitutional_executor) do
    # Minimal serialization - executor flow description
    executor_data = %{
      execution_steps: [
        :build_manifest,
        :derive_fingerprint,
        :check_drift,
        :spawn_watchdog,
        :run_validation_gate,
        :execute_simulation,
        :generate_certificate,
        :record_in_journal
      ],
      metadata: %{
        module: "TiannaraOS.ConstitutionalExecutor",
        type: "executor"
      }
    }

    canonical_json(executor_data)
  end

  def serialize(:metric_provenance_resolver) do
    # Minimal serialization - resolver tracks metric lineage
    resolver_data = %{
      provenance_rules: [
        "All metrics have single owner",
        "No duplicate storage",
        "Complete lineage tracking",
        "Display-only calculations ephemeral"
      ],
      metadata: %{
        module: "TiannaraOS.MetricProvenanceResolver",
        type: "resolver"
      }
    }

    canonical_json(resolver_data)
  end

  @doc """
  Compute SHA256 hash of serialized component.

  Hash is content-derived - computed from actual specification data,
  not module metadata or BEAM bytecode.

  ## Parameters

  - `component`: Component name atom

  ## Returns

  - Lowercase hex-encoded SHA256 hash string

  ## Examples

      iex> hash = ConstitutionSerializer.hash_component(:scientific_capital_definition)
      iex> String.length(hash)
      64
  """
  @spec hash_component(component_name()) :: String.t()
  def hash_component(component) do
    serialized = serialize(component)

    :crypto.hash(:sha256, serialized)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Build complete ConstitutionManifest with all component hashes.

  Creates a software bill of materials (SBOM) equivalent for the constitution,
  containing hashes for all 7 constitutional components plus a combined hash.

  ## Returns

  - Map with all component hashes and combined hash

  ## Examples

      iex> manifest = ConstitutionSerializer.build_manifest()
      iex> Map.has_key?(manifest, :combined_hash)
      true
      iex> Map.has_key?(manifest, :definition_hash)
      true
  """
  @spec build_manifest() :: map()
  def build_manifest() do
    component_hashes = %{
      definition_hash: hash_component(:scientific_capital_definition),
      policy_hash: hash_component(:scientific_capital_policy),
      ledger_hash: hash_component(:scientific_capital_ledger),
      registry_hash: hash_component(:constitutional_invariant_registry),
      gate_hash: hash_component(:structural_validation_gate),
      executor_hash: hash_component(:constitutional_executor),
      resolver_hash: hash_component(:metric_provenance_resolver)
    }

    # Combined hash = SHA256(sorted component hash values)
    combined_input =
      component_hashes
      |> Map.values()
      |> Enum.sort()
      |> Enum.join("")

    combined_hash =
      :crypto.hash(:sha256, combined_input)
      |> Base.encode16(case: :lower)

    Map.put(component_hashes, :combined_hash, combined_hash)
  end

  # Private helper functions

  @spec canonical_json(map()) :: String.t()
  defp canonical_json(data) do
    Jason.encode!(data, pretty: false, maps: :strict)
  end

  @spec extract_coefficients(map()) :: map()
  defp extract_coefficients(policy) do
    Map.get(policy, :coefficients, %{})
  end

  @spec extract_rules(map()) :: list()
  defp extract_rules(policy) do
    Map.get(policy, :rules, [])
  end

  @spec extract_constraints(map()) :: list()
  defp extract_constraints(policy) do
    Map.get(policy, :constraints, [])
  end

  @spec extract_invariant(map()) :: map()
  defp extract_invariant(invariant) do
    %{
      id: Map.get(invariant, :id),
      title: Map.get(invariant, :title),
      severity: Map.get(invariant, :failure_severity)
    }
  end
end
