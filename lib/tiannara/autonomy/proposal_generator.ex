defmodule Tiannara.Autonomy.ProposalGenerator do
  @moduledoc """
  Proposal Generator — generates structured improvement proposals.
  Transforms identified opportunities into formal proposals.
  """

  use GenServer
  require Logger
  alias Tiannara.Executive.Types

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec generate([map()]) :: [map()]
  def generate(opportunities) do
    GenServer.call(__MODULE__, {:generate, opportunities}, 30_000)
  end

  @spec submit_manual(map()) :: {:ok, binary()} | {:error, term()}
  def submit_manual(proposal_data) do
    GenServer.call(__MODULE__, {:submit_manual, proposal_data})
  end

  @spec active_count() :: non_neg_integer()
  def active_count do
    GenServer.call(__MODULE__, :active_count)
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @impl true
  def init(_opts) do
    {:ok, %{proposals: %{}, total_generated: 0, total_manual: 0}}
  end

  @impl true
  def handle_call({:generate, opportunities}, _from, state) do
    proposals = Enum.map(opportunities, &opportunity_to_proposal/1)
    new_proposals = Enum.reduce(proposals, state.proposals, fn p, acc -> Map.put(acc, p.id, p) end)
    :telemetry.execute([:tiannara, :autonomy, :proposals_generated], %{count: length(proposals)}, %{categories: Enum.map(proposals, & &1.category)})
    {:reply, proposals, %{state | proposals: new_proposals, total_generated: state.total_generated + length(proposals)}}
  end

  @impl true
  def handle_call({:submit_manual, proposal_data}, _from, state) do
    proposal = %{id: Types.new_id(), title: proposal_data[:title] || "Manual improvement proposal", objective: proposal_data[:objective] || "", rationale: proposal_data[:rationale] || "Submitted by human operator.", category: proposal_data[:category] || :manual, target: proposal_data[:target] || :unspecified, expected_impact: proposal_data[:expected_impact] || 0.5, confidence: proposal_data[:confidence] || 0.5, risk_level: proposal_data[:risk_level] || :medium, resource_requirements: proposal_data[:resources] || [:cpu], rollback_plan: proposal_data[:rollback_plan] || "Revert to previous state.", constitutional_compliance: proposal_data[:compliance] || "Pending validation.", human_approval_required: true, source_opportunity_id: nil, status: :submitted, created_at: DateTime.utc_now(), lineage: %{source: :human_operator, submitted_at: DateTime.utc_now()}}
    {:reply, {:ok, proposal.id}, %{state | proposals: Map.put(state.proposals, proposal.id, proposal), total_manual: state.total_manual + 1}}
  end

  @impl true
  def handle_call(:active_count, _from, state) do
    active = state.proposals |> Map.values() |> Enum.count(fn p -> p.status in [:draft, :submitted, :approved] end)
    {:reply, active, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{total_proposals: map_size(state.proposals), total_generated: state.total_generated, total_manual: state.total_manual, by_status: state.proposals |> Map.values() |> Enum.frequencies_by(& &1.status)}, state}
  end

  defp opportunity_to_proposal(opportunity) do
    risk = assess_risk(opportunity)
    human_required = risk in [:high, :critical] or opportunity.estimated_impact > 0.8

    %{id: Types.new_id(), title: "#{opportunity.category}: #{opportunity.target} improvement",
      objective: "Address: #{opportunity.description} Expected impact: #{Float.round(opportunity.estimated_impact * 100, 1)}% improvement.",
      rationale: "Evidence indicates #{opportunity.category} improvement opportunity at #{opportunity.target}. Confidence: #{Float.round(opportunity.confidence * 100, 1)}%.",
      category: opportunity.category, target: opportunity.target, expected_impact: opportunity.estimated_impact,
      confidence: opportunity.confidence, risk_level: risk, resource_requirements: [:cpu, :benchmark_runner],
      rollback_plan: "Revert to previous configuration. Restore checkpoint. Verify system health post-rollback.",
      constitutional_compliance: "Compliant: verification precedes deployment; rollback available; lineage preserved; human approval #{if human_required, do: "required", else: "not required"}.",
      human_approval_required: human_required, source_opportunity_id: opportunity.id, status: :draft,
      created_at: DateTime.utc_now(), lineage: %{source: :improvement_engine, opportunity_id: opportunity.id, evidence: opportunity.evidence, identified_at: opportunity.identified_at}}
  end

  defp assess_risk(%{category: :performance, confidence: c}) when c > 0.8, do: :low
  defp assess_risk(%{category: :scalability}), do: :medium
  defp assess_risk(%{estimated_impact: impact}) when impact > 0.9, do: :high
  defp assess_risk(%{confidence: c}) when c < 0.5, do: :high
  defp assess_risk(_), do: :medium
end
