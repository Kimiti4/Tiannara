defmodule Tiannara.ASC.Civilization.DecisionEngine do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def decide(plan, risk, sustainability) do
    GenServer.call(__MODULE__, {:decide, plan, risk, sustainability}, 30_000)
  end

  @impl true
  def init(_opts), do: {:ok, %{decisions: 0}}

  @impl true
  def handle_call({:decide, plan, risk, sustainability}, _from, state) do
    decisions = generate_decisions(plan, risk, sustainability)
    {:reply, {:ok, decisions}, %{state | decisions: state.decisions + length(decisions)}}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp generate_decisions(plan, risk, sustainability) do
    risk_decisions = if risk.overall_risk > 0.4 do
      [%{
        id: "dec_risk_#{random_id()}", type: :risk_mitigation,
        action: "Invest in risk reduction for #{risk.highest_risk.category}",
        confidence: 0.7, uncertainty: 0.3,
        evidence: "Overall risk #{Float.round(risk.overall_risk, 2)} exceeds threshold",
        alternatives: ["Accept risk", "Transfer risk", "Avoid risk"],
        trade_offs: "Risk reduction requires resource allocation from other priorities",
        requires_human_approval: risk.overall_risk > 0.6
      }]
    else [] end

    sust_decisions = if sustainability.score < 0.5 do
      [%{
        id: "dec_sust_#{random_id()}", type: :sustainability_investment,
        action: "Prioritize sustainability improvements",
        confidence: 0.8, uncertainty: 0.2,
        evidence: "Sustainability score #{Float.round(sustainability.score, 2)} below threshold",
        alternatives: ["Maintain current trajectory", "Aggressive intervention"],
        trade_offs: "Sustainability investment may slow short-term growth",
        requires_human_approval: false
      }]
    else [] end

    plan_decisions = Enum.map(Map.get(plan, :priorities, []), fn priority ->
      %{
        id: "dec_plan_#{random_id()}", type: :strategic_priority,
        action: "Pursue #{priority.priority}",
        confidence: 0.6, uncertainty: 0.4,
        evidence: "Identified as priority in civilizational plan",
        alternatives: ["Defer", "Delegate", "Decompose"],
        trade_offs: "Opportunity cost of not pursuing other priorities",
        requires_human_approval: priority.urgency == :high
      }
    end)

    risk_decisions ++ sust_decisions ++ plan_decisions
  end

  defp random_id, do: :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
end
