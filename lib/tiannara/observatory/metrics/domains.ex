defmodule Tiannara.Observatory.Metrics.Domains do
  def get_dashboard_data do
    case Tiannara.Domains.ResearchDirector.get_all_metrics() do
      {:ok, metrics} ->
        Enum.map(metrics, fn {domain, data} ->
          %{name: domain, hypotheses: data.active_hypotheses, experiments: data.open_experiments, velocity: data.knowledge_growth_rate, confidence: data.evidence_quality_score}
        end)
      _ -> []
    end
  end
end
