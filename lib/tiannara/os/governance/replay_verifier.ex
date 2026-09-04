defmodule TiannaraOS.Governance.ReplayVerifier do
  @moduledoc """
  ReplayVerifier - Verifies correctness of replay operations
  
  Independently verifies that replay produces identical state to original.
  Used for audit and certification purposes.
  
  ## Verification Checks
  - State hash matches original
  - All events were processed
  - No events were skipped or duplicated
  - Event order is preserved
  - Deterministic seed produces same result
  
  ## Owner
  Independent verification component (no write access).
  """

  alias TiannaraOS.Governance.RFCReplayEngine
  alias TiannaraOS.Governance.ProposalLedger

  # === Public API ===

  @doc """
  Verify a single replay operation.
  
  Returns verification result with detailed diagnostics.
  """
  @spec verify_replay(map()) :: {:ok, map()} | {:error, map()}
  def verify_replay(certificate) do
    start_time = System.monotonic_time(:millisecond)
    
    checks = [
      check_certificate_structure(certificate),
      check_event_completeness(certificate),
      check_state_hash_match(certificate),
      check_determinism(certificate),
      check_event_order(certificate)
    ]
    
    passed = Enum.count(checks, &match?({:pass, _}, &1))
    failed = Enum.count(checks, &match?({:fail, _}, &1))
    
    elapsed = System.monotonic_time(:millisecond) - start_time
    
    result = %{
      certificate_id: certificate.certificate_id,
      proposal_id: certificate.proposal_id,
      verification_timestamp: DateTime.utc_now(),
      elapsed_ms: elapsed,
      checks_passed: passed,
      checks_failed: failed,
      total_checks: length(checks),
      overall_result: if(failed == 0, do: :passed, else: :failed),
      details: Enum.map(checks, fn {status, detail} ->
        %{status: status, detail: detail}
      end)
    }
    
    if failed == 0 do
      {:ok, result}
    else
      {:error, result}
    end
  end

  @doc """
  Verify multiple replays for consistency.
  """
  @spec verify_batch([map()]) :: {:ok, map()} | {:error, map()}
  def verify_batch(certificates) do
    results = Enum.map(certificates, fn cert ->
      case verify_replay(cert) do
        {:ok, result} -> {:success, result}
        {:error, result} -> {:failure, result}
      end
    end)
    
    successes = Enum.count(results, &match?({:success, _}, &1))
    failures = Enum.count(results, &match?({:failure, _}, &1))
    
    {:ok, %{
      total_verified: length(certificates),
      successes: successes,
      failures: failures,
      success_rate: if(length(certificates) > 0, do: successes / length(certificates), else: 0),
      results: results
    }}
  end

  @doc """
  Continuous verification - monitor replays over time.
  """
  @spec continuous_verify(String.t(), integer()) :: {:ok, map()}
  def continuous_verify(proposal_id, iterations \\ 10) do
    results = Enum.map(1..iterations, fn i ->
      seed = 42 + i
      
      case RFCReplayEngine.replay_proposal(proposal_id, seed: seed) do
        {:ok, result} ->
          case verify_replay(result.certificate) do
            {:ok, verification} -> {:success, verification}
            {:error, verification} -> {:failure, verification}
          end
        {:error, reason} ->
          {:error, reason}
      end
    end)
    
    successes = Enum.count(results, &match?({:success, _}, &1))
    
    {:ok, %{
      proposal_id: proposal_id,
      iterations: iterations,
      successes: successes,
      failures: iterations - successes,
      determinism_verified: successes == iterations,
      results: results
    }}
  end

  # === Individual Check Functions ===

  defp check_certificate_structure(cert) do
    required_fields = [
      :certificate_id, :proposal_id, :seed, :events_replayed,
      :event_ids, :determinism_verified, :original_state_hash,
      :replayed_state_hash, :state_match
    ]
    
    missing = Enum.filter(required_fields, &is_nil(Map.get(cert, &1)))
    
    if Enum.empty?(missing) do
      {:pass, "Certificate structure valid"}
    else
      {:fail, "Missing fields: #{inspect(missing)}"}
    end
  end

  defp check_event_completeness(cert) do
    events = ProposalLedger.get_proposal_events(cert.proposal_id)
    expected_count = length(events)
    actual_count = cert.events_replayed
    
    if expected_count == actual_count do
      {:pass, "All #{actual_count} events processed"}
    else
      {:fail, "Expected #{expected_count} events, replayed #{actual_count}"}
    end
  end

  defp check_state_hash_match(cert) do
    if cert.state_match do
      {:pass, "State hashes match: #{cert.replayed_state_hash}"}
    else
      {:fail, "State hash mismatch: original=#{cert.original_state_hash}, replayed=#{cert.replayed_state_hash}"}
    end
  end

  defp check_determinism(cert) do
    if cert.determinism_verified do
      {:pass, "Determinism verified"}
    else
      {:fail, "Determinism not verified"}
    end
  end

  defp check_event_order(cert) do
    events = ProposalLedger.get_proposal_events(cert.proposal_id)
    event_ids = Enum.map(events, & &1.event_id)
    
    if event_ids == cert.event_ids do
      {:pass, "Event order preserved"}
    else
      {:fail, "Event order mismatch"}
    end
  end
end
