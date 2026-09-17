defmodule TiannaraOS.ProgramSelfEvaluationTest do
  use ExUnit.Case, async: false

  alias TiannaraOS.ProgramSelfEvaluation

  test "evaluates a program in a bounded, observable way" do
    program = %{
      id: "prog_self_eval_1",
      goals: ["confirm mechanism", "validate evidence"],
      discoveries: ["d1", "d2"],
      evidence_ids: ["e1", "e2", "e3"],
      metrics: %{
        discovery_yield: 0.7,
        candidates_produced: 10,
        candidates_validated: 6,
        retention_rate: 0.82
      },
      budget: %{credits: 1200, compute: 500, attention: 200},
      active_experiments: ["exp_1", "exp_2"],
      capabilities: %{modeling: true, validation: true},
      life_stage: :juvenile,
      born_at_tick: 0,
      hypotheses: [%{id: "h1"}, %{id: "h2"}, %{id: "h3"}],
      strategy_genome: %{
        exploration_rate: 0.6,
        validation_priority: 0.7,
        cross_domain_synthesis: 0.5,
        anomaly_sensitivity: 0.4,
        risk_tolerance: 0.3
      }
    }

    result = ProgramSelfEvaluation.evaluate_program(program, 5000, %{})

    assert result.program_id == "prog_self_eval_1"
    assert result.evaluation_tick == 5000
    assert result.life_stage == :apprentice
    assert result.progress_assessment.completion_percentage >= 0.0
    assert is_list(result.adaptive_recommendations)
    assert result.budget_health.budget_status in [:healthy, :adequate, :concerning, :critical]
    assert result.discovery_rate.conversion_rate >= 0.0
  end

  test "flags program termination only under severe budget and progress conditions" do
    program = %{
      id: "prog_self_eval_2",
      goals: ["goal_a"],
      discoveries: [],
      evidence_ids: [],
      metrics: %{discovery_yield: 0.05},
      budget: %{credits: 10, compute: 10, attention: 10},
      active_experiments: [],
      capabilities: %{},
      life_stage: :adult,
      born_at_tick: 0,
      hypotheses: [],
      strategy_genome: %{
        exploration_rate: 0.4,
        validation_priority: 0.2,
        cross_domain_synthesis: 0.1,
        anomaly_sensitivity: 0.2,
        risk_tolerance: 0.1
      }
    }

    assessment =
      ProgramSelfEvaluation.assess_termination_need(program, %{budget_status: :critical}, %{
        completion_percentage: 0
      })

    assert assessment.termination_recommended == true
    assert assessment.termination_urgency in [:immediate, :soon, :planned, :none]
  end
end
