defmodule TiannaraOS.Governance.Validation.CampaignExecutor do
  @moduledoc """
  CampaignExecutor - Generic campaign execution engine with no GV-specific logic.
  
  This executor reads campaign specifications from the registry and executes them
  using the appropriate adapters. It knows nothing about GV-001, GV-002, etc.
  It only knows: spec.adapter, spec.params, spec.evidence_type.
  
  Adding new campaigns requires zero changes to this module.
  
  ## Execution Flow
  
      spec = CampaignRegistry.get_campaign("GV-001")
      {:ok, evidence} = CampaignExecutor.execute_campaign(spec, adapters)
  
  ## Adapter Resolution
  
  The executor resolves adapters by name and delegates all domain logic to them.
  This ensures measurement logic lives in adapters, not campaigns.
  """

  alias TiannaraOS.Governance.Validation.{
    EvidenceCollector,
    EvidenceSigner
  }

  @type campaign_spec :: map()
  @type adapter_map :: %{atom() => module()}
  @type execution_result :: {:ok, map()} | {:error, map()}

  @doc """
  Execute a single campaign based on its specification.
  
  Returns evidence artifact or failure report.
  """
  @spec execute_campaign(campaign_spec(), adapter_map()) :: execution_result()
  def execute_campaign(spec, adapters) do
    start_time = System.system_time(:millisecond)
    
    IO.puts("  📊 Executing #{spec.campaign_id}: #{spec.name}")
    
    result = case execute_with_adapter(spec, adapters) do
      {:ok, data} ->
        # Collect evidence
        evidence = EvidenceCollector.collect_evidence(spec, data, start_time)
        
        # Sign artifact
        signed_evidence = EvidenceSigner.sign_artifact(evidence)
        
        {:ok, signed_evidence}
        
      {:error, failure} ->
        {:error, wrap_failure(spec, failure)}
    end
    
    duration_ms = System.system_time(:millisecond) - start_time
    IO.puts("     ✓ Completed in #{duration_ms}ms")
    
    result
  end

  @doc """
  Execute multiple campaigns in parallel within a phase.
  """
  @spec execute_phase([campaign_spec()], adapter_map()) :: %{String.t() => execution_result()}
  def execute_phase(campaigns, adapters) do
    campaigns
    |> Task.async_stream(
      fn spec ->
        {spec.campaign_id, execute_campaign(spec, adapters)}
      end,
      timeout: 300_000,  # 5 minute timeout per campaign
      max_concurrency: 5
    )
    |> Enum.into(%{})
  end

  @doc """
  Resolve adapter module from spec.
  """
  @spec resolve_adapter(atom(), adapter_map()) :: module()
  def resolve_adapter(adapter_name, adapters) do
    case Map.get(adapters, adapter_name) do
      nil -> raise "Adapter not found: #{inspect(adapter_name)}"
      module -> module
    end
  end

  @doc """
  Execute adapter operation with parameters from spec.
  """
  @spec execute_adapter(module(), atom(), map()) :: term()
  def execute_adapter(adapter_module, operation, params) do
    apply(adapter_module, operation, [params])
  end

  # Private Functions

  defp execute_with_adapter(spec, adapters) do
    # Get primary adapter from spec
    adapter_name = get_primary_adapter(spec)
    adapter_module = resolve_adapter(adapter_name, adapters)
    
    # Prepare execution parameters
    params = build_execution_params(spec)
    
    # Execute adapter operation
    try do
      execute_adapter(adapter_module, :execute, params)
    rescue
      e ->
        {:error, %{
          type: :adapter_exception,
          message: Exception.message(e),
          stacktrace: __STACKTRACE__
        }}
    end
  end

  defp get_primary_adapter(spec) do
    # Get first adapter from adapters_required list
    case Map.get(spec, :adapters_required, []) do
      [] -> raise "No adapters specified for campaign #{spec.campaign_id}"
      [first | _] -> String.to_atom(first)
    end
  end

  defp build_execution_params(spec) do
    # Build parameters from campaign spec
    # In production, this would be more sophisticated
    %{
      campaign_id: spec.campaign_id,
      threshold: get_threshold_for_execution(spec),
      seed: :fixed_for_replay,
      config: spec
    }
  end

  defp get_threshold_for_execution(spec) do
    # Use recommended threshold by default
    thresholds = Map.get(spec, :thresholds, %{})
    Map.get(thresholds, :recommended, 100)
  end

  defp wrap_failure(spec, failure) do
    # Categorize failure using failure registry
    %{
      campaign_id: spec.campaign_id,
      failure_type: categorize_failure(failure),
      details: failure,
      timestamp: DateTime.utc_now()
    }
  end

  defp categorize_failure(failure) do
    # Map failure to FAIL-XXX code
    # Simplified for now
    case failure do
      %{type: :adapter_exception} -> "FAIL-001"
      _ -> "FAIL-999"
    end
  end
end
