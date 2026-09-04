defmodule TiannaraOS.Governance.Validation.GovernanceValidationLaboratory do
  @moduledoc """
  GovernanceValidationLaboratory - Orchestrates the complete validation campaign.
  
  This is the entry point for running all governance validation campaigns.
  It loads registries, builds execution plans, schedules phases, executes campaigns,
  collects evidence, and generates reports.
  
  ## Usage
  
      # Run full validation campaign
      {:ok, report} = GovernanceValidationLaboratory.run_full_campaign()
      
      # Run single campaign
      {:ok, evidence} = GovernanceValidationLaboratory.run_campaign("GV-001")
  """

  alias TiannaraOS.Governance.Validation.{
    CampaignRegistry,
    CampaignExecutor,
    EvidenceAggregator,
    ReportGenerator
  }
  
  alias TiannaraOS.Governance.Validation.Adapters

  @doc """
  Run full validation campaign across all phases.
  
  Returns aggregated validation report with freeze recommendation.
  """
  @spec run_full_campaign() :: {:ok, map()} | {:error, term()}
  def run_full_campaign() do
    IO.puts("\n🧪 Starting Governance Validation Campaign...\n")
    
    start_time = System.system_time(:millisecond)
    
    with {:ok, campaigns} <- CampaignRegistry.load_registry(),
         adapters <- initialize_adapters(),
         {:ok, all_evidence} <- execute_all_phases(campaigns, adapters) do
      
      # Aggregate results
      summary = EvidenceAggregator.aggregate_results(all_evidence)
      
      # Generate report
      ReportGenerator.generate_report(summary, all_evidence)
      
      duration_ms = System.system_time(:millisecond) - start_time
      
      IO.puts("\n✅ Campaign Complete:")
      IO.puts("   Total: #{summary.total_campaigns}")
      IO.puts("   Passed: #{summary.passed_campaigns}")
      IO.puts("   Failed: #{summary.failed_campaigns}")
      IO.puts("   Status: #{summary.overall_status |> Atom.to_string() |> String.upcase()}")
      IO.puts("   Freeze: #{summary.freeze_recommendation |> Atom.to_string() |> String.upcase()}")
      IO.puts("   Duration: #{duration_ms}ms\n")
      
      {:ok, %{summary: summary, evidence: all_evidence}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Run single campaign by ID.
  """
  @spec run_campaign(String.t()) :: {:ok, map()} | {:error, term()}
  def run_campaign(campaign_id) do
    with {:ok, spec} <- CampaignRegistry.get_campaign(campaign_id),
         adapters <- initialize_adapters(),
         {:ok, evidence} <- CampaignExecutor.execute_campaign(spec, adapters) do
      {:ok, evidence}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Private Functions

  defp initialize_adapters() do
    # Initialize all required adapters with REAL implementations (Phase 14.0.97)
    %{
      LedgerAdapter: Adapters.LedgerAdapter,
      StateAdapter: Adapters.StateAdapter,
      GraphAdapter: Adapters.GraphAdapter,
      ReplayAdapter: Adapters.ReplayAdapter,
      CertificateAdapter: Adapters.CertificateAdapter,
      FingerprintAdapter: Adapters.FingerprintAdapter,
      ArchaeologyAdapter: Adapters.ArchaeologyAdapter,
      FitnessAdapter: Adapters.FitnessAdapter,
      EntropyAdapter: Adapters.EntropyAdapter,
      CostAdapter: Adapters.CostAdapter
    }
  end

  defp execute_all_phases(campaigns, adapters) do
    # Get max phase number
    max_phase = campaigns
    |> Enum.map(& &1.execution_phase)
    |> Enum.max()
    
    # Execute phases sequentially
    all_evidence = Enum.reduce(1..max_phase, [], fn phase_num, acc ->
      IO.puts("\n📋 Executing Phase #{phase_num}...")
      
      phase_campaigns = CampaignRegistry.list_campaigns_by_phase(phase_num)
      
      if Enum.empty?(phase_campaigns) do
        acc
      else
        # Execute phase (parallel within phase)
        results = CampaignExecutor.execute_phase(phase_campaigns, adapters)
        
        # Collect successful evidence
        evidence = results
        |> Map.values()
        |> Enum.filter(fn
          {:ok, _} -> true
          _ -> false
        end)
        |> Enum.map(fn {:ok, ev} -> ev end)
        
        acc ++ evidence
      end
    end)
    
    {:ok, all_evidence}
  end
end

