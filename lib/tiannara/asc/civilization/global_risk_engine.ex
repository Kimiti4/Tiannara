defmodule Tiannara.ASC.Civilization.GlobalRiskEngine do
  use GenServer

  @categories [:pandemic, :climate, :economic_shock, :technological, :geopolitical, :existential]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def assess(world_state) do
    GenServer.call(__MODULE__, {:assess, world_state})
  end

  @impl true
  def init(_opts), do: {:ok, %{assessments: 0}}

  @impl true
  def handle_call({:assess, world_state}, _from, state) do
    risks = Enum.map(@categories, fn cat -> assess_category(cat, world_state) end)
    overall = Enum.sum(Enum.map(risks, & &1.probability)) / length(risks)

    result = %{
      overall_risk: overall, risks: risks,
      highest_risk: Enum.max_by(risks, & &1.probability),
      recommendations: gen_recommendations(risks), assessed_at: DateTime.utc_now()
    }
    {:reply, {:ok, result}, %{state | assessments: state.assessments + 1}}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp assess_category(:pandemic, ws), do: %{category: :pandemic, probability: max(0.05, 0.3 - Map.get(ws, :medicine, 0.6) * 0.2), severity: :high, mitigation: "Strengthen global health surveillance"}
  defp assess_category(:climate, ws), do: %{category: :climate, probability: max(0.1, 0.6 - Map.get(ws, :ecology, 0.4) * 0.4), severity: :critical, mitigation: "Accelerate decarbonization"}
  defp assess_category(:economic_shock, ws), do: %{category: :economic_shock, probability: max(0.05, 0.4 - Map.get(ws, :economics, 0.5) * 0.3), severity: :high, mitigation: "Diversify economic systems"}
  defp assess_category(:technological, _ws), do: %{category: :technological, probability: 0.15, severity: :medium, mitigation: "Responsible development frameworks"}
  defp assess_category(:geopolitical, ws), do: %{category: :geopolitical, probability: max(0.1, 0.4 - Map.get(ws, :governance, 0.5) * 0.3), severity: :high, mitigation: "Strengthen international cooperation"}
  defp assess_category(:existential, _ws), do: %{category: :existential, probability: 0.02, severity: :critical, mitigation: "Existential risk monitoring and prevention"}

  defp gen_recommendations(risks) do
    risks
    |> Enum.filter(&(&1.probability > 0.2))
    |> Enum.map(fn r -> %{priority: if(r.severity == :critical, do: :critical, else: :high), category: r.category, action: r.mitigation} end)
  end
end
