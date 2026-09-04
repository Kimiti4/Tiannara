defmodule Tiannara.CCI.CivilizationRiskIntelligence do
  @moduledoc """
  Civilization Risk Intelligence (CRI): detects epistemic, structural, and governance
  threats at civilizational scale.
  Categories: epistemic threats, structural threats, governance threats.
  """
  use GenServer
  alias Tiannara.CCI.Models.CivilizationalRisk

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{}, opts)

  def assess_risks(pid, civ_state), do: GenServer.call(pid, {:assess, civ_state})
  def get_active_risks(pid), do: GenServer.call(pid, :active)
  def propose_mitigation(pid, risk_id), do: GenServer.call(pid, {:mitigate, risk_id})

  @impl true
  def init(_), do: {:ok, %{risks: %{}, assessments: []}}

  @impl true
  def handle_call({:assess, civ_state}, _from, state) do
    risks = detect_risks(civ_state)
    assessment = %{
      timestamp: DateTime.utc_now(),
      risks: risks,
      overall_risk_level: calculate_overall_risk(risks),
      critical_count: Enum.count(risks, & &1.severity == :critical),
      elevated_count: Enum.count(risks, & &1.severity == :elevated)
    }

    state = %{state |
      risks: Enum.reduce(risks, state.risks, fn r, acc -> Map.put(acc, r.id, r) end),
      assessments: [assessment | state.assessments] |> Enum.take(100)
    }
    {:reply, {:ok, assessment}, state}
  end

  @impl true
  def handle_call(:active, _from, state) do
    active = state.risks |> Map.values() |> Enum.filter(& &1.severity in [:critical, :elevated])
    {:reply, active, state}
  end

  @impl true
  def handle_call({:mitigate, risk_id}, _from, state) do
    case Map.get(state.risks, risk_id) do
      nil -> {:reply, {:error, :not_found}, state}
      risk ->
        mitigation = propose_mitigation_options(risk)
        {:reply, {:ok, mitigation}, state}
    end
  end

  defp detect_risks(civ_state) do
    epistemic = detect_epistemic_risks(civ_state)
    structural = detect_structural_risks(civ_state)
    governance = detect_governance_risks(civ_state)
    epistemic ++ structural ++ governance
  end

  defp detect_epistemic_risks(civ_state) do
    if civ_state.knowledge_state.pending_validation > civ_state.knowledge_state.validated_assets * 0.3 do
      [%CivilizationalRisk{
        id: UUID.uuid4(), category: :epistemic, timestamp: DateTime.utc_now(),
        description: "High ratio of unvalidated knowledge may introduce false assumptions",
        severity: :elevated, probability: 0.6, impact: :high,
        early_indicators: [:pending_validation_ratio],
        mitigation_options: [:increase_validation_throughput, :prioritize_critical_validations],
        confidence: 0.7, evidence: [:knowledge_state_metrics],
        requires_immediate_action: false
      }]
    else
      []
    end
  end

  defp detect_structural_risks(civ_state) do
    if civ_state.capability_state.emerging > civ_state.capability_state.promoted * 2 do
      [%CivilizationalRisk{
        id: UUID.uuid4(), category: :structural, timestamp: DateTime.utc_now(),
        description: "Capability emergence outpacing promotion suggests selection bottleneck",
        severity: :elevated, probability: 0.5, impact: :medium,
        early_indicators: [:capability_emergence_promotion_ratio],
        mitigation_options: [:diversify_selection_criteria, :reduce_selection_pressure],
        confidence: 0.65, evidence: [:capability_state_metrics],
        requires_immediate_action: false
      }]
    else
      []
    end
  end

  defp detect_governance_risks(civ_state) do
    if civ_state.institutional_state.active < 3 do
      [%CivilizationalRisk{
        id: UUID.uuid4(), category: :governance, timestamp: DateTime.utc_now(),
        description: "Low institutional count may lead to power concentration",
        severity: :critical, probability: 0.7, impact: :critical,
        early_indicators: [:institutional_count],
        mitigation_options: [:encourage_institution_formation, :distribute_authority],
        confidence: 0.8, evidence: [:institutional_state_metrics],
        requires_immediate_action: true
      }]
    else
      []
    end
  end

  defp calculate_overall_risk(risks) do
    critical = Enum.count(risks, & &1.severity == :critical)
    elevated = Enum.count(risks, & &1.severity == :elevated)
    cond do
      critical > 0 -> :critical
      elevated > 2 -> :elevated
      elevated > 0 -> :moderate
      true -> :nominal
    end
  end

  defp propose_mitigation_options(risk) do
    %{
      risk_id: risk.id,
      options: Enum.map(risk.mitigation_options, fn opt ->
        %{
          option: opt,
          expected_effectiveness: 0.7,
          resource_cost: 50,
          risk: 0.1,
          requires_human_approval: true
        }
      end),
      recommendation: Enum.at(risk.mitigation_options, 0)
    }
  end
end
