defmodule Tiannara.ASC.Crucible.FailureSpecies do
  @moduledoc """
  Failure Species — explicit ecological species for failure diversity.

  Phase 5C.5 introduces canonical failure species to replace keyword-based
  classification inference. Each species has:
  - species_id: Unique identifier
  - species_signature: Canonical classification pattern
  - species_generator: Function to generate failures of this species
  - species_budget: Target percentage in ecological mix
  """

  defstruct [
    :species_id,
    :species_name,
    :species_signature,
    :domain,
    :budget_percentage,
    :generator_function,
    :description
  ]

  @typedoc "Failure species record"
  @type t :: %__MODULE__{
          species_id: atom(),
          species_name: String.t(),
          species_signature: String.t(),
          domain: atom(),
          budget_percentage: non_neg_integer(),
          generator_function: atom(),
          description: String.t()
        }

  def all_species do
    [
      %__MODULE__{
        species_id: :security,
        species_name: "Security Vulnerability",
        species_signature: "implementation:security:*",
        domain: :security,
        budget_percentage: 20,
        generator_function: :generate_security_failure,
        description: "Authentication, authorization, injection, credential failures"
      },
      %__MODULE__{
        species_id: :data,
        species_name: "Data Integrity Failure",
        species_signature: "implementation:data:*",
        domain: :data,
        budget_percentage: 15,
        generator_function: :generate_data_failure,
        description: "Schema mismatch, serialization, migration, constraint violations"
      },
      %__MODULE__{
        species_id: :concurrency,
        species_name: "Concurrency Control Failure",
        species_signature: "implementation:concurrency:*",
        domain: :concurrency,
        budget_percentage: 20,
        generator_function: :generate_concurrency_failure,
        description: "Race conditions, deadlocks, ordering violations, consistency failures"
      },
      %__MODULE__{
        species_id: :performance,
        species_name: "Performance Degradation",
        species_signature: "implementation:performance:*",
        domain: :performance,
        budget_percentage: 15,
        generator_function: :generate_performance_failure,
        description: "Latency violations, throughput issues, resource exhaustion"
      },
      %__MODULE__{
        species_id: :dependency,
        species_name: "Dependency Resolution Failure",
        species_signature: "implementation:dependency:*",
        domain: :dependency,
        budget_percentage: 10,
        generator_function: :generate_dependency_failure,
        description: "Service unavailable, version conflicts, connection refused"
      },
      %__MODULE__{
        species_id: :interface,
        species_name: "Interface Contract Violation",
        species_signature: "implementation:interface:*",
        domain: :interface,
        budget_percentage: 10,
        generator_function: :generate_interface_failure,
        description: "Protocol mismatch, schema breakage, compatibility failures"
      },
      %__MODULE__{
        species_id: :null_safety,
        species_name: "Null Safety Violation",
        species_signature: "implementation:null_safety:*",
        domain: :logic,
        budget_percentage: 5,
        generator_function: :generate_null_safety_failure,
        description: "Null reference exceptions, nil pointer dereferences"
      },
      %__MODULE__{
        species_id: :boundary,
        species_name: "Boundary Condition Failure",
        species_signature: "implementation:boundary:*",
        domain: :logic,
        budget_percentage: 5,
        generator_function: :generate_boundary_failure,
        description: "Edge case handling, min/max value violations"
      }
    ]
  end

  def get(species_id) do
    all_species() |> Enum.find(& &1.species_id == species_id)
  end

  def species_budgets do
    all_species()
    |> Enum.map(fn species -> {species.species_id, species.budget_percentage} end)
    |> Enum.into(%{})
  end

  def generate_failure(species_id) do
    species = get(species_id)

    if species do
      apply(__MODULE__, species.generator_function, [])
    else
      {:error, "Unknown species: #{inspect(species_id)}"}
    end
  end

  def generate_security_failure do
    failures = [
      %{type: :security, severity: :critical, description: "SQL injection vulnerability - authentication bypass possible", trigger: "sql_injection_attempt", subcategory: :sql_injection, variant_id: "variant_01"},
      %{type: :security, severity: :high, description: "Cross-site scripting - credential theft vector detected", trigger: "xss_attack_detected", subcategory: :xss, variant_id: "variant_02"},
      %{type: :security, severity: :critical, description: "Token validation failure - authorization bypass", trigger: "invalid_auth_token", subcategory: :token_validation, variant_id: "variant_03"},
      %{type: :security, severity: :high, description: "Credential handling failure - password leak detected", trigger: "credential_exposure", subcategory: :credential_handling, variant_id: "variant_04"},
      %{type: :security, severity: :medium, description: "Permission denied - authorization failure on protected resource", trigger: "unauthorized_access_attempt", subcategory: :authorization, variant_id: "variant_05"},
      %{type: :security, severity: :critical, description: "NoSqli vulnerability - object injection", trigger: "nosqli_attack_detected", subcategory: :nosql_injection, variant_id: "variant_06"},
      %{type: :security, severity: :high, description: "Path traversal - access outside allowed directory", trigger: "path_traversal_attempt", subcategory: :path_traversal, variant_id: "variant_07"},
      %{type: :security, severity: :medium, description: "Missing CSRF token - cross site request forgery", trigger: "missing_csrf_token", subcategory: :csrf, variant_id: "variant_08"},
      %{type: :security, severity: :critical, description: "Server side request forgery - internal network access", trigger: "ssrf_attempt", subcategory: :ssrf, variant_id: "variant_09"},
      %{type: :security, severity: :high, description: "Insecure direct object reference - unverified owner access", trigger: "idor_detected", subcategory: :idor, variant_id: "variant_10"}
    ]
    {:ok, Enum.random(failures)}
  end

  def generate_data_failure do
    failures = [
      %{type: :data, severity: :medium, description: "Schema mismatch - required field missing in deserialization", trigger: "schema_mismatch_missing_field", subcategory: :schema_mismatch, variant_id: "variant_01"},
      %{type: :data, severity: :low, description: "Serialization failure - data encoding error", trigger: "serialization_error", subcategory: :serialization, variant_id: "variant_02"},
      %{type: :data, severity: :medium, description: "Deserialization failure - schema evolution mismatch", trigger: "deserialization_schema_evolution", subcategory: :deserialization, variant_id: "variant_03"},
      %{type: :data, severity: :high, description: "Migration failure - database schema incompatibility", trigger: "migration_incompatibility", subcategory: :migration, variant_id: "variant_04"},
      %{type: :data, severity: :medium, description: "Null constraint violation - required field is null", trigger: "null_constraint_violation", subcategory: :constraint_violation, variant_id: "variant_05"},
      %{type: :data, severity: :high, description: "Unique constraint violation - duplicate key error", trigger: "unique_constraint_violation", subcategory: :constraint_violation, variant_id: "variant_06"},
      %{type: :data, severity: :medium, description: "Foreign key violation - referenced record missing", trigger: "foreign_key_violation", subcategory: :constraint_violation, variant_id: "variant_07"},
      %{type: :data, severity: :low, description: "Check constraint violation - data out of allowed bounds", trigger: "check_constraint_violation", subcategory: :constraint_violation, variant_id: "variant_08"},
      %{type: :data, severity: :high, description: "Data truncation error - value too long for column", trigger: "data_truncation_error", subcategory: :data_truncation, variant_id: "variant_09"},
      %{type: :data, severity: :medium, description: "Enum mapping error - invalid enum string", trigger: "enum_mapping_error", subcategory: :enum_mapping, variant_id: "variant_10"}
    ]
    {:ok, Enum.random(failures)}
  end

  def generate_concurrency_failure do
    failures = [
      %{type: :concurrency, severity: :high, description: "Race condition detected - concurrent access conflict", trigger: "race_condition_detected", subcategory: :race_condition, variant_id: "variant_01"},
      %{type: :concurrency, severity: :critical, description: "Deadlock detected - mutex timeout exceeded", trigger: "deadlock_mutex_timeout", subcategory: :deadlock, variant_id: "variant_02"},
      %{type: :concurrency, severity: :medium, description: "Ordering violation at boundary - event sequence broken", trigger: "ordering_violation_boundary", subcategory: :ordering_violation, variant_id: "variant_03"},
      %{type: :concurrency, severity: :medium, description: "Eventual consistency failure - state divergence detected", trigger: "eventual_consistency_divergence", subcategory: :consistency_failure, variant_id: "variant_04"},
      %{type: :concurrency, severity: :high, description: "Concurrent modification conflict - optimistic locking failure", trigger: "concurrent_modification_conflict", subcategory: :concurrent_modification, variant_id: "variant_05"},
      %{type: :concurrency, severity: :high, description: "Livelock detected - processes continuously changing state without progress", trigger: "livelock_detected", subcategory: :livelock, variant_id: "variant_06"},
      %{type: :concurrency, severity: :medium, description: "Starvation detected - low priority process unable to acquire lock", trigger: "resource_starvation", subcategory: :resource_starvation, variant_id: "variant_07"},
      %{type: :concurrency, severity: :high, description: "Phantom read - data changed during transaction", trigger: "phantom_read_anomaly", subcategory: :transaction_anomaly, variant_id: "variant_08"},
      %{type: :concurrency, severity: :medium, description: "Lost update - write overwritten by concurrent transaction", trigger: "lost_update_anomaly", subcategory: :transaction_anomaly, variant_id: "variant_09"},
      %{type: :concurrency, severity: :critical, description: "Actor mailbox overflow - process unable to keep up with messages", trigger: "mailbox_overflow", subcategory: :actor_overload, variant_id: "variant_10"}
    ]
    {:ok, Enum.random(failures)}
  end

  def generate_performance_failure do
    failures = [
      %{type: :performance, severity: :high, description: "Latency violation - response time exceeded threshold", trigger: "latency_threshold_exceeded", subcategory: :latency_violation, variant_id: "variant_01"},
      %{type: :performance, severity: :medium, description: "Throughput violation - resource contention detected", trigger: "throughput_contention", subcategory: :throughput_violation, variant_id: "variant_02"},
      %{type: :performance, severity: :critical, description: "Resource exhaustion - memory pressure critical", trigger: "memory_exhaustion_critical", subcategory: :resource_exhaustion, variant_id: "variant_03"},
      %{type: :performance, severity: :high, description: "CPU resource pressure - processing bottleneck", trigger: "cpu_bottleneck_detected", subcategory: :cpu_pressure, variant_id: "variant_04"},
      %{type: :performance, severity: :medium, description: "Connection pool exhausted - no available connections", trigger: "connection_pool_exhausted", subcategory: :pool_exhaustion, variant_id: "variant_05"},
      %{type: :performance, severity: :high, description: "Database query timeout - index missing or table scan", trigger: "db_query_timeout", subcategory: :query_performance, variant_id: "variant_06"},
      %{type: :performance, severity: :medium, description: "Cache stampede - multiple processes regenerating same cache key", trigger: "cache_stampede", subcategory: :caching_failure, variant_id: "variant_07"},
      %{type: :performance, severity: :high, description: "N+1 query problem - excessive database roundtrips", trigger: "n_plus_one_queries", subcategory: :query_performance, variant_id: "variant_08"},
      %{type: :performance, severity: :critical, description: "File descriptor exhaustion - cannot open new sockets", trigger: "file_descriptor_limit", subcategory: :resource_exhaustion, variant_id: "variant_09"},
      %{type: :performance, severity: :medium, description: "GC pause threshold exceeded - stop the world GC affecting latency", trigger: "gc_pause_exceeded", subcategory: :garbage_collection, variant_id: "variant_10"}
    ]
    {:ok, Enum.random(failures)}
  end

  def generate_dependency_failure do
    failures = [
      %{type: :dependency, severity: :high, description: "Dependency resolution failure - module not found", trigger: "dependency_module_not_found", subcategory: :resolution_failure, variant_id: "variant_01"},
      %{type: :dependency, severity: :medium, description: "Version conflict detected - incompatible dependency", trigger: "version_conflict_incompatible", subcategory: :version_conflict, variant_id: "variant_02"},
      %{type: :dependency, severity: :critical, description: "Service unavailable - connection refused", trigger: "service_unavailable_refused", subcategory: :service_unavailable, variant_id: "variant_03"},
      %{type: :dependency, severity: :high, description: "External API timeout - upstream service degraded", trigger: "external_api_timeout", subcategory: :api_timeout, variant_id: "variant_04"},
      %{type: :dependency, severity: :medium, description: "Circular dependency detected - import cycle", trigger: "circular_dependency_cycle", subcategory: :circular_dependency, variant_id: "variant_05"},
      %{type: :dependency, severity: :high, description: "DNS resolution failure - cannot resolve upstream host", trigger: "dns_resolution_failure", subcategory: :network_failure, variant_id: "variant_06"},
      %{type: :dependency, severity: :medium, description: "TLS certificate expired - upstream service verification failed", trigger: "tls_cert_expired", subcategory: :tls_failure, variant_id: "variant_07"},
      %{type: :dependency, severity: :high, description: "Circuit breaker open - fast failing upstream requests", trigger: "circuit_breaker_open", subcategory: :circuit_breaker, variant_id: "variant_08"},
      %{type: :dependency, severity: :medium, description: "Rate limit exceeded - upstream API throttling", trigger: "rate_limit_exceeded", subcategory: :api_throttling, variant_id: "variant_09"},
      %{type: :dependency, severity: :critical, description: "Transitive dependency conflict - multiple versions required", trigger: "transitive_dependency_conflict", subcategory: :resolution_failure, variant_id: "variant_10"}
    ]
    {:ok, Enum.random(failures)}
  end

  def generate_interface_failure do
    failures = [
      %{type: :interface, severity: :medium, description: "Contract violation - API compatibility failure", trigger: "contract_violation_compatibility", subcategory: :contract_violation, variant_id: "variant_01"},
      %{type: :interface, severity: :high, description: "Protocol mismatch - interface version incompatibility", trigger: "protocol_version_mismatch", subcategory: :protocol_mismatch, variant_id: "variant_02"},
      %{type: :interface, severity: :high, description: "Event schema breakage - message format changed", trigger: "event_schema_breakage", subcategory: :schema_breakage, variant_id: "variant_03"},
      %{type: :interface, severity: :medium, description: "Compatibility failure - breaking change detected", trigger: "breaking_change_detected", subcategory: :compatibility_failure, variant_id: "variant_04"},
      %{type: :interface, severity: :low, description: "Type contract violation - expected number got string", trigger: "type_contract_violation", subcategory: :type_mismatch, variant_id: "variant_05"},
      %{type: :interface, severity: :medium, description: "Missing HTTP header - required client metadata absent", trigger: "missing_required_header", subcategory: :contract_violation, variant_id: "variant_06"},
      %{type: :interface, severity: :high, description: "Unknown RPC method - client invoking deprecated function", trigger: "unknown_rpc_method", subcategory: :protocol_mismatch, variant_id: "variant_07"},
      %{type: :interface, severity: :medium, description: "Pagination contract broken - invalid cursor token", trigger: "invalid_pagination_cursor", subcategory: :compatibility_failure, variant_id: "variant_08"},
      %{type: :interface, severity: :high, description: "Webhook signature verification failed - invalid HMAC", trigger: "webhook_signature_failure", subcategory: :contract_violation, variant_id: "variant_09"},
      %{type: :interface, severity: :low, description: "Unexpected response format - client cannot parse XML", trigger: "unexpected_content_type", subcategory: :schema_breakage, variant_id: "variant_10"}
    ]
    {:ok, Enum.random(failures)}
  end

  def generate_null_safety_failure do
    failures = [
      %{type: :logic, severity: :medium, description: "Null reference exception - null safety violation", trigger: "null_reference_exception", subcategory: :null_reference, variant_id: "variant_01"},
      %{type: :logic, severity: :medium, description: "Nil pointer dereference - optional value not checked", trigger: "nil_pointer_dereference", subcategory: :nil_pointer, variant_id: "variant_02"},
      %{type: :logic, severity: :low, description: "Optional field accessed without guard - potential crash", trigger: "optional_field_unguarded", subcategory: :optional_access, variant_id: "variant_03"},
      %{type: :logic, severity: :high, description: "Null injected through map get - unexpected nil in list operations", trigger: "nil_in_list_comprehension", subcategory: :null_reference, variant_id: "variant_04"},
      %{type: :logic, severity: :medium, description: "Database returned null for non-null domain object", trigger: "db_null_mapping_error", subcategory: :nil_pointer, variant_id: "variant_05"},
      %{type: :logic, severity: :low, description: "Uninitialized variable access in closure", trigger: "uninitialized_closure_var", subcategory: :uninitialized, variant_id: "variant_06"},
      %{type: :logic, severity: :medium, description: "Config missing value results in nil parameter", trigger: "config_nil_parameter", subcategory: :null_reference, variant_id: "variant_07"},
      %{type: :logic, severity: :low, description: "JSON decoding produced nil for expected nested object", trigger: "json_nil_nested_object", subcategory: :optional_access, variant_id: "variant_08"},
      %{type: :logic, severity: :high, description: "Callback invoked with nil instead of context map", trigger: "nil_callback_context", subcategory: :nil_pointer, variant_id: "variant_09"},
      %{type: :logic, severity: :medium, description: "Pattern match failure on expected struct, got nil", trigger: "nil_pattern_match_failure", subcategory: :null_reference, variant_id: "variant_10"}
    ]
    {:ok, Enum.random(failures)}
  end

  def generate_boundary_failure do
    failures = [
      %{type: :logic, severity: :medium, description: "Boundary value not handled - edge case failure", trigger: "boundary_edge_case_failure", subcategory: :edge_case, variant_id: "variant_01"},
      %{type: :logic, severity: :low, description: "Min/max value violation - range check failed", trigger: "range_check_violation", subcategory: :range_violation, variant_id: "variant_02"},
      %{type: :logic, severity: :medium, description: "Empty collection operation - no elements to process", trigger: "empty_collection_operation", subcategory: :empty_collection, variant_id: "variant_03"},
      %{type: :logic, severity: :low, description: "Zero division attempt - mathematical boundary error", trigger: "zero_division_attempt", subcategory: :division_by_zero, variant_id: "variant_04"},
      %{type: :logic, severity: :medium, description: "Off by one error in array indexing", trigger: "off_by_one_index", subcategory: :edge_case, variant_id: "variant_05"},
      %{type: :logic, severity: :high, description: "Integer overflow on accumulator", trigger: "integer_overflow", subcategory: :numeric_overflow, variant_id: "variant_06"},
      %{type: :logic, severity: :medium, description: "String length exactly at database limit edge case", trigger: "string_length_exact_limit", subcategory: :range_violation, variant_id: "variant_07"},
      %{type: :logic, severity: :low, description: "Negative value passed to unsigned expected parameter", trigger: "negative_unsigned_param", subcategory: :edge_case, variant_id: "variant_08"},
      %{type: :logic, severity: :high, description: "Epoch wraparound boundary condition", trigger: "epoch_wraparound", subcategory: :numeric_overflow, variant_id: "variant_09"},
      %{type: :logic, severity: :medium, description: "List operation on exactly 1 item triggers scalar branch bug", trigger: "single_item_collection_bug", subcategory: :empty_collection, variant_id: "variant_10"}
    ]
    {:ok, Enum.random(failures)}
  end

  def calculate_species_fitness(species_id, transfer_successes, transfer_attempts) do
    if transfer_attempts > 0 do
      transfer_successes / transfer_attempts
    else
      0.0
    end
  end

  def species_signature_pattern(species_id) do
    case get(species_id) do
      nil -> "implementation:unknown:*"
      species -> species.species_signature
    end
  end
end
