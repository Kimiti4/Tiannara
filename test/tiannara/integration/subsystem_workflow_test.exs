defmodule Tiannara.Integration.SubsystemWorkflowTest do
  use ExUnit.Case, async: false

  alias Tiannara.ASC.Research.Director
  alias Tiannara.Evolution.EvolutionEngine
  alias TiannaraOS.ProgramSelfEvaluation

  setup do
    case Director.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    case EvolutionEngine.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    :ok
  end

  test "research, evolution, and self-evaluation compose into a single bounded workflow" do
    {:ok, program_id} =
      Director.submit_program(%{
        name: "Causal model refinement",
        domain: :physics,
        objective: "Improve predictive confidence under sparse evidence",
        priority: :high,
        resources: %{compute: 200, time_hours: 20}
      })

    assert is_binary(program_id)

    active = Director.active_programs()
    assert Enum.any?(active, &(&1.id == program_id))

    program = %{
      id: program_id,
      goals: ["confirm model", "validate mechanism"],
      discoveries: ["d1", "d2", "d3"],
      evidence_ids: ["e1", "e2"],
      metrics: %{
        discovery_yield: 0.8,
        candidates_produced: 12,
        candidates_validated: 7,
        retention_rate: 0.9
      },
      budget: %{credits: 1800, compute: 700, attention: 300},
      active_experiments: ["exp_1"],
      capabilities: %{causal_modeling: true},
      life_stage: :juvenile,
      born_at_tick: 0,
      hypotheses: [%{id: "h1"}, %{id: "h2"}],
      strategy_genome: %{
        exploration_rate: 0.5,
        validation_priority: 0.8,
        cross_domain_synthesis: 0.7,
        anomaly_sensitivity: 0.6,
        risk_tolerance: 0.4
      }
    }

    evaluation = ProgramSelfEvaluation.evaluate_program(program, 2000, %{})

    assert evaluation.program_id == program_id

    assert evaluation.progress_assessment.status in [
             :on_track,
             :near_completion,
             :behind_schedule,
             :significantly_behind
           ]

    assert is_list(evaluation.adaptive_recommendations)

    EvolutionEngine.trigger_evolution()
    assert is_list(EvolutionEngine.lineage())
    assert is_map(EvolutionEngine.stats())
  end
end
