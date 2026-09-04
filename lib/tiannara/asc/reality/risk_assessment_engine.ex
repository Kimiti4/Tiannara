defmodule Tiannara.ASC.Reality.RiskAssessmentEngine do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def assess(artifact, params \\ %{}) do
    GenServer.call(__MODULE__, {:assess, artifact, params})
  end

  def get_risk_profile do
    GenServer.call(__MODULE__, :get_profile)
  end

  def list_mitigations do
    GenServer.call(__MODULE__, :list_mitigations)
  end

  @impl true
  def init(:ok) do
    {:ok, %{assessments: [], risk_profile: %{}, mitigations: []}}
  end

  @impl true
  def handle_call({:assess, artifact, params}, _from, state) do
    risks = identify_risks(artifact, params)
    scores = score_risks(risks)
    mitigations = propose_mitigations(risks, scores)
    overall_score = calculate_overall_risk(scores)

    profile = %{
      artifact: artifact,
      timestamp: DateTime.utc_now(),
      risks: risks,
      scores: scores,
      overall_risk_score: overall_score,
      mitigations: mitigations,
      is_acceptable: overall_score < 0.7
    }

    {:reply, {:ok, profile},
     %{state | assessments: [profile | state.assessments], risk_profile: profile}}
  end

  def handle_call(:get_profile, _from, state) do
    {:reply, state.risk_profile, state}
  end

  def handle_call(:list_mitigations, _from, state) do
    {:reply, state.mitigations, state}
  end

  defp identify_risks(artifact, params) do
    risks = []

    risks = if Map.get(artifact, :uncertainty_level) == :high do
      [%{id: :high_uncertainty, severity: :high, category: :technical, description: "High uncertainty artifact"}| risks]
    else
      risks
    end

    risks = if Map.get(artifact, :real_world_interaction) == true do
      [
        %{id: :physical_safety, severity: :critical, category: :safety,
          description: "Physical world interaction requires safety verification"},
        %{id: :regulatory, severity: :high, category: :compliance,
          description: "Regulatory compliance needed for real-world deployment"}
      | risks]
    else
      risks
    end

    risks = case params[:rollout_speed] do
      :fast -> [%{id: :rollout_too_fast, severity: :medium, category: :operational,
                   description: "Fast rollout increases blast radius risk"} | risks]
      _ -> risks
    end

    if risks == [], do: [
      %{id: :default_risk, severity: :low, category: :general,
        description: "Standard deployment risk assessment"}
    ], else: risks
  end

  defp score_risks(risks) do
    Enum.map(risks, fn risk ->
      base_score = case risk.severity do
        :critical -> 0.9
        :high -> 0.7
        :medium -> 0.4
        :low -> 0.1
      end
      Map.put(risk, :score, base_score)
    end)
  end

  defp propose_mitigations(risks, _scores) do
    Enum.map(risks, fn risk ->
      mitigation = case risk.id do
        :high_uncertainty -> %{id: :reduce_uncertainty, action: "Run additional simulations before deployment"}
        :physical_safety -> %{id: :safety_protocols, action: "Engage safety interlock systems"}
        :regulatory -> %{id: :compliance_check, action: "Submit for regulatory review"}
        :rollout_too_fast -> %{id: :slow_rollout, action: "Reduce rollout speed to gradual canary"}
        _ -> %{id: :standard_mitigation, action: "Apply standard risk mitigation procedures"}
      end
      Map.put(risk, :proposed_mitigation, mitigation)
    end)
  end

  defp calculate_overall_risk(scores) do
    count = length(scores)
    if count == 0, do: 0.0, else: Enum.reduce(scores, 0.0, fn s, acc -> acc + s.score end) / count
  end
end
