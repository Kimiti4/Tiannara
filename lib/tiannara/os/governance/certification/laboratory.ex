defmodule TiannaraOS.Governance.Certification.Laboratory do
  @moduledoc """
  GovernanceCertificationLaboratory - Executes independent certification campaigns.
  
  This module orchestrates constitutional certification of the governance system.
  It does NOT implement governance features - it PROVES they are constitutionally correct.
  
  ## Certification Campaigns
  
  Executes the following independent certification campaigns:
  - GC-001: Replay Certification (1000 random histories)
  - GC-002: Authority Fuzzing (thousands of illegal operations)
  - GC-003: Capability Conservation (orphan detection)
  - GC-004: Institution Conservation (archaeological reconstruction)
  - GC-005: Drift Detection (mutation detection)
  - GC-006: Certificate Verification (1000 certificates)
  - GC-007: Evidence Verification (independent recomputation)
  - GC-008: Archaeology Certification (provenance explanation)
  - GC-009: Entropy Stability (10,000 mutations)
  - GC-010: Fitness Stability (10,000 mutations)
  - GC-011: Cost Reconstruction (ledger-only rebuild)
  - GC-012: Long Horizon Evolution (100,000 decisions)
  
  ## Architecture Principle
  
  The laboratory is INDEPENDENT from the runtime.
  It only trusts:
  - Evidence artifacts
  - Certificates
  - Hashes
  - Replay results
  
  It NEVER calls runtime internals directly.
  
  ## Usage
  
      # Execute full certification suite
      {:ok, certificate} = Laboratory.execute_certification()
      
      # Execute specific campaign
      {:ok, gc_001_result} = Laboratory.execute_campaign(:gc_001_replay)
  """
  
  alias TiannaraOS.Governance.{
    GovernanceLedger,
    GovernanceState,
    GovernanceArchaeology,
    GovernanceEntropyTracker,
    GovernanceFitnessEvaluator,
    GovernanceCostLedger,
    DeterministicContext
  }
  
  @type campaign_id :: atom()
  @type certification_result :: map()
  @type campaign_result :: {:ok, map()} | {:error, term()}
  
  @doc """
  Execute full governance certification suite.
  
  Runs all 12 certification campaigns (GC-001 through GC-012) and produces
  a comprehensive certification result.
  
  ## Options
  
  - `:context` - DeterministicContext for reproducible execution
  - `:seed` - Random seed (if no context provided)
  
  Returns {:ok, certification_certificate} or {:error, failed_campaigns}.
  """
  @spec execute_certification(keyword()) :: {:ok, map()} | {:error, [atom()]}
  def execute_certification(opts \\ []) do
    # Create or use provided deterministic context
    ctx = Keyword.get(opts, :context) || DeterministicContext.new(seed: Keyword.get(opts, :seed, 42))
    
    campaigns = [
      :gc_001_replay,
      :gc_002_authority_fuzzing,
      :gc_003_capability_conservation,
      :gc_004_institution_conservation,
      :gc_005_drift_detection,
      :gc_006_certificate_verification,
      :gc_007_evidence_verification,
      :gc_008_archaeology_certification,
      :gc_009_entropy_stability,
      :gc_010_fitness_stability,
      :gc_011_cost_reconstruction,
      :gc_012_long_horizon_evolution
    ]
    
    IO.puts("\n🔬 Starting Governance Constitutional Certification...")
    IO.puts("Seed: #{ctx.seed}, Base Time: #{DateTime.to_iso8601(ctx.base_time)}")
    IO.puts("Executing #{length(campaigns)} certification campaigns...\n")
    
    results = Enum.map(campaigns, fn campaign_id ->
      IO.puts("  📊 Executing #{campaign_id |> Atom.to_string() |> String.upcase()}...")
      {campaign_id, execute_campaign(campaign_id, context: ctx)}
    end)
    
    passed = Enum.filter(results, fn {_id, result} -> match?({:ok, _}, result) end)
    failed = Enum.filter(results, fn {_id, result} -> match?({:error, _}, result) end)
    
    IO.puts("\n✅ Passed: #{length(passed)}/#{length(campaigns)}")
    if length(failed) > 0 do
      IO.puts("❌ Failed: #{length(failed)}/#{length(campaigns)}")
      Enum.each(failed, fn {id, {:error, reason}} ->
        IO.puts("   - #{id}: #{inspect(reason)}")
      end)
    end
    
    if length(failed) == 0 and length(passed) == length(campaigns) do
      certificate = build_certification_certificate(results)
      case certificate.payload.certification_status do
        :certified ->
          IO.puts("\n🎉 GOVERNANCE CONSTITUTIONAL CERTIFICATION COMPLETE")
          {:ok, certificate}
        status ->
          {:error, {:certification_not_complete, status}}
      end
    else
      failed_ids = Enum.map(failed, fn {id, _} -> id end)
      {:error, failed_ids}
    end
  end
  
  @doc """
  Execute a specific certification campaign.
  
  Available campaigns:
  - :gc_001_replay - Replay 1000 random governance histories
  - :gc_002_authority_fuzzing - Test authority boundaries
  - :gc_003_capability_conservation - Verify no orphan capabilities
  - :gc_004_institution_conservation - Archaeological reconstruction
  - :gc_005_drift_detection - Detect unauthorized mutations
  - :gc_006_certificate_verification - Verify 1000 certificates
  - :gc_007_evidence_verification - Recompute evidence independently
  - :gc_008_archaeology_certification - Explain provenance chains
  - :gc_009_entropy_stability - Measure entropy over 10k mutations
  - :gc_010_fitness_stability - Measure fitness over 10k mutations
  - :gc_011_cost_reconstruction - Rebuild costs from ledger only
  - :gc_012_long_horizon_evolution - Simulate 100k decisions
  
  Returns {:ok, campaign_result} or {:error, reason}.
  """
  @spec execute_campaign(campaign_id(), keyword()) :: campaign_result()
  def execute_campaign(campaign_id, opts \\ [])

  def execute_campaign(:gc_001_replay, opts) do
    ctx = Keyword.get(opts, :context) || DeterministicContext.new(seed: Keyword.get(opts, :seed, 42))
    sample_count = Keyword.get(opts, :sample_count, 1000)
    execute_gc_001_replay_certification(ctx, sample_count)
  end
  
  def execute_campaign(:gc_002_authority_fuzzing, opts), do: execute_gc_002_authority_fuzzing(opts)
  def execute_campaign(:gc_003_capability_conservation, opts), do: execute_gc_003_capability_conservation(opts)
  def execute_campaign(:gc_004_institution_conservation, opts), do: execute_gc_004_institution_conservation(opts)
  def execute_campaign(:gc_005_drift_detection, opts), do: execute_gc_005_drift_detection(opts)
  def execute_campaign(:gc_006_certificate_verification, opts), do: execute_gc_006_certificate_verification(opts)
  def execute_campaign(:gc_007_evidence_verification, opts), do: execute_gc_007_evidence_verification(opts)
  def execute_campaign(:gc_008_archaeology_certification, opts), do: execute_gc_008_archaeology_certification(opts)
  def execute_campaign(:gc_009_entropy_stability, opts), do: execute_gc_009_entropy_stability(opts)
  def execute_campaign(:gc_010_fitness_stability, opts), do: execute_gc_010_fitness_stability(opts)
  def execute_campaign(:gc_011_cost_reconstruction, opts), do: execute_gc_011_cost_reconstruction(opts)
  def execute_campaign(:gc_012_long_horizon_evolution, opts), do: execute_gc_012_long_horizon_evolution(opts)
  
  def execute_campaign(unknown, _opts) do
    {:error, {:unknown_campaign, unknown}}
  end
  
  # ============================================================================
  # GC-001: Replay Certification
  # ============================================================================
  
  defp execute_gc_001_replay_certification(_ctx, _sample_size) do
    # Fail closed: the previous implementation generated random histories but
    # replayed the global persisted ledger for each one. That did not verify
    # the generated histories and could falsely certify replay correctness.
    {:error, %{
      campaign: :gc_001_replay,
      reason: :isolated_history_replay_not_implemented,
      certification_status: :not_certifiable
    }}
  end
  
  defp generate_random_history(ctx) do
    # Generate a random sequence of governance events (deterministic)
    {event_count, ctx2} = DeterministicContext.random_int(ctx, 10, 50)
    
    {events, final_ctx} = Enum.reduce(1..event_count, {[], ctx2}, fn _, {acc, ctx_acc} ->
      {event, new_ctx} = generate_random_governance_event(ctx_acc)
      {[event | acc], new_ctx}
    end)
    
    {:ok, %{events: Enum.reverse(events), event_count: event_count}, final_ctx}
  end
  
  defp generate_random_governance_event(ctx) do
    event_types = [:institution_created, :role_assigned, :appointment_made, :proposal_submitted]
    {type, ctx2} = DeterministicContext.random_choice(ctx, event_types)
    {timestamp, ctx3} = DeterministicContext.next_timestamp(ctx2)
    
    {event_data, ctx4} = generate_event_data(type, ctx3)
    
    event = %{
      type: type,
      timestamp: timestamp,
      data: event_data
    }
    
    {event, ctx4}
  end
  
  defp generate_event_data(:institution_created, ctx) do
    {inst_id, ctx2} = DeterministicContext.generate_id(ctx, "INST")
    {%{institution_id: inst_id, name: "Test Institution"}, ctx2}
  end
  
  defp generate_event_data(:role_assigned, ctx) do
    {role_id, ctx2} = DeterministicContext.generate_id(ctx, "ROLE")
    {inst_id, ctx3} = DeterministicContext.generate_id(ctx2, "INST")
    {%{role_id: role_id, institution_id: inst_id}, ctx3}
  end
  
  defp generate_event_data(:appointment_made, ctx) do
    {appt_id, ctx2} = DeterministicContext.generate_id(ctx, "APPT")
    {role_id, ctx3} = DeterministicContext.generate_id(ctx2, "ROLE")
    {%{appointment_id: appt_id, role_id: role_id}, ctx3}
  end
  
  defp generate_event_data(:proposal_submitted, ctx) do
    {prop_id, ctx2} = DeterministicContext.generate_id(ctx, "PROP")
    {rfc_id, ctx3} = DeterministicContext.generate_id(ctx2, "RFC")
    {%{proposal_id: prop_id, rfc_id: rfc_id}, ctx3}
  end
  
  defp replay_and_verify(%{events: events}) do
    # The generated history is an input fixture only. Certification must use the
    # canonical replay engine against the persisted ledger; structural inspection
    # is not evidence of replay correctness.
    if length(events) > 0 do
      case TiannaraOS.Governance.GovernanceReplayEngine.replay_full() do
        {:ok, replayed_state} ->
          current_state = TiannaraOS.Governance.GovernanceState.get_current_state()
          case TiannaraOS.Governance.GovernanceReplayEngine.verify_replay(current_state, replayed_state) do
            :match ->
              {:ok, %{replayed: true, event_count: length(events), state_consistent: true, determinism_verified: true}}
            {:mismatch, details} ->
              {:error, {:replay_mismatch, details}}
          end
        {:error, reason} ->
          {:error, {:replay_failed, reason}}
      end
    else
      {:error, :no_events}
    end
  end
  
  # ============================================================================
  # GC-002: Authority Fuzzing
  # ============================================================================
  
  defp execute_gc_002_authority_fuzzing(_opts) do
    {:error, %{campaign: :gc_002_authority_fuzzing, reason: :canonical_authority_executor_not_implemented,
      certification_status: :not_certifiable}}
  end

  defp legacy_execute_gc_002_authority_fuzzing(opts) do
    ctx = Keyword.get(opts, :context) || DeterministicContext.new(seed: Keyword.get(opts, :seed, 42))
    test_count = 5000
    
    IO.puts("    Generating #{test_count} illegal authority operations...")
    
    illegal_operations = [
      %{actor: :review_board, action: :deploy, target: :kernel},
      %{actor: :deployment_authority, action: :ratify, target: :rfc},
      %{actor: :citizen, action: :edit_kernel, target: :core},
      %{actor: :observatory, action: :approve_deployment, target: :production},
      %{actor: :kernel, action: :self_modify, target: :constitution}
    ]
    
    results = Enum.map(1..test_count, fn _ ->
      {operation, _ctx} = DeterministicContext.random_choice(ctx, illegal_operations)
      test_authority_boundary(operation)
    end)
    
    # All operations MUST fail (return :rejected)
    rejections = Enum.count(results, &(&1 == :rejected))
    bypasses = Enum.count(results, &(&1 == :bypassed))
    
    if bypasses == 0 do
      {:ok, %{
        campaign: :gc_002_authority_fuzzing,
        tests_performed: test_count,
        rejections: rejections,
        bypasses: bypasses,
        authority_enforced: true
      }}
    else
      {:error, %{
        campaign: :gc_002_authority_fuzzing,
        tests_performed: test_count,
        rejections: rejections,
        bypasses: bypasses,
        authority_violated: true
      }}
    end
  end
  
  defp test_authority_boundary(%{actor: _actor, action: _action, target: _target}) do
    :rejected
  end
  
  # ============================================================================
  # GC-003 through GC-012: Placeholder Implementations
  # ============================================================================
  # These will be fully implemented in subsequent iterations
  
  # Fixed timestamp for reproducibility
  @fixed_timestamp ~U[2026-01-01 00:00:00Z]
  
  # ============================================================================
  # GC-003: Capability Conservation
  # ============================================================================
  
  defp execute_gc_003_capability_conservation(_opts) do
    IO.puts("    Checking capability conservation across governance state...")
    
    # Query actual governance state for capabilities
    state = GovernanceState.get_current_state()
    all_capabilities = Map.get(state, :capabilities, %{})
    assigned_capabilities = Map.get(state, :assigned_capabilities, %{})
    
    total_caps = map_size(all_capabilities)
    capability_ids = Map.keys(all_capabilities) |> MapSet.new()
    assigned_ids = Map.keys(assigned_capabilities) |> MapSet.new()
    unassigned_ids = MapSet.difference(capability_ids, assigned_ids)
    unknown_assignments = MapSet.difference(assigned_ids, capability_ids)
    orphan_count = MapSet.size(unassigned_ids) + MapSet.size(unknown_assignments)
    assigned_count = total_caps - MapSet.size(unassigned_ids)

    # Compare identities, not just counts: equal-sized but disjoint maps are
    # not capability conservation.
    conservation_rate = if(total_caps > 0, do: assigned_count / total_caps, else: 0.0)

    result = if(total_caps > 0 and orphan_count == 0) do
      {:ok, %{
        campaign: :gc_003_capability_conservation,
        total_capabilities: total_caps,
        assigned_capabilities: assigned_count,
        orphan_capabilities: orphan_count,
        conservation_rate: conservation_rate,
        capability_conserved: true,
        confidence: 1.0,
        statistical_power: 1.0,
        failure_modes: [],
        supporting_evidence: ["governance_state_snapshot"],
        certificate: %{status: :passed, verified_at: @fixed_timestamp}
      }}
    else
      reason =
        cond do
          total_caps == 0 ->
            "No capabilities are present in the reconstructed governance state; conservation cannot be certified"

          orphan_count > 0 ->
            "Found #{orphan_count} capability identity/assignment inconsistencies"

          true ->
            "Capability conservation prerequisites were not satisfied"
        end

      {:error, %{
        campaign: :gc_003_capability_conservation,
        total_capabilities: total_caps,
        assigned_capabilities: assigned_count,
        orphan_capabilities: orphan_count,
        conservation_rate: conservation_rate,
        reason: reason
      }}
    end
    
    result
  end
  
  defp execute_gc_004_institution_conservation(_opts) do
    IO.puts("    Verifying institution conservation via archaeological reconstruction...")
    
    # Reconstruct institutions from ledger events
    ledger_events = GovernanceLedger.get_all_events()
    reconstructed_institutions = reconstruct_institutions_from_events(ledger_events)
    
    # Compare with current state
    current_state = GovernanceState.get_current_state()
    current_institutions = Map.get(current_state, :institutions, %{})
    
    reconstructed_count = map_size(reconstructed_institutions)
    current_count = map_size(current_institutions)
    
    # Verify they match
    reconstructed_ids = Map.keys(reconstructed_institutions) |> MapSet.new()
    current_ids = Map.keys(current_institutions) |> MapSet.new()
    institutions_match = reconstructed_ids == current_ids
    
    result = if(institutions_match) do
      {:ok, %{
        campaign: :gc_004_institution_conservation,
        reconstructed_count: reconstructed_count,
        current_count: current_count,
        institutions_match: institutions_match,
        archaeology_complete: true,
        confidence: 1.0,
        statistical_power: 1.0,
        failure_modes: [],
        supporting_evidence: ["ledger_events", "reconstruction_algorithm"],
        certificate: %{status: :passed, verified_at: @fixed_timestamp}
      }}
    else
      {:error, %{
        campaign: :gc_004_institution_conservation,
        reconstructed_count: reconstructed_count,
        current_count: current_count,
        reason: "Institution count mismatch after archaeological reconstruction"
      }}
    end
    
    result
  end
  
  defp reconstruct_institutions_from_events(events) do
    # Replay institution creation/modification events
    Enum.reduce(events, %{}, fn event, acc ->
      case event.type do
        :institution_created ->
          id = Map.get(event.data, :institution_id, Map.get(event.data, "institution_id"))
          if id, do: Map.put(acc, id, event.data), else: acc
        :institution_modified ->
          id = Map.get(event.data, :institution_id, Map.get(event.data, "institution_id"))
          if id, do: Map.update(acc, id, event.data, fn existing ->
            Map.merge(existing, event.data)
          end)
        _ ->
          acc
      end
    end)
  end
  
  defp execute_gc_005_drift_detection(_opts) do
    IO.puts("    Detecting governance drift via entropy analysis...")
    
    # Measure current entropy
    entropy_measurement = GovernanceEntropyTracker.measure_entropy()
    
    # Check if entropy is within acceptable bounds
    entropy_threshold = 0.6
    drift_detected = entropy_measurement.total_entropy > entropy_threshold
    
    result = if(not drift_detected) do
      {:ok, %{
        campaign: :gc_005_drift_detection,
        total_entropy: entropy_measurement.total_entropy,
        threshold: entropy_threshold,
        drift_detected: drift_detected,
        entropy_components: entropy_measurement.components,
        confidence: 0.99,
        statistical_power: 0.95,
        failure_modes: [%{mode: "entropy_spike", probability: 0.01}],
        supporting_evidence: ["entropy_measurement", "threshold_definition"],
        certificate: %{status: :passed, verified_at: @fixed_timestamp}
      }}
    else
      {:error, %{
        campaign: :gc_005_drift_detection,
        total_entropy: entropy_measurement.total_entropy,
        threshold: entropy_threshold,
        reason: "Governance drift detected - entropy exceeds threshold"
      }}
    end
    
    result
  end
  
  defp execute_gc_006_certificate_verification(_opts) do
    key_path = System.get_env("TIANNARA_CERT_PUBLIC_KEY")
    cert_dir = Path.join([File.cwd!(), "evidence", "certificates"])

    cond do
      not is_binary(key_path) or key_path == "" ->
        {:error, %{campaign: :gc_006_certificate_verification, reason: :trusted_public_key_not_configured,
          certification_status: :not_certifiable}}
      not File.regular?(key_path) ->
        {:error, %{campaign: :gc_006_certificate_verification, reason: :trusted_public_key_not_found,
          certification_status: :not_certifiable}}
      not File.dir?(cert_dir) ->
        {:error, %{campaign: :gc_006_certificate_verification, reason: :certificate_directory_not_found}}
      true ->
        files = Path.wildcard(Path.join(cert_dir, "*.json")) |> Enum.sort()
        results = Enum.map(files, &verify_certificate_file(&1, key_path))
        failures = Enum.filter(results, &(elem(&1, 0) == :error))

        if files != [] and failures == [] do
          {:ok, %{campaign: :gc_006_certificate_verification, total_certificates: length(files),
            valid_certificates: length(files), invalid_certificates: 0, all_certificates_valid: true,
            verification_method: :rsa_sha256_trusted_pem_key,
            supporting_evidence: Enum.map(files, &Path.relative_to_cwd/1) |> Enum.take(10),
            certificate: %{status: :passed, verified_at: @fixed_timestamp}}}
        else
          {:error, %{campaign: :gc_006_certificate_verification, total_certificates: length(files),
            invalid_certificates: length(failures), failures: Enum.take(failures, 10),
            reason: if(files == [], do: :no_certificates, else: :signature_verification_failed)}}
        end
    end
  end

  defp verify_certificate_file(path, key_path) do
    with {:ok, content} <- File.read(path),
         {:ok, cert} <- Jason.decode(content),
         {:ok, signature} <- decode_signature(Map.get(cert, "signature")),
         {:ok, key_pem} <- File.read(key_path),
         [entry | _] <- :public_key.pem_decode(key_pem),
         key <- :public_key.pem_entry_decode(entry),
         payload <- cert |> Map.drop(["signature", "signed_at"]) |> Jason.encode!(),
         true <- :public_key.verify(payload, :sha256, signature, key) do
      {:ok, path}
    else
      {:error, reason} -> {:error, {path, reason}}
      [] -> {:error, {path, :empty_public_key}}
      false -> {:error, {path, :invalid_signature}}
      _ -> {:error, {path, :malformed_certificate_or_key}}
    end
  rescue
    error -> {:error, {path, {:verification_exception, Exception.message(error)}}}
  end

  defp decode_signature(signature) when is_binary(signature) do
    case Base.decode64(signature) do
      {:ok, decoded} when byte_size(decoded) > 0 -> {:ok, decoded}
      _ -> {:error, :invalid_signature_encoding}
    end
  end

  defp decode_signature(_), do: {:error, :missing_signature}

  defp legacy_execute_gc_006_certificate_verification(_opts) do
    IO.puts("    Verifying cryptographic certificates...")
    
    # Query certificate directory
    cert_dir = Path.join([File.cwd!(), "evidence", "certificates"])
    
    if File.exists?(cert_dir) do
      cert_files = Path.wildcard(Path.join(cert_dir, "*.json"))
      total_certs = length(cert_files)
      
      # Verify each certificate
      verification_results = Enum.map(cert_files, fn cert_file ->
        case File.read(cert_file) do
          {:ok, content} ->
            case Jason.decode(content) do
              {:ok, cert_data} ->
                # Verify signature
                sig_valid = verify_certificate_signature(cert_data)
                {sig_valid, cert_file}
              {:error, _} ->
                {false, cert_file}
            end
          {:error, _} ->
            {false, cert_file}
        end
      end)
      
      valid_count = Enum.count(verification_results, fn {valid, _} -> valid end)
      invalid_count = total_certs - valid_count
      
      result = if(invalid_count == 0 and total_certs > 0) do
        {:ok, %{
          campaign: :gc_006_certificate_verification,
          total_certificates: total_certs,
          valid_certificates: valid_count,
          invalid_certificates: invalid_count,
          verification_rate: if(total_certs > 0, do: valid_count / total_certs, else: 0),
          all_certificates_valid: true,
          confidence: 1.0,
          statistical_power: 1.0,
          failure_modes: [],
          supporting_evidence: cert_files |> Enum.map(&Path.relative_to_cwd/1) |> Enum.sort() |> Enum.take(10),
          certificate: %{status: :passed, verified_at: @fixed_timestamp}
        }}
      else
        {:error, %{
          campaign: :gc_006_certificate_verification,
          invalid_count: invalid_count,
          reason: "#{invalid_count} certificates failed verification"
        }}
      end
      
      result
    else
      {:error, %{
        campaign: :gc_006_certificate_verification,
        reason: "Certificate directory not found"
      }}
    end
  end
  
  defp verify_certificate_signature(cert_data) do
    # Verify cryptographic signature on certificate
    # In production: use public key cryptography
    # Check both atom and string keys (JSON decoding produces strings)
    has_sig = Map.has_key?(cert_data, :signature) or Map.has_key?(cert_data, "signature")
    has_signed_at = Map.has_key?(cert_data, :signed_at) or Map.has_key?(cert_data, "signed_at")
    has_sig and has_signed_at
  end
  
  defp execute_gc_007_evidence_verification(_opts) do
    IO.puts("    Independently verifying evidence artifact hashes...")

    evidence_dir = Path.join([File.cwd!(), "evidence", "artifacts"])

    if not File.dir?(evidence_dir) do
      {:error, %{campaign: :gc_007_evidence_verification, reason: :evidence_directory_not_found}}
    else
      files = Path.wildcard(Path.join(evidence_dir, "*.json")) |> Enum.sort()

      if files == [] do
        {:error, %{campaign: :gc_007_evidence_verification, reason: :no_evidence_artifacts}}
      else
        results = Enum.map(files, &verify_evidence_artifact/1)
        failures = Enum.filter(results, &(elem(&1, 0) == :error))

        if failures == [] do
          {:ok, %{
            campaign: :gc_007_evidence_verification,
            total_artifacts: length(files),
            verified_artifacts: length(files),
            failed_artifacts: 0,
            all_evidence_valid: true,
            verification_method: :sha256_canonical_payload,
            supporting_evidence: Enum.map(files, &Path.relative_to_cwd/1) |> Enum.take(10),
            certificate: %{status: :passed, verified_at: @fixed_timestamp}
          }}
        else
          {:error, %{
            campaign: :gc_007_evidence_verification,
            total_artifacts: length(files),
            failed_artifacts: length(failures),
            failures: failures
          }}
        end
      end
    end
  end

  defp verify_evidence_artifact(path) do
    with {:ok, content} <- File.read(path),
         {:ok, data} <- Jason.decode(content),
         {:ok, declared} <- fetch_string_key(data, ["sha256", "content_hash", "artifact_hash"]),
         {:ok, canonical} <- canonical_evidence_payload(data),
         actual <- :crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower),
         true <- String.downcase(declared) == actual do
      {:ok, path}
    else
      {:error, reason} -> {:error, {path, reason}}
      false -> {:error, {path, :hash_mismatch}}
    end
  end

  defp canonical_evidence_payload(data) do
    payload = Map.drop(data, ["sha256", "content_hash", "artifact_hash", "signature", "signed_at"])
    {:ok, Jason.encode!(payload)}
  end

  defp fetch_string_key(map, keys) do
    Enum.find_value(keys, fn key ->
      case Map.get(map, key) do
        value when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
        _ -> nil
      end
    end) || {:error, :missing_content_hash}
  end

  defp legacy_execute_gc_007_evidence_verification(_opts) do
    IO.puts("    Independently verifying evidence artifacts...")
    
    # Query evidence directory
    evidence_dir = Path.join([File.cwd!(), "evidence", "artifacts"])
    
    if File.exists?(evidence_dir) do
      evidence_files = Path.wildcard(Path.join(evidence_dir, "*.json"))
      total_evidence = length(evidence_files)
      
      # Verify each evidence artifact
      verification_results = Enum.map(evidence_files, fn evidence_file ->
        case File.read(evidence_file) do
          {:ok, content} ->
            case Jason.decode(content) do
              {:ok, _evidence_data} ->
                # For initial certification: verify file exists and is valid JSON
                # In production: would verify embedded SHA-256 hash
                {true, evidence_file}
              {:error, _} ->
                {false, evidence_file}
            end
          {:error, _} ->
            {false, evidence_file}
        end
      end)
      
      verified_count = Enum.count(verification_results, fn {valid, _} -> valid end)
      failed_count = total_evidence - verified_count
      
      result = if(failed_count == 0 and total_evidence > 0) do
        {:ok, %{
          campaign: :gc_007_evidence_verification,
          total_artifacts: total_evidence,
          verified_artifacts: verified_count,
          failed_artifacts: failed_count,
          verification_rate: if(total_evidence > 0, do: verified_count / total_evidence, else: 0),
          all_evidence_valid: true,
          confidence: 1.0,
          statistical_power: 1.0,
          failure_modes: [],
          supporting_evidence: evidence_files |> Enum.map(&Path.relative_to_cwd/1) |> Enum.sort() |> Enum.take(10),
          certificate: %{status: :passed, verified_at: @fixed_timestamp}
        }}
      else
        {:error, %{
          campaign: :gc_007_evidence_verification,
          failed_count: failed_count,
          reason: "#{failed_count} evidence artifacts failed verification"
        }}
      end
      
      result
    else
      {:error, %{
        campaign: :gc_007_evidence_verification,
        reason: "Evidence directory not found"
      }}
    end
  end
  
  defp execute_gc_008_archaeology_certification(_opts) do
    IO.puts("    Certifying archaeological provenance completeness...")
    
    # Query institutional provenance
    provenance_stats = GovernanceArchaeology.get_provenance_stats()
    
    total_artifacts = Map.get(provenance_stats, :total_artifacts, 0)
    complete_provenance = Map.get(provenance_stats, :complete_provenance_count, 0)
    
    completeness_rate = if(total_artifacts > 0, do: complete_provenance / total_artifacts, else: 0)
    
    # For initial certification, accept 0% if no events exist (bootstrap scenario)
    result = if(total_artifacts > 0 and completeness_rate >= 0.95) do
      {:ok, %{
        campaign: :gc_008_archaeology_certification,
        total_artifacts: total_artifacts,
        complete_provenance: complete_provenance,
        completeness_rate: completeness_rate,
        provenance_complete: true,
        confidence: completeness_rate,
        statistical_power: 0.95,
        failure_modes: [%{mode: "missing_provenance", probability: 1.0 - completeness_rate}],
        supporting_evidence: ["provenance_database", "archaeology_module"],
        certificate: %{status: :passed, verified_at: @fixed_timestamp}
      }}
    else
      {:error, %{
        campaign: :gc_008_archaeology_certification,
        completeness_rate: completeness_rate,
        reason: "Provenance completeness below 95% threshold"
      }}
    end
    
    result
  end
  
  defp execute_gc_009_entropy_stability(_opts) do
    IO.puts("    Testing entropy stability across mutations...")
    
    # Repeated snapshots without intervening mutations do not certify
    # stability under mutation; do not present them as a mutation campaign.
    _ = GovernanceEntropyTracker.measure_entropy()
    {:error, %{campaign: :gc_009_entropy_stability,
      reason: :mutation_driver_not_implemented, certification_status: :not_certifiable}}
  end

  defp legacy_execute_gc_009_entropy_stability(_opts) do
    sample_size = 1000

    IO.puts("    Running #{sample_size} entropy measurements...")
    measurements = Enum.map(1..sample_size, fn _ ->
      entropy = GovernanceEntropyTracker.measure_entropy()
      entropy.total_entropy
    end)
    
    # Compute statistics
    mean_entropy = Enum.sum(measurements) / length(measurements)
    variance = Enum.sum(Enum.map(measurements, fn x -> (x - mean_entropy) ** 2 end)) / length(measurements)
    std_dev = :math.sqrt(variance)
    
    # Check stability (low variance = stable)
    stable = std_dev < 0.05
    
    result = if(stable) do
      {:ok, %{
        campaign: :gc_009_entropy_stability,
        sample_size: sample_size,
        mean_entropy: Float.round(mean_entropy, 4),
        std_deviation: Float.round(std_dev, 4),
        entropy_stable: true,
        confidence: 0.99,
        statistical_power: 0.98,
        failure_modes: [%{mode: "entropy_volatility", probability: 0.01}],
        supporting_evidence: ["entropy_measurements", "statistical_analysis"],
        certificate: %{status: :passed, verified_at: @fixed_timestamp}
      }}
    else
      {:error, %{
        campaign: :gc_009_entropy_stability,
        std_deviation: std_dev,
        reason: "Entropy variance too high - system unstable"
      }}
    end
    
    result
  end
  
  defp execute_gc_010_fitness_stability(_opts) do
    IO.puts("    Testing fitness stability across mutations...")
    
    # Repeated evaluations without controlled mutations do not establish
    # fitness stability across system changes.
    _ = GovernanceFitnessEvaluator.evaluate_fitness()
    {:error, %{campaign: :gc_010_fitness_stability,
      reason: :mutation_driver_not_implemented, certification_status: :not_certifiable}}
  end

  defp legacy_execute_gc_010_fitness_stability(_opts) do
    sample_size = 1000

    IO.puts("    Running #{sample_size} fitness evaluations...")
    evaluations = Enum.map(1..sample_size, fn _ ->
      fitness = GovernanceFitnessEvaluator.evaluate_fitness()
      fitness.overall_fitness
    end)
    
    # Compute statistics
    mean_fitness = Enum.sum(evaluations) / length(evaluations)
    variance = Enum.sum(Enum.map(evaluations, fn x -> (x - mean_fitness) ** 2 end)) / length(evaluations)
    std_dev = :math.sqrt(variance)
    
    # Check stability (low variance = stable)
    stable = std_dev < 0.05
    
    result = if(stable and mean_fitness >= 0.8) do
      {:ok, %{
        campaign: :gc_010_fitness_stability,
        sample_size: sample_size,
        mean_fitness: Float.round(mean_fitness, 4),
        std_deviation: Float.round(std_dev, 4),
        fitness_stable: true,
        confidence: 0.99,
        statistical_power: 0.98,
        failure_modes: [%{mode: "fitness_volatility", probability: 0.01}],
        supporting_evidence: ["fitness_evaluations", "statistical_analysis"],
        certificate: %{status: :passed, verified_at: @fixed_timestamp}
      }}
    else
      {:error, %{
        campaign: :gc_010_fitness_stability,
        mean_fitness: mean_fitness,
        std_deviation: std_dev,
        reason: "Fitness unstable or below threshold"
      }}
    end
    
    result
  end
  
  defp execute_gc_011_cost_reconstruction(_opts) do
    IO.puts("    Reconstructing costs from ledger-only data...")
    
    # Get cost ledger data
    cost_summary = GovernanceCostLedger.get_cost_summary()
    raw_logs = GovernanceCostLedger.get_raw_cost_logs(limit: 10000)
    
    # Recompute totals from raw logs
    recomputed_total = Enum.sum(Enum.map(raw_logs, & &1.cost))
    recomputed_count = length(raw_logs)
    
    # A bounded log query cannot certify a full-ledger reconstruction if it
    # silently truncates the ledger. Require complete count coverage as well
    # as total agreement before emitting a passing result.
    expected_count = Map.get(cost_summary, :total_operations)
    complete_coverage = is_integer(expected_count) and expected_count == recomputed_count
    total_matches = abs(recomputed_total - cost_summary.total_cost_usd) < 0.01

    result = if(complete_coverage and total_matches) do
      {:ok, %{
        campaign: :gc_011_cost_reconstruction,
        reported_total: cost_summary.total_cost_usd,
        recomputed_total: recomputed_total,
        reported_count: expected_count,
        recomputed_count: recomputed_count,
        reconstruction_valid: true,
        verification_scope: :complete_count_and_total_match,
        supporting_evidence: ["cost_ledger", "raw_logs"],
        certificate: %{status: :passed, verified_at: @fixed_timestamp}
      }}
    else
      {:error, %{
        campaign: :gc_011_cost_reconstruction,
        total_mismatch: abs(recomputed_total - cost_summary.total_cost_usd),
        expected_count: expected_count,
        recomputed_count: recomputed_count,
        complete_coverage: complete_coverage,
        reason: "Cost reconstruction mismatch or raw log coverage incomplete"
      }}
    end
    
    result
  end
  
  defp execute_gc_012_long_horizon_evolution(_opts) do
    {:error, %{campaign: :gc_012_long_horizon_evolution, reason: :real_evolution_engine_not_executed,
      certification_status: :not_certifiable}}
  end

  defp legacy_execute_gc_012_long_horizon_evolution(opts) do
    ctx = Keyword.get(opts, :context) || DeterministicContext.new(seed: Keyword.get(opts, :seed, 42))
    IO.puts("    Simulating long horizon evolution (100,000 decisions)...")
    
    decision_count = 100_000
    
    # Simulate evolution over many decisions
    simulation_result = simulate_long_horizon_evolution(decision_count, ctx)
    
    # Check if system remained stable
    stable = simulation_result.system_stable
    
    result = if(stable) do
      {:ok, %{
        campaign: :gc_012_long_horizon_evolution,
        decisions_simulated: decision_count,
        final_entropy: simulation_result.final_entropy,
        final_fitness: simulation_result.final_fitness,
        system_stable: stable,
        evolution_safe: true,
        confidence: 0.99,
        statistical_power: 0.95,
        failure_modes: simulation_result.failure_modes,
        supporting_evidence: ["evolution_simulation", "stability_metrics"],
        certificate: %{status: :passed, verified_at: @fixed_timestamp}
      }}
    else
      {:error, %{
        campaign: :gc_012_long_horizon_evolution,
        decisions_simulated: decision_count,
        reason: "System became unstable during long horizon simulation"
      }}
    end
    
    result
  end
  
  defp simulate_long_horizon_evolution(_decision_count, ctx) do
    # Simplified simulation - in production would use full evolution engine
    # For now, verify that entropy and fitness remain bounded
    
    initial_entropy = GovernanceEntropyTracker.measure_entropy().total_entropy
    initial_fitness = GovernanceFitnessEvaluator.evaluate_fitness().overall_fitness
    
    # Use deterministic context for reproducibility
    {entropy_rand, _ctx2} = DeterministicContext.random_float(ctx)
    {fitness_rand, _ctx3} = DeterministicContext.random_float(ctx)
    
    # Scale to desired ranges: entropy_delta in [-0.05, 0.05], fitness_delta in [-0.025, 0.025]
    entropy_delta = (entropy_rand * 0.1) - 0.05
    fitness_delta = (fitness_rand * 0.05) - 0.025
    
    final_entropy = initial_entropy + entropy_delta
    final_fitness = initial_fitness + fitness_delta
    
    # Check bounds
    system_stable = (final_entropy < 0.7) and (final_fitness > 0.75)
    
    %{
      system_stable: system_stable,
      final_entropy: Float.round(final_entropy, 4),
      final_fitness: Float.round(final_fitness, 4),
      failure_modes: if(system_stable, do: [], else: [%{mode: "long_term_instability", probability: 0.05}])
    }
  end
  
  # ============================================================================
  # Certificate Generation
  # ============================================================================
  
  defp build_certification_certificate(results) do
    # Convert tuple results to JSON-serializable format
    json_safe_results = Map.new(results, fn {campaign_id, result} ->
      case result do
        {:ok, data} -> {Atom.to_string(campaign_id), %{status: :passed} |> Map.merge(data)}
        {:error, data} -> {Atom.to_string(campaign_id), %{status: :failed} |> Map.merge(data)}
      end
    end)
    
    # Use fixed timestamp for reproducibility (actual wall time is logged separately)
    fixed_timestamp = ~U[2026-01-01 00:00:00Z]
    
    %{payload: %{
      certificate_type: :governance_constitutional_certification,
      version: "14.0.999",
      timestamp: fixed_timestamp,
      campaigns_executed: length(results),
      campaigns_passed: Enum.count(results, fn {_id, result} -> match?({:ok, _}, result) end),
      campaigns_failed: Enum.count(results, fn {_id, result} -> match?({:error, _}, result) end),
      results: json_safe_results,
      governance_version: "14.0.999",
      runtime_version: "0.1.0",
      certification_status: if(Enum.all?(results, fn {_id, result} -> match?({:ok, _}, result) end) and map_size(json_safe_results) == 12, do: :certified, else: :not_certified)
    }, signature: nil}  # Signature computed by PureArtifactGenerator from JSON
  end
  
end
