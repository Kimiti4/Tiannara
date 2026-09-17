defmodule TiannaraRuntime.Civilization.Portfolio.BottleneckAnalyzer do
  def initialize() do
    {:ok, %{bottlenecks: [], categories: [:scientific, :engineering, :infrastructure, :economic, :institutional, :knowledge, :resource, :governance]}}
  end

  def analyze(analyzer, civilization) do
    bottlenecks = Enum.reduce(analyzer.categories, [], fn cat, acc ->
      metric_key = case cat do
        :scientific -> :research_output
        :engineering -> :engineering_capacity
        :infrastructure -> :infrastructure_health
        :economic -> :economic_output
        :institutional -> :institutional_stability
        :knowledge -> :knowledge_diffusion
        :resource -> :resource_availability
        :governance -> :governance_effectiveness
      end
      value = Map.get(civilization, metric_key, 1.0)
      if value < 0.3 do
        severity = 1.0 - value
        [%{category: cat, severity: severity, dependencies: [], affected_domains: [cat]} | acc]
      else
        acc
      end
    end)
    {:ok, %{analyzer | bottlenecks: bottlenecks}}
  end

  def get_bottlenecks(analyzer, severity_threshold) do
    filtered = Enum.filter(analyzer.bottlenecks, fn b -> Map.get(b, :severity) >= severity_threshold end)
    {:ok, filtered}
  end

  def metrics(analyzer) do
    by_category = Enum.reduce(analyzer.bottlenecks, %{}, fn b, acc ->
      cat = Map.get(b, :category)
      Map.put(acc, cat, Map.get(acc, cat, 0) + 1)
    end)
    {:ok, %{total: length(analyzer.bottlenecks), by_category: by_category}}
  end
end
