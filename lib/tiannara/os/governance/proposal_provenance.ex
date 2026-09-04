defmodule TiannaraOS.Governance.ProposalProvenance do
  @moduledoc """
  ProposalProvenance - Complete lineage tracking for proposals
  
  Answers the fundamental archaeological questions:
  - WHY did this proposal exist? (intent, justification)
  - WHEN did each change occur? (timestamps)
  - WHO made each decision? (proposer, reviewers, institutions)
  - WHAT evidence supports it? (simulations, reviews, certifications)
  - WHAT does it supersede/depend on? (lineage)
  
  ## Owner
  Read-only interface to ProposalLedger + ProposalIndex.
  
  ## Guarantees
  - Every state change is explainable
  - Complete decision trail preserved
  - Evidence chain immutable
  """

  alias TiannaraOS.Governance.ProposalLedger

  # === Public API ===

  @doc """
  Get complete provenance record for a proposal.
  
  Returns comprehensive explanation of proposal's entire lifecycle.
  """
  @spec get_provenance(String.t()) :: {:ok, map()} | {:error, String.t()}
  def get_provenance(proposal_id) do
    with {:ok, events} <- fetch_events(proposal_id),
         {:ok, proposal} <- fetch_proposal(proposal_id) do
      
      provenance = %{
        proposal_id: proposal_id,
        why: explain_why(proposal, events),
        when: explain_when(events),
        who: explain_who(proposal, events),
        evidence: collect_evidence(events),
        certificate: extract_certificate(proposal),
        supersedes: get_supersedes_chain(proposal_id),
        depends_on: get_dependencies(proposal),
        lineage: build_lineage(proposal_id, events),
        completeness: verify_completeness(events)
      }
      
      {:ok, provenance}
    end
  end

  @doc """
  Explain why a proposal was created.
  """
  @spec explain_why(map(), [map()]) :: map()
  def explain_why(proposal, events) do
    creation_event = Enum.find(events, &(&1.type == :proposal_created))
    
    %{
      intent: Map.get(creation_event, :data, %{}) |> Map.get(:intent, ""),
      justification: Map.get(creation_event, :data, %{}) |> Map.get(:justification, ""),
      problem_statement: Map.get(proposal, :problem_statement, ""),
      expected_benefits: Map.get(proposal, :expected_benefits, []),
      proposer: proposal.proposer,
      created_at: proposal.created_at
    }
  end

  @doc """
  Explain when each significant event occurred.
  """
  @spec explain_when([map()]) :: map()
  def explain_when(events) do
    timeline = Enum.map(events, fn event ->
      %{
        sequence: event.sequence,
        timestamp: event.timestamp,
        event_type: event.type,
        summary: summarize_event(event)
      }
    end)
    
    key_milestones = extract_milestones(events)
    
    %{
      created: find_timestamp(events, :proposal_created),
      first_review: find_timestamp(events, :review_added),
      simulation_completed: find_timestamp(events, :simulation_completed),
      ratified: find_timestamp(events, :ratification_completed),
      execution_started: find_timestamp(events, :execution_started),
      execution_completed: find_timestamp(events, :execution_completed),
      certified: find_timestamp(events, :certification_completed),
      archived: find_timestamp(events, :proposal_archived),
      full_timeline: timeline,
      milestones: key_milestones
    }
  end

  @doc """
  Explain who made each decision.
  """
  @spec explain_who(map(), [map()]) :: map()
  def explain_who(proposal, events) do
    review_events = Enum.filter(events, &(&1.type == :review_added))
    ratification_event = Enum.find(events, &(&1.type == :ratification_completed))
    
    %{
      proposer: proposal.proposer,
      reviewers: Enum.map(review_events, fn event ->
        %{
          reviewer_id: event.data.reviewer_id,
          decision: event.data.decision,
          timestamp: event.timestamp
        }
      end),
      ratifying_institutions: case ratification_event do
        nil -> []
        event -> event.data.approving_institutions || []
      end,
      total_reviewers: length(review_events),
      decision_authority: determine_authority(events)
    }
  end

  @doc """
  Collect all supporting evidence.
  """
  @spec collect_evidence([map()]) :: map()
  def collect_evidence(events) do
    simulations = Enum.filter(events, &(&1.type == :simulation_completed))
    reviews = Enum.filter(events, &(&1.type == :review_added))
    certifications = Enum.filter(events, &(&1.type == :certification_completed))
    
    %{
      simulations: Enum.map(simulations, fn event ->
        %{
          simulation_id: event.data.simulation_id,
          scenario: event.data.scenario,
          passed: event.data.passed,
          timestamp: event.timestamp
        }
      end),
      reviews: Enum.map(reviews, fn event ->
        %{
          review_id: event.data.review_id,
          decision: event.data.decision,
          rationale: event.data.rationale,
          timestamp: event.timestamp
        }
      end),
      certifications: Enum.map(certifications, fn event ->
        %{
          certificate_hash: event.data.certificate_hash,
          timestamp: event.timestamp
        }
      end),
      total_evidence_items: length(simulations) + length(reviews) + length(certifications)
    }
  end

  @doc """
  Extract final certification information.
  """
  @spec extract_certificate(map()) :: map() | nil
  def extract_certificate(proposal) do
    case Map.get(proposal, :certificate_hash) do
      nil -> nil
      hash ->
        %{
          certificate_hash: hash,
          certified_at: Map.get(proposal, :certified_at),
          replay_hash: Map.get(proposal, :replay_hash)
        }
    end
  end

  @doc """
  Get supersedes relationship chain.
  """
  @spec get_supersedes_chain(String.t()) :: [String.t()]
  def get_supersedes_chain(proposal_id) do
    events = ProposalLedger.get_proposal_events(proposal_id)
    
    case Enum.find(events, &(&1.type == :proposal_superseded)) do
      nil -> []
      event ->
        superseded_by = event.data.superseded_by
        [superseded_by | get_supersedes_chain(superseded_by)]
    end
  end

  @doc """
  Get dependencies for a proposal.
  """
  @spec get_dependencies(map()) :: [String.t()]
  def get_dependencies(proposal) do
    Map.get(proposal, :depends_on, [])
  end

  @doc """
  Build complete lineage tree.
  """
  @spec build_lineage(String.t(), [map()]) :: map()
  def build_lineage(proposal_id, events) do
    creation_event = Enum.find(events, &(&1.type == :proposal_created))
    rfc_id = case creation_event do
      nil -> nil
      event -> event.rfc_id
    end
    
    %{
      proposal_id: proposal_id,
      parent_rfc: rfc_id,
      supersedes: get_supersedes_chain(proposal_id),
      superseded_by: get_superseded_by(proposal_id),
      siblings: get_siblings(rfc_id, proposal_id),
      depth: calculate_depth(proposal_id, 0)
    }
  end

  @doc """
  Verify provenance completeness.
  """
  @spec verify_completeness([map()]) :: map()
  def verify_completeness(events) do
    required_events = [:proposal_created]
    optional_events = [:review_added, :simulation_completed, :ratification_completed,
                       :certification_completed]
    
    present_required = Enum.filter(required_events, fn type ->
      Enum.any?(events, &(&1.type == type))
    end)
    
    present_optional = Enum.filter(optional_events, fn type ->
      Enum.any?(events, &(&1.type == type))
    end)
    
    %{
      required_present: present_required,
      required_missing: required_events -- present_required,
      optional_present: present_optional,
      optional_missing: optional_events -- present_optional,
      completeness_score: calculate_completeness(present_required, required_events,
                                                  present_optional, optional_events),
      is_complete: length(required_events -- present_required) == 0
    }
  end

  # === Private Functions ===

  defp fetch_events(proposal_id) do
    events = ProposalLedger.get_proposal_events(proposal_id)
    
    if Enum.empty?(events) do
      {:error, "No events found for proposal #{proposal_id}"}
    else
      {:ok, events}
    end
  end

  defp fetch_proposal(proposal_id) do
    case ProposalLedger.get_proposal_state(proposal_id) do
      nil -> {:error, "Proposal not found: #{proposal_id}"}
      state -> {:ok, state}
    end
  end

  defp summarize_event(%{type: :proposal_created}), do: "Proposal created"
  defp summarize_event(%{type: :status_changed, data: data}), do: "Status: #{data.old_status} → #{data.new_status}"
  defp summarize_event(%{type: :review_added, data: data}), do: "Review: #{data.decision}"
  defp summarize_event(%{type: :simulation_completed, data: data}), do: "Simulation (#{data.scenario}): #{if data.passed, do: "PASSED", else: "FAILED"}"
  defp summarize_event(%{type: :ratification_completed}), do: "Ratification completed"
  defp summarize_event(%{type: :migration_plan_created}), do: "Migration plan created"
  defp summarize_event(%{type: :execution_started}), do: "Execution started"
  defp summarize_event(%{type: :execution_completed, data: data}), do: "Execution #{if data.success, do: "succeeded", else: "failed"}"
  defp summarize_event(%{type: :certification_completed}), do: "Certification completed"
  defp summarize_event(%{type: :proposal_superseded}), do: "Superseded"
  defp summarize_event(%{type: :proposal_archived}), do: "Archived"
  defp summarize_event(_), do: "Unknown event"

  defp extract_milestones(events) do
    events
    |> Enum.filter(fn event ->
      event.type in [:proposal_created, :ratification_completed,
                     :execution_completed, :certification_completed]
    end)
    |> Enum.map(fn event ->
      %{
        milestone: Atom.to_string(event.type),
        timestamp: event.timestamp,
        sequence: event.sequence
      }
    end)
  end

  defp find_timestamp(events, type) do
    case Enum.find(events, &(&1.type == type)) do
      nil -> nil
      event -> event.timestamp
    end
  end

  defp determine_authority(events) do
    has_ratification = Enum.any?(events, &(&1.type == :ratification_completed))
    has_reviews = Enum.any?(events, &(&1.type == :review_added))
    
    cond do
      has_ratification -> :institutional
      has_reviews -> :review_board
      true -> :proposer_only
    end
  end

  defp get_superseded_by(proposal_id) do
    # Check if any other proposal supersedes this one
    events = ProposalLedger.get_all_events()
    
    case Enum.find(events, fn event ->
      event.type == :proposal_superseded && event.data.superseded_by == proposal_id
    end) do
      nil -> nil
      event -> event.proposal_id
    end
  end

  defp get_siblings(rfc_id, current_proposal_id) do
    if rfc_id do
      ProposalLedger.get_rfc_events(rfc_id)
      |> Enum.filter(&(&1.type == :proposal_created))
      |> Enum.map(& &1.proposal_id)
      |> Enum.uniq()
      |> Enum.reject(&(&1 == current_proposal_id))
    else
      []
    end
  end

  defp calculate_depth(proposal_id, current_depth) do
    supersedes_chain = get_supersedes_chain(proposal_id)
    current_depth + length(supersedes_chain)
  end

  defp calculate_completeness(present_required, required_events, present_optional, optional_events) do
    required_score = length(present_required) / max(length(required_events), 1)
    optional_score = length(present_optional) / max(length(optional_events), 1)
    
    (required_score * 0.7 + optional_score * 0.3) |> Float.round(2)
  end
end
