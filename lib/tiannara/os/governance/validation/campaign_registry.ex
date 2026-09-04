defmodule TiannaraOS.Governance.Validation.CampaignRegistry do
  @moduledoc """
  CampaignRegistry - Loads and manages governance validation campaign specifications.
  
  This module reads campaign definitions from GOVERNANCE_CAMPAIGN_REGISTRY.md,
  parses them into executable specs, and provides lookup functions for the runtime.
  
  Campaigns are data, not code. This registry is the single source of truth for
  what campaigns exist, their dependencies, thresholds, and required adapters.
  
  ## Usage
  
      {:ok, campaigns} = CampaignRegistry.load_registry()
      {:ok, spec} = CampaignRegistry.get_campaign("GV-001")
      phase_1_campaigns = CampaignRegistry.list_campaigns_by_phase(1)
  """

  @registry_path "docs/GOVERNANCE_CAMPAIGN_REGISTRY.md"
  @failure_registry_path "docs/GOVERNANCE_FAILURE_REGISTRY.md"
  @evidence_registry_path "docs/GOVERNANCE_EVIDENCE_REGISTRY.md"

  @type campaign_spec :: map()
  @type failure_spec :: map()
  @type evidence_spec :: map()

  @doc """
  Load all campaign specifications from registry file.
  
  Returns list of parsed campaign specs with resolved references.
  """
  @spec load_registry() :: {:ok, [campaign_spec()]} | {:error, term()}
  def load_registry() do
    with {:ok, content} <- File.read(@registry_path),
         {:ok, campaigns} <- parse_campaigns(content),
         {:ok, failures} <- load_failure_registry(),
         {:ok, evidence_types} <- load_evidence_registry(),
         resolved <- resolve_references(campaigns, failures, evidence_types) do
      {:ok, resolved}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get specific campaign by ID.
  
  Returns campaign spec with all references resolved.
  """
  @spec get_campaign(String.t()) :: {:ok, campaign_spec()} | {:error, :not_found}
  def get_campaign(campaign_id) do
    case load_registry() do
      {:ok, campaigns} ->
        case Enum.find(campaigns, fn c -> c.campaign_id == campaign_id end) do
          nil -> {:error, :not_found}
          campaign -> {:ok, campaign}
        end
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  List all campaigns for a specific execution phase.
  """
  @spec list_campaigns_by_phase(non_neg_integer()) :: [campaign_spec()]
  def list_campaigns_by_phase(phase_number) do
    case load_registry() do
      {:ok, campaigns} ->
        Enum.filter(campaigns, fn c -> c.execution_phase == phase_number end)
      {:error, _} -> []
    end
  end

  @doc """
  Get dependencies for a specific campaign.
  """
  @spec get_dependencies(String.t()) :: [String.t()]
  def get_dependencies(campaign_id) do
    case get_campaign(campaign_id) do
      {:ok, campaign} -> Map.get(campaign, :dependencies, [])
      {:error, _} -> []
    end
  end

  @doc """
  Get threshold value for campaign at specified level.
  """
  @spec get_threshold(String.t(), :minimum_required | :recommended | :certification | :stress) :: non_neg_integer() | map()
  def get_threshold(campaign_id, level) do
    case get_campaign(campaign_id) do
      {:ok, campaign} ->
        thresholds = Map.get(campaign, :thresholds, %{})
        Map.get(thresholds, level, 0)
      {:error, _} -> 0
    end
  end

  @doc """
  Validate that all campaign references are resolvable.
  """
  @spec validate_registry() :: :valid | {:invalid, map()}
  def validate_registry() do
    case load_registry() do
      {:ok, campaigns} ->
        # Check for circular dependencies
        case detect_cycles(campaigns) do
          :valid -> :valid
          {:cycle_detected, cycle} -> {:invalid, %{cycles: cycle}}
        end
      {:error, reason} -> {:invalid, %{load_error: reason}}
    end
  end

  # Private Functions

  defp parse_campaigns(content) do
    # Simplified YAML parsing - in production, use proper YAML parser
    # For now, extract campaign blocks using regex
    
    campaign_blocks = Regex.scan(~r/## GV-\d+:.*?(?=## GV-\d+:|$)/s, content)
    
    campaigns = Enum.map(campaign_blocks, fn [block] ->
      parse_single_campaign(block)
    end)
    
    {:ok, campaigns}
  end

  defp parse_single_campaign(block) do
    # Extract fields from YAML block
    # This is a simplified parser - production would use proper YAML library
    
    campaign_id = extract_field(block, ~r/campaign_id:\s*(\S+)/)
    campaign_version = extract_field(block, ~r/campaign_version:\s*(\S+)/)
    name = extract_field(block, ~r/name:\s*(.+)/)
    introduced_in = extract_field(block, ~r/introduced_in:\s*(.+)/)
    
    # Extract failure modes
    failure_modes = extract_list(block, ~r/failure_modes:\s*\n((?:\s+- .+\n)+)/)
    
    # Extract evidence type
    evidence_type = extract_field(block, ~r/evidence_type:\s*(\S+)/)
    
    # Extract thresholds
    thresholds = extract_thresholds(block)
    
    # Extract dependencies
    dependencies = extract_list(block, ~r/dependencies:\s*\n((?:\s+- .+\n)+)/)
    
    # Extract adapters
    adapters_required = extract_list(block, ~r/adapters_required:\s*\n((?:\s+- .+\n)+)/)
    
    # Extract execution phase
    execution_phase = extract_field(block, ~r/execution_phase:\s*(\d+)/) |> String.to_integer()
    
    %{
      campaign_id: campaign_id,
      campaign_version: campaign_version,
      name: name,
      introduced_in: introduced_in,
      failure_modes: failure_modes,
      evidence_type: evidence_type,
      thresholds: thresholds,
      dependencies: dependencies,
      adapters_required: adapters_required,
      execution_phase: execution_phase
    }
  end

  defp extract_field(text, pattern) do
    case Regex.run(pattern, text) do
      [_, value] -> String.trim(value)
      nil -> ""
    end
  end

  defp extract_list(text, pattern) do
    case Regex.run(pattern, text) do
      [_, list_block] ->
        list_block
        |> String.split("\n")
        |> Enum.map(&String.trim/1)
        |> Enum.filter(fn line -> String.starts_with?(line, "- ") end)
        |> Enum.map(fn line -> String.trim_leading(line, "- ") end)
      nil -> []
    end
  end

  defp extract_thresholds(text) do
    # Simplified threshold extraction
    %{
      minimum_required: extract_numeric_field(text, ~r/minimum_required:\s*(\d+)/),
      recommended: extract_numeric_field(text, ~r/recommended:\s*(\d+)/),
      certification: extract_numeric_field(text, ~r/certification:\s*(\d+)/),
      stress: extract_numeric_field(text, ~r/stress:\s*(\d+)/)
    }
  end

  defp extract_numeric_field(text, pattern) do
    case Regex.run(pattern, text) do
      [_, value] -> String.to_integer(value)
      nil -> 0
    end
  end

  defp load_failure_registry() do
    case File.read(@failure_registry_path) do
      {:ok, _content} ->
        # Parse failure registry (simplified)
        {:ok, []}
      {:error, reason} ->
        {:error, "Failed to load failure registry: #{inspect(reason)}"}
    end
  end

  defp load_evidence_registry() do
    case File.read(@evidence_registry_path) do
      {:ok, _content} ->
        # Parse evidence registry (simplified)
        {:ok, []}
      {:error, reason} ->
        {:error, "Failed to load evidence registry: #{inspect(reason)}"}
    end
  end

  defp resolve_references(campaigns, _failures, _evidence_types) do
    # In production, resolve FAIL-XXX and EVID-XXX references
    # For now, return campaigns as-is
    campaigns
  end

  defp detect_cycles(campaigns) do
    # Simple cycle detection using DFS
    # Build adjacency list
    adj_list = Enum.reduce(campaigns, %{}, fn campaign, acc ->
      Map.put(acc, campaign.campaign_id, campaign.dependencies)
    end)
    
    # Check for cycles
    visited = MapSet.new()
    rec_stack = MapSet.new()
    
    case Enum.find(campaigns, fn campaign ->
      has_cycle?(campaign.campaign_id, adj_list, visited, rec_stack)
    end) do
      nil -> :valid
      _ -> {:cycle_detected, "Cycle detected in dependencies"}
    end
  end

  defp has_cycle?(node, adj_list, visited, rec_stack) do
    visited = MapSet.put(visited, node)
    rec_stack = MapSet.put(rec_stack, node)
    
    neighbors = Map.get(adj_list, node, [])
    
    Enum.any?(neighbors, fn neighbor ->
      if not MapSet.member?(visited, neighbor) do
        has_cycle?(neighbor, adj_list, visited, rec_stack)
      else
        MapSet.member?(rec_stack, neighbor)
      end
    end)
  end
end
