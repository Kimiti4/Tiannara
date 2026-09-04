defmodule Tiannara.ASC.Reality.EnvironmentalImpactEngine do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def assess(artifact, params \\ %{}) do
    GenServer.call(__MODULE__, {:assess, artifact, params})
  end

  def get_sustainability_score(deployment_id \\ nil) do
    GenServer.call(__MODULE__, {:sustainability, deployment_id})
  end

  def get_carbon_footprint_history do
    GenServer.call(__MODULE__, :carbon_history)
  end

  @impl true
  def init(:ok) do
    {:ok, %{assessments: [], carbon_history: [], total_carbon_kg: 0}}
  end

  @impl true
  def handle_call({:assess, artifact, params}, _from, state) do
    compute_carbon = estimate_compute_carbon(params)
    infrastructure_carbon = estimate_infrastructure_carbon(params)
    total_carbon = compute_carbon + infrastructure_carbon
    sustainability_score = calculate_sustainability_score(compute_carbon, infrastructure_carbon, params)

    assessment = %{
      artifact: artifact,
      timestamp: DateTime.utc_now(),
      carbon_footprint_kg: %{
        compute: compute_carbon,
        infrastructure: infrastructure_carbon,
        total: total_carbon
      },
      sustainability_score: sustainability_score,
      recommendations: generate_recommendations(sustainability_score),
      energy_source: params[:energy_source] || :mixed
    }

    {:reply, {:ok, assessment},
     %{state | assessments: [assessment | state.assessments],
               carbon_history: [{DateTime.utc_now(), total_carbon} | state.carbon_history],
               total_carbon_kg: state.total_carbon_kg + total_carbon}}
  end

  def handle_call({:sustainability, deployment_id}, _from, state) do
    result = case deployment_id do
      nil ->
        scores = Enum.map(state.assessments, fn a -> a.sustainability_score end)
        avg = if length(scores) > 0, do: Enum.sum(scores) / length(scores), else: 0.0
        %{average_sustainability: avg, total_assessments: length(state.assessments)}
      id ->
        assessment = Enum.find(state.assessments, fn a ->
          case a.artifact do
            %{deployment_id: ^id} -> true
            _ -> false
          end
        end)
        case assessment do
          nil -> nil
          _ -> %{sustainability_score: assessment.sustainability_score, carbon: assessment.carbon_footprint_kg}
        end
    end
    {:reply, result, state}
  end

  def handle_call(:carbon_history, _from, state) do
    {:reply, %{history: state.carbon_history, total_carbon_kg: state.total_carbon_kg}, state}
  end

  defp estimate_compute_carbon(params) do
    compute_hours = params[:estimated_compute_hours] || 100
    carbon_intensity = params[:carbon_intensity_g_per_kwh] || 400
    power_kw = params[:power_kw] || 0.5
    (compute_hours * power_kw * carbon_intensity) / 1000.0
  end

  defp estimate_infrastructure_carbon(_params) do
    50.0
  end

  defp calculate_sustainability_score(compute_carbon, infra_carbon, params) do
    total = compute_carbon + infra_carbon
    energy_multiplier = case params[:energy_source] do
      :renewable -> 0.3
      :nuclear -> 0.4
      :mixed -> 0.6
      :fossil -> 0.9
      _ -> 0.6
    end

    base_score = max(0, 1.0 - (total / 1000.0))
    base_score * (1.0 - energy_multiplier) + energy_multiplier
  end

  defp generate_recommendations(score) when score >= 0.8 do
    ["Current environmental impact is low", "Consider carbon offset programs", "Maintain current energy efficiency practices"]
  end

  defp generate_recommendations(score) when score >= 0.5 do
    ["Moderate environmental impact detected", "Consider migrating to renewable energy sources",
     "Optimize compute resource utilization", "Implement energy-efficient scheduling"]
  end

  defp generate_recommendations(_score) do
    ["High environmental impact detected!", "Immediately migrate to renewable energy sources",
     "Reduce compute footprint through optimization", "Consider carbon offset purchases",
     "Audit infrastructure for energy efficiency improvements"]
  end
end
