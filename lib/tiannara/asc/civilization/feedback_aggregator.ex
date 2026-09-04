defmodule Tiannara.ASC.Civilization.FeedbackAggregator do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def aggregate_and_feed_back(cycle_data) do
    GenServer.cast(__MODULE__, {:aggregate, cycle_data})
  end

  def feedback_history, do: GenServer.call(__MODULE__, :history)

  @impl true
  def init(_opts), do: {:ok, %{history: [], total_feedback: 0}}

  @impl true
  def handle_cast({:aggregate, cycle_data}, state) do
    feedback = %{
      cycle: Map.get(cycle_data, :cycle),
      strategic_priorities: extract_priorities(cycle_data),
      risk_alerts: extract_risk_alerts(cycle_data),
      sustainability_directives: extract_sustainability_directives(cycle_data),
      methodology_improvements: extract_methodology_improvements(cycle_data),
      resource_reallocation: extract_resource_reallocation(cycle_data),
      aggregated_at: DateTime.utc_now()
    }

    Tiannara.Operations.CampaignIntegration.route_result(:phase10, %{
      status: :completed, feedback: feedback,
      cycle: Map.get(cycle_data, :cycle), completed_at: DateTime.utc_now()
    })

    Logger.info("FeedbackAggregator: Loop closed — Cycle #{Map.get(cycle_data, :cycle)} feedback sent to Phase 5")

    {:noreply, %{state | history: [feedback | state.history] |> Enum.take(200), total_feedback: state.total_feedback + 1}}
  end

  @impl true
  def handle_call(:history, _from, state), do: {:reply, state.history, state}
  def handle_info(_, state), do: {:noreply, state}

  defp extract_priorities(cycle_data), do: Map.get(Map.get(cycle_data, :plan, %{}), :priorities, [])
  defp extract_risk_alerts(cycle_data) do
    risk = Map.get(cycle_data, :risk, %{})
    if Map.get(risk, :overall_risk, 0) > 0.5, do: [%{level: :high, message: "Elevated civilizational risk: #{Float.round(risk.overall_risk, 2)}"}], else: []
  end
  defp extract_sustainability_directives(cycle_data) do
    s = Map.get(cycle_data, :sustainability, %{})
    if Map.get(s, :score, 1.0) < 0.5, do: [%{directive: "Prioritize sustainability in all Phase 8 engineering decisions"}], else: []
  end
  defp extract_methodology_improvements(cycle_data) do
    f = Map.get(cycle_data, :forecast, %{})
    if Map.get(f, :confidence, 1.0) < 0.5, do: [%{improvement: "Improve long-term forecasting methodology (low confidence)"}], else: []
  end
  defp extract_resource_reallocation(cycle_data) do
    priorities = Map.get(Map.get(cycle_data, :plan, %{}), :priorities, [])
    if priorities != [], do: [%{action: "Reallocate resources toward top civilizational priorities", priorities: Enum.map(priorities, & &1.priority)}], else: []
  end
end
