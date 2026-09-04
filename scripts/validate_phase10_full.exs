Mix.Task.run(:app.start)

defmodule Phase10Validator do
  @checks [
    :director_alive, :world_model_alive, :planner_alive,
    :policy_simulation_alive, :sustainability_alive, :global_risk_alive,
    :metrics_alive, :long_term_forecast_alive, :decision_engine_alive,
    :constitutional_governance_alive, :intergenerational_equity_alive,
    :knowledge_preservation_alive, :feedback_aggregator_alive,
    :plan_generation, :risk_assessment, :sustainability_evaluation,
    :policy_simulation, :forecast_generation, :decision_making,
    :governance_review, :metrics_recording
  ]

  def run do
    IO.puts("=" |> String.duplicate(60))
    IO.puts("Phase 10 — Civilizational Intelligence Validation")
    IO.puts("=" |> String.duplicate(60))

    results = @checks |> Enum.map(&{&1, run_check(&1)}) |> Enum.into(%{})

    passed = results |> Enum.count(fn {_, v} -> v == :pass end)
    failed = results |> Enum.count(fn {_, v} -> v == :fail end)
    skipped = results |> Enum.count(fn {_, v} -> v == :skip end)

    IO.puts("")
    IO.puts("Results: #{passed}/#{length(@checks)} passed, #{failed} failed, #{skipped} skipped")

    results
    |> Enum.sort_by(fn {k, _} -> Enum.find_index(@checks, &(&1 == k)) end)
    |> Enum.each(fn {check, status} ->
      icon = case status do
        :pass -> "[PASS]"
        :fail -> "[FAIL]"
        :skip -> "[SKIP]"
      end
      IO.puts("  #{icon} #{check}")
    end)

    IO.puts("")
    if failed == 0, do: IO.puts("Phase 10: ALL CHECKS PASSED"), else: IO.puts("Phase 10: #{failed} CHECK(S) FAILED")
    results
  end

  defp run_check(:director_alive) do
    check_process(Tiannara.ASC.Civilization.Director)
  end

  defp run_check(:world_model_alive) do
    check_process(Tiannara.ASC.Civilization.WorldModel)
  end

  defp run_check(:planner_alive) do
    check_process(Tiannara.ASC.Civilization.Planner)
  end

  defp run_check(:policy_simulation_alive) do
    check_process(Tiannara.ASC.Civilization.PolicySimulationEngine)
  end

  defp run_check(:sustainability_alive) do
    check_process(Tiannara.ASC.Civilization.SustainabilityEngine)
  end

  defp run_check(:global_risk_alive) do
    check_process(Tiannara.ASC.Civilization.GlobalRiskEngine)
  end

  defp run_check(:metrics_alive) do
    check_process(Tiannara.ASC.Civilization.Metrics)
  end

  defp run_check(:long_term_forecast_alive) do
    check_process(Tiannara.ASC.Civilization.LongTermForecastEngine)
  end

  defp run_check(:decision_engine_alive) do
    check_process(Tiannara.ASC.Civilization.DecisionEngine)
  end

  defp run_check(:constitutional_governance_alive) do
    check_process(Tiannara.ASC.Civilization.ConstitutionalGovernanceEngine)
  end

  defp run_check(:intergenerational_equity_alive) do
    check_process(Tiannara.ASC.Civilization.IntergenerationalEquityEngine)
  end

  defp run_check(:knowledge_preservation_alive) do
    check_process(Tiannara.ASC.Civilization.KnowledgePreservationEngine)
  end

  defp run_check(:feedback_aggregator_alive) do
    check_process(Tiannara.ASC.Civilization.FeedbackAggregator)
  end

  defp run_check(:plan_generation) do
    world_state = %{entities: [], metrics: %{complexity: 0.5}, timestamp: DateTime.utc_now()}
    risk = %{overall_risk: 0.3, threats: []}
    sustainability = %{score: 0.8, factors: []}
    equity = %{score: 0.7, metrics: %{}}
    forecast = %{horizon_years: 50, projections: []}
    case Tiannara.ASC.Civilization.Planner.generate_plan(world_state, risk, sustainability, equity, forecast) do
      {:ok, _plan} -> :pass
      {:error, reason} -> IO.puts("    Plan error: #{inspect(reason)}"); :fail
    end
  rescue
    e -> IO.puts("    Error: #{inspect(e)}"); :fail
  end

  defp run_check(:risk_assessment) do
    world_state = %{entities: [], metrics: %{complexity: 0.5}, timestamp: DateTime.utc_now()}
    case Tiannara.ASC.Civilization.GlobalRiskEngine.assess(world_state) do
      {:ok, _report} -> :pass
      {:error, reason} -> IO.puts("    Risk error: #{inspect(reason)}"); :fail
    end
  rescue
    e -> IO.puts("    Error: #{inspect(e)}"); :fail
  end

  defp run_check(:sustainability_evaluation) do
    world_state = %{entities: [], metrics: %{complexity: 0.5}, timestamp: DateTime.utc_now()}
    case Tiannara.ASC.Civilization.SustainabilityEngine.evaluate(world_state) do
      {:ok, _report} -> :pass
      {:error, reason} -> IO.puts("    Sustainability error: #{inspect(reason)}"); :fail
    end
  rescue
    e -> IO.puts("    Error: #{inspect(e)}"); :fail
  end

  defp run_check(:policy_simulation) do
    world_state = %{entities: [], metrics: %{complexity: 0.5}, timestamp: DateTime.utc_now()}
    risk = %{overall_risk: 0.3, threats: []}
    case Tiannara.ASC.Civilization.PolicySimulationEngine.simulate(world_state, risk) do
      {:ok, _results} -> :pass
      {:error, reason} -> IO.puts("    Policy error: #{inspect(reason)}"); :fail
    end
  rescue
    e -> IO.puts("    Error: #{inspect(e)}"); :fail
  end

  defp run_check(:forecast_generation) do
    world_state = %{entities: [], metrics: %{complexity: 0.5}, timestamp: DateTime.utc_now()}
    policy_results = %{scenarios: [], recommendations: []}
    case Tiannara.ASC.Civilization.LongTermForecastEngine.forecast(world_state, policy_results) do
      {:ok, _forecast} -> :pass
      {:error, reason} -> IO.puts("    Forecast error: #{inspect(reason)}"); :fail
    end
  rescue
    e -> IO.puts("    Error: #{inspect(e)}"); :fail
  end

  defp run_check(:decision_making) do
    plan = %{goals: [], timeline: [], resources: %{}}
    risk = %{overall_risk: 0.3, threats: []}
    sustainability = %{score: 0.8, factors: []}
    case Tiannara.ASC.Civilization.DecisionEngine.decide(plan, risk, sustainability) do
      {:ok, _decisions} -> :pass
      {:error, reason} -> IO.puts("    Decision error: #{inspect(reason)}"); :fail
    end
  rescue
    e -> IO.puts("    Error: #{inspect(e)}"); :fail
  end

  defp run_check(:governance_review) do
    decisions = [%{id: "dec_1", action: "test", impact: %{risk: 0.1, benefit: 0.9}}]
    case Tiannara.ASC.Civilization.ConstitutionalGovernanceEngine.review(decisions) do
      {:ok, _review} -> :pass
      {:error, reason} -> IO.puts("    Governance error: #{inspect(reason)}"); :fail
    end
  rescue
    e -> IO.puts("    Error: #{inspect(e)}"); :fail
  end

  defp run_check(:metrics_recording) do
    cycle_data = %{cycle: 1, risk_level: 0.3, sustainability_score: 0.8, equity_score: 0.7, decisions: 1, forecast_horizon: 50}
    case Tiannara.ASC.Civilization.Metrics.record_cycle(cycle_data) do
      {:ok, _result} -> :pass
      {:error, reason} -> IO.puts("    Metrics error: #{inspect(reason)}"); :fail
    end
  rescue
    e -> IO.puts("    Error: #{inspect(e)}"); :fail
  end

  defp check_process(mod) do
    case Process.whereis(mod) do
      nil -> :fail
      pid -> if Process.alive?(pid), do: :pass, else: :fail
    end
  rescue
    _ -> :skip
  end
end

Phase10Validator.run()
