defmodule TiannaraOS.Governance.Validation.EvidenceCollector do
  @moduledoc """
  EvidenceCollector - Gathers raw outputs, measurements, timings from campaign execution.
  
  This module collects all evidence data from campaign execution but does NOT
  sign or hash artifacts. That's the job of EvidenceSigner.
  
  Responsibilities:
  - Capture raw campaign output
  - Compute quantitative measurements (from adapters)
  - Record execution timings
  - Compute fingerprints for inputs/outputs
  """

  @type campaign_spec :: map()
  @type execution_data :: map()
  @type evidence_artifact :: map()

  @doc """
  Collect evidence from campaign execution result.
  
  Returns unsigned evidence artifact ready for signing.
  """
  @spec collect_evidence(campaign_spec(), execution_data(), non_neg_integer()) :: evidence_artifact()
  def collect_evidence(spec, data, start_time) do
    end_time = System.system_time(:millisecond)
    
    %{
      campaign_id: spec.campaign_id,
      campaign_version: spec.campaign_version,
      timestamp: DateTime.utc_now(),
      input_fingerprint: compute_input_fingerprint(spec),
      output_fingerprint: compute_output_fingerprint(data),
      content_hash: nil,  # Will be set by signer
      signature: nil,     # Will be set by signer
      content: %{
        data: data,
        measurements: compute_measurements(data),
        timings: record_timings(start_time, end_time),
        logs: capture_logs(data)
      }
    }
  end

  @doc """
  Compute quantitative measurements from execution data.
  
  Delegates to adapters for domain-specific measurements.
  """
  @spec compute_measurements(execution_data()) :: map()
  def compute_measurements(data) do
    # Extract measurements from execution data
    # In production, this would call adapter measurement functions
    %{
      execution_success: Map.get(data, :success, false),
      records_processed: Map.get(data, :records_count, 0),
      duration_ms: Map.get(data, :duration_ms, 0)
    }
  end

  @doc """
  Record execution timings.
  """
  @spec record_timings(non_neg_integer(), non_neg_integer()) :: map()
  def record_timings(start_time, end_time) do
    %{
      start_time: start_time,
      end_time: end_time,
      duration_ms: end_time - start_time
    }
  end

  @doc """
  Capture diagnostic logs from execution context.
  """
  @spec capture_logs(execution_data()) :: [String.t()]
  def capture_logs(data) do
    # Extract logs from execution data
    Map.get(data, :logs, [])
  end

  @doc """
  Compute fingerprint of canonical inputs.
  """
  @spec compute_input_fingerprint(campaign_spec()) :: String.t()
  def compute_input_fingerprint(spec) do
    # Hash campaign spec as input fingerprint
    :crypto.hash(:sha256, :erlang.term_to_binary(spec))
    |> Base.encode16(case: :lower)
  end

  @doc """
  Compute fingerprint of output data.
  """
  @spec compute_output_fingerprint(execution_data()) :: String.t()
  def compute_output_fingerprint(data) do
    # Hash output data
    :crypto.hash(:sha256, :erlang.term_to_binary(data))
    |> Base.encode16(case: :lower)
  end
end
