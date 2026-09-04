defmodule TiannaraOS.Governance.Validation.Adapters.ReplayAdapter do
  @moduledoc """
  ReplayAdapter - Provides deterministic replay capabilities for governance state.

  This adapter implements the ReplayAdapterBehaviour contract, enabling
  campaigns to verify that governance state can be reconstructed from the ledger.

  Responsibilities:
  - Execute deterministic replay of governance history
  - Compare replayed state against captured state
  - Verify field-by-field equality
  - Generate replay certificates

  ## Archaeology

  - **purpose**: Enable deterministic replay validation of governance state
  - **introduced_in**: Phase 14.0.97
  - **depends_on**: TiannaraOS.Governance.GovernanceLedger, TiannaraOS.Governance.GovernanceReplayEngine
  - **constitution_reference**: GOVERNANCE_VALIDATION_CONSTITUTION.md Section 8.3
  - **owner**: Governance Council

  ## Usage

      {:ok, certificate} = ReplayAdapter.execute(%{operation: :replay, count: 1000})
      {:ok, integrity} = ReplayAdapter.measure(:replay_integrity)
  """

  @behaviour TiannaraOS.Governance.Validation.Adapter

  alias TiannaraOS.Governance.GovernanceReplayEngine

  # Adapter behaviour implementation

  @impl true
  def execute(params) do
    case Map.get(params, :operation) do
      :replay -> execute_replay(params)
      :verify_field_equality -> verify_field_equality(params)
      :generate_certificate -> generate_certificate(params)
      _ -> {:error, :unknown_operation}
    end
  end

  @impl true
  def measure(metric, _params \\ %{}) do
    case metric do
      :replay_integrity -> measure_replay_integrity()
      :field_equality_rate -> measure_field_equality_rate()
      :determinism_score -> measure_determinism_score()
      _ -> {:error, :unknown_metric}
    end
  end

  @impl true
  def describe() do
    %{
      name: "ReplayAdapter",
      version: "1.0.0",
      purpose: "Enable deterministic replay validation of governance state",
      introduced_in: "Phase 14.0.97",
      depends_on: [
        "TiannaraOS.Governance.GovernanceLedger",
        "TiannaraOS.Governance.GovernanceReplayEngine"
      ],
      constitution_reference: "GOVERNANCE_VALIDATION_CONSTITUTION.md Section 8.3",
      owner: "Governance Council"
    }
  end

  @impl true
  def metadata() do
    %{
      module: __MODULE__,
      behaviour: TiannaraOS.Governance.Validation.Adapter,
      frozen_interface: true,
      hot_swappable: true,
      certified: false  # Will be set to true after certification in Phase 14.0.98
    }
  end

  # Private implementation functions

  defp execute_replay(%{count: count}) do
    # Execute deterministic replay using GovernanceReplayEngine
    results = Enum.map(1..count, fn _ ->
      case GovernanceReplayEngine.replay_full() do
        {:ok, state} ->
          %{success: true, state_hash: compute_state_hash(state)}
        {:error, reason} ->
          %{success: false, error: reason}
      end
    end)

    success_count = Enum.count(results, & &1.success)
    failure_count = count - success_count

    {:ok, %{
      certificate_id: "REPLAY-#{:crypto.strong_rand_bytes(8) |> Base.encode16()}",
      replay_count: count,
      success_count: success_count,
      failure_count: failure_count,
      success_rate: success_count / count,
      mismatches: failure_count,
      timestamp: DateTime.utc_now(),
      signature: generate_replay_signature(results),
      results: results
    }}
  end

  defp execute_replay(_params) do
    execute_replay(%{count: 100})
  end

  defp verify_field_equality(%{captured_state: captured, replayed_state: replayed}) do
    # Compare captured vs replayed state field-by-field using GovernanceReplayEngine
    case GovernanceReplayEngine.verify_replay(captured, replayed) do
      :match ->
        {:ok, %{
          equal: true,
          fields_checked: count_fields(captured),
          fields_mismatched: 0,
          equality_rate: 1.0
        }}
      {:mismatch, mismatch_details} ->
        total_fields = count_fields(captured)
        mismatched_fields = length(Map.keys(mismatch_details))
        {:ok, %{
          equal: false,
          fields_checked: total_fields,
          fields_mismatched: mismatched_fields,
          equality_rate: (total_fields - mismatched_fields) / total_fields,
          mismatch_details: mismatch_details
        }}
    end
  end

  defp verify_field_equality(_params) do
    verify_field_equality(%{captured_state: %{}, replayed_state: %{}})
  end

  defp generate_certificate(%{replay_results: results}) do
    # Generate cryptographic replay certificate
    content_hash = :crypto.hash(:sha256, :erlang.term_to_binary(results)) |> Base.encode16(case: :lower)
    signature = :crypto.hash(:sha256, content_hash <> "replay_cert") |> Base.encode16(case: :lower)
    
    {:ok, %{
      type: :replay_certificate,
      content_hash: content_hash,
      signature: signature,
      timestamp: DateTime.utc_now(),
      replay_verified: Map.get(results, :verified, false)
    }}
  end

  defp generate_certificate(_params) do
    generate_certificate(%{replay_results: %{}})
  end

  defp measure_replay_integrity() do
    # Measure percentage of replays that succeed deterministically by running sample
    sample_size = 10
    results = Enum.map(1..sample_size, fn _ ->
      case GovernanceReplayEngine.replay_full() do
        {:ok, _state} -> 1
        {:error, _reason} -> 0
      end
    end)
    
    integrity = Enum.sum(results) / sample_size
    {:ok, integrity}
  end

  defp measure_field_equality_rate() do
    # Measure average field equality rate across multiple replay runs
    sample_size = 5
    equality_rates = Enum.map(1..sample_size, fn _ ->
      case GovernanceReplayEngine.replay_full() do
        {:ok, state} ->
          # Capture current state and compare
          case GovernanceReplayEngine.replay_full() do
            {:ok, state2} ->
              case GovernanceReplayEngine.verify_replay(state, state2) do
                :match -> 1.0
                {:mismatch, details} ->
                  total = count_fields(state)
                  mismatched = length(Map.keys(details))
                  (total - mismatched) / total
              end
            {:error, _} -> 0.0
          end
        {:error, _} -> 0.0
      end
    end)
    
    avg_equality = Enum.sum(equality_rates) / sample_size
    {:ok, avg_equality}
  end

  defp measure_determinism_score() do
    # Score based on consistency across multiple replay runs
    sample_size = 10
    hashes = Enum.map(1..sample_size, fn _ ->
      case GovernanceReplayEngine.replay_full() do
        {:ok, state} -> compute_state_hash(state)
        {:error, _} -> nil
      end
    end)
    
    # Count unique hashes (deterministic = all same)
    unique_hashes = hashes |> Enum.filter(& &1) |> Enum.uniq()
    determinism_score = if length(unique_hashes) == 1, do: 1.0, else: 1.0 / length(unique_hashes)
    
    {:ok, determinism_score}
  end

  # Helper functions

  defp compute_state_hash(%{institutions: institutions, roles: roles, appointments: appointments}) do
    # Compute deterministic hash of governance state
    state_data = %{institutions: institutions, roles: roles, appointments: appointments}
    :crypto.hash(:sha256, :erlang.term_to_binary(state_data)) |> Base.encode16(case: :lower)
  end

  defp compute_state_hash(_state) do
    # Fallback for incomplete state
    "unknown"
  end

  defp generate_replay_signature(results) do
    # Generate cryptographic signature over replay results
    results_binary = :erlang.term_to_binary(results)
    :crypto.hash(:sha256, results_binary) |> Base.encode16(case: :lower)
  end

  defp count_fields(state) when is_map(state) do
    # Count total fields in governance state map
    Map.keys(state) |> length()
  end

  defp count_fields(_), do: 0
end
