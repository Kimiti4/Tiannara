defmodule TiannaraOS.InstitutionEpisodeComparisonReport do
  @moduledoc """
  Comparison report for multiple institutional research episodes.
  
  This artifact demonstrates adaptive scientific reasoning by comparing
  how an institution responds to different environmental conditions,
  evidence quality, governance decisions, and economic constraints.
  
  ## Purpose
  
  Validates Capability 12.1.2B - proving that institutions can reason
  correctly under uncertainty rather than executing deterministic workflows.
  
  ## Usage
  
  Generate after executing multiple research episodes to compare:
  - Decision outcomes (SUCCESS, NEGATIVE_RESULT, INCONCLUSIVE, REJECTED, DEFERRED)
  - Belief revision patterns
  - Constitutional invariant preservation
  - Resource utilization
  - Publication decisions
  """
  
  defstruct [
    # Report Metadata
    :report_id,
    :institution_id,
    :timestamp,
    
    # Episode Collection
    :episodes,
    
    # Comparative Analysis
    :summary_statistics,
    
    # Behavioral Patterns
    :adaptation_evidence,
    
    # Constitutional Compliance
    :invariant_preservation,
    
    # Overall Assessment
    :overall_status
  ]
  
  @doc """
  Generate a comparison report from multiple episode reports.
  """
  @spec generate([TiannaraOS.InstitutionEpisodeReport.t()]) :: %__MODULE__{}
  def generate(episode_reports) when is_list(episode_reports) and length(episode_reports) > 0 do
    %__MODULE__{
      report_id: generate_report_id(),
      institution_id: get_institution_id(episode_reports),
      timestamp: DateTime.utc_now(),
      
      episodes: episode_reports,
      
      summary_statistics: calculate_summary_statistics(episode_reports),
      
      adaptation_evidence: analyze_adaptation_patterns(episode_reports),
      
      invariant_preservation: check_invariant_preservation(episode_reports),
      
      overall_status: determine_overall_status(episode_reports)
    }
  end
  
  @doc """
  Print human-readable comparison report.
  """
  @spec print(%__MODULE__{}) :: :ok
  def print(report) do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("INSTITUTION EPISODE COMPARISON REPORT")
    IO.puts(String.duplicate("=", 80))
    
    IO.puts("\n📊 REPORT METADATA:")
    IO.puts("  Report ID: #{report.report_id}")
    IO.puts("  Institution: #{report.institution_id}")
    IO.puts("  Timestamp: #{report.timestamp}")
    IO.puts("  Episodes Compared: #{length(report.episodes)}")
    
    IO.puts("\n📈 SUMMARY STATISTICS:")
    stats = report.summary_statistics
    IO.puts("  Total Episodes: #{stats.total_episodes}")
    IO.puts("  Successful Discoveries: #{stats.successful_discoveries}")
    IO.puts("  Negative Results: #{stats.negative_results}")
    IO.puts("  Inconclusive: #{stats.inconclusive}")
    IO.puts("  Rejected by Governance: #{stats.rejected}")
    IO.puts("  Deferred (Budget): #{stats.deferred}")
    IO.puts("  Average Execution Time: #{stats.avg_execution_time_ms}ms")
    IO.puts("  Total Ledger Cost: #{stats.total_ledger_cost}")
    
    IO.puts("\n🧠 ADAPTATION EVIDENCE:")
    adaptation = report.adaptation_evidence
    IO.puts("  Different Outcomes: #{if adaptation.different_outcomes, do: "✓", else: "✗"}")
    IO.puts("  Confidence Adaptation: #{if adaptation.confidence_adaptation, do: "✓", else: "✗"}")
    IO.puts("  Governance Responsiveness: #{if adaptation.governance_responsiveness, do: "✓", else: "✗"}")
    IO.puts("  Economic Constraints Respected: #{if adaptation.economic_constraints, do: "✓", else: "✗"}")
    IO.puts("  Uncertainty Preservation: #{if adaptation.uncertainty_preservation, do: "✓", else: "✗"}")
    
    IO.puts("\n🛡️  CONSTITUTIONAL INVARIANT PRESERVATION:")
    inv = report.invariant_preservation
    IO.puts("  Kernel Ownership: #{if inv.kernel_ownership, do: "✓ PASS", else: "✗ FAIL"}")
    IO.puts("  Event Completeness: #{if inv.event_completeness, do: "✓ PASS", else: "✗ FAIL"}")
    IO.puts("  Lifecycle Tracking: #{if inv.lifecycle_tracking, do: "✓ PASS", else: "✗ FAIL"}")
    IO.puts("  Knowledge Consistency: #{if inv.knowledge_consistency, do: "✓ PASS", else: "✗ FAIL"}")
    IO.puts("  Ledger Conservation: #{if inv.ledger_conservation, do: "✓ PASS", else: "✗ FAIL"}")
    IO.puts("  Memory Integrity: #{if inv.memory_integrity, do: "✓ PASS", else: "✗ FAIL"}")
    IO.puts("  Traceability: #{if inv.traceability, do: "✓ PASS", else: "✗ FAIL"}")
    
    IO.puts("\n✅ OVERALL STATUS: #{report.overall_status |> Atom.to_string() |> String.upcase()}")
    
    if report.overall_status == :pass do
      IO.puts("\n🎉 CAPABILITY 12.1.2B VALIDATED")
      IO.puts("Institution demonstrates adaptive scientific reasoning under uncertainty.")
    else
      IO.puts("\n❌ CAPABILITY 12.1.2B FAILED")
      IO.puts("Institution did not demonstrate sufficient adaptive behavior.")
    end
    
    IO.puts("\n" <> String.duplicate("=", 80))
    
    # Print individual episode summaries
    IO.puts("\n📋 INDIVIDUAL EPISODE SUMMARIES:\n")
    
    Enum.each(Enum.with_index(report.episodes), fn {episode, idx} ->
      rcr = episode.research_cycle_result
      IO.puts("Episode #{idx + 1}: #{episode.episode_id}")
      IO.puts("  Goal: #{episode.research_goal}")
      IO.puts("  Status: #{episode.status}")
      IO.puts("  Hypothesis Confidence: #{format_confidence_change(rcr.hypothesis, rcr.belief_change)}")
      IO.puts("  Publication: #{format_publication(rcr.publication)}")
      IO.puts("  Governance: #{format_governance(rcr.governance_decisions)}")
      IO.puts("  Ledger Cost: #{if rcr.ledger_delta, do: rcr.ledger_delta.expense || 0, else: 0}")
      IO.puts("  Semantic Events: #{length(rcr.semantic_events)}")
      IO.puts("  Constitutional Validation: #{rcr.constitutional_validation.status}")
      IO.puts("")
    end)
    
    :ok
  end
  
  # Private helper functions
  
  defp generate_report_id do
    "comp_#{:crypto.hash(:sha256, "#{DateTime.utc_now() |> DateTime.to_iso8601()}_#{System.system_time()}") |> Base.encode16(case: :lower) |> binary_part(0, 16)}"
  end
  
  defp get_institution_id(episodes) do
    hd(episodes).institution_id
  end
  
  defp calculate_summary_statistics(episodes) do
    statuses = Enum.map(episodes, & &1.status)
    
    %{
      total_episodes: length(episodes),
      successful_discoveries: Enum.count(statuses, &(&1 == :success)),
      negative_results: Enum.count(statuses, &(&1 == :negative_result)),
      inconclusive: Enum.count(statuses, &(&1 == :inconclusive)),
      rejected: Enum.count(statuses, &(&1 == :rejected)),
      deferred: Enum.count(statuses, &(&1 == :deferred)),
      avg_execution_time_ms: calculate_avg(execution_times(episodes)),
      total_ledger_cost: Enum.sum(ledger_costs(episodes))
    }
  end
  
  defp execution_times(episodes) do
    Enum.map(episodes, fn ep ->
      case ep.execution_time_ms do
        time when is_number(time) -> time
        _ -> 0
      end
    end)
  end
  
  defp ledger_costs(episodes) do
    Enum.map(episodes, fn ep ->
      case ep.research_cycle_result.ledger_delta do
        %{expense: cost} when is_number(cost) -> cost
        _ -> 0
      end
    end)
  end
  
  defp calculate_avg([]), do: 0
  defp calculate_avg(list), do: Enum.sum(list) / length(list)
  
  defp analyze_adaptation_patterns(episodes) do
    statuses = Enum.map(episodes, & &1.status)
    
    %{
      different_outcomes: length(Enum.uniq(statuses)) > 1,
      confidence_adaptation: confidence_varies?(episodes),
      governance_responsiveness: Enum.any?(statuses, &(&1 == :rejected)),
      economic_constraints: Enum.any?(statuses, &(&1 == :deferred)),
      uncertainty_preservation: Enum.any?(statuses, &(&1 == :inconclusive))
    }
  end
  
  defp confidence_varies?(episodes) do
    confidence_changes = Enum.map(episodes, fn ep ->
      case ep.research_cycle_result.belief_change do
        %{delta: delta} -> delta
        _ -> 0
      end
    end)
    
    length(Enum.uniq(confidence_changes)) > 1
  end
  
  defp check_invariant_preservation(episodes) do
    all_validations = Enum.map(episodes, & &1.research_cycle_result.constitutional_validation)
    
    %{
      kernel_ownership: Enum.all?(all_validations, &Map.get(&1, :kernel_ownership_violations, 0) == 0),
      event_completeness: Enum.all?(all_validations, &Map.get(&1, :semantic_events_emitted, 0) > 0),
      lifecycle_tracking: Enum.all?(all_validations, &Map.get(&1, :lifecycle_events_recorded, 0) > 0),
      knowledge_consistency: Enum.all?(all_validations, &Map.get(&1, :knowledge_graph_valid, false)),
      ledger_conservation: Enum.all?(all_validations, &Map.get(&1, :ledger_balanced, false)),
      memory_integrity: Enum.all?(all_validations, &Map.get(&1, :memory_intact, false)),
      traceability: Enum.all?(all_validations, &Map.get(&1, :status) == :pass)
    }
  end
  
  defp determine_overall_status(episodes) do
    validations = check_invariant_preservation(episodes)
    adaptation = analyze_adaptation_patterns(episodes)
    
    # All invariants must pass AND institution must show adaptation
    invariants_pass = Map.values(validations) |> Enum.all?(& &1)
    shows_adaptation = Map.values(adaptation) |> Enum.filter(& &1) |> length() >= 3
    
    if invariants_pass and shows_adaptation do
      :pass
    else
      :fail
    end
  end
  
  defp format_confidence_change(hypothesis, belief_change) do
    cond do
      hypothesis == nil -> "N/A"
      belief_change == nil -> "#{hypothesis.confidence} (no change)"
      true ->
        prior = belief_change.prior_confidence
        posterior = belief_change.posterior_confidence
        delta = belief_change.delta
        sign = if delta >= 0, do: "+", else: ""
        "#{prior} → #{posterior} (#{sign}#{delta})"
    end
  end
  
  defp format_publication(publication) do
    cond do
      publication == nil -> "None"
      publication.decision == :publish -> "Published (confidence: #{publication.confidence})"
      publication.decision == :archive -> "Archived (confidence: #{publication.confidence})"
      publication.decision == :defer -> "Deferred (insufficient evidence)"
      true -> Atom.to_string(publication.decision)
    end
  end
  
  defp format_governance(decisions) do
    cond do
      length(decisions) == 0 -> "No decision"
      true ->
        decision = hd(decisions)
        case decision.approved do
          true -> "Approved"
          false -> "Rejected: #{decision.reason}"
          _ -> "Unknown"
        end
    end
  end
end
