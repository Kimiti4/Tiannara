defmodule TiannaraRuntime.AutonomousResearch.ValidationCampaignTest do
  use ExUnit.Case, async: false
  @moduletag :campaign

  alias TiannaraRuntime.WorldModel.AutonomousResearch.{
    ResearchProgram, ResearchCampaign, ExperimentPortfolio,
    ExperimentBudget, ExperimentSchedule, ResearchOutcome,
    ResearchEvidence, ProgramMetrics
  }

  alias TiannaraRuntime.WorldModel.AutonomousResearch.Engines.{
    KnowledgeGapPrioritizer, ExperimentPlanner, PortfolioOptimizer,
    ExperimentScheduler, TheoryUpdater, ResearchArchaeology,
    ResearchMathVerification, ResearchProgramEngine
  }

  alias TiannaraRuntime.WorldModel.AutonomousResearch.{
    ScoringConfig, KnowledgeGapPriorityRecord,
    ExperimentDesignConfig, ScheduleConfig,
    PortfolioConfig, TheoryEvolutionConfig
  }

  defp gap_map(id, current, target, impact, feasibility, civ_rel, info_gain) do
    %{
      knowledge_gap_id: id,
      current_confidence: current,
      target_confidence: target,
      estimated_impact: impact,
      feasibility: feasibility,
      civilization_relevance: civ_rel,
      information_gain: info_gain,
      phase_17_8_ext: %{twin_provenance_hash: "th_#{id}"}
    }
  end

  defp scoring_config do
    {:ok, cfg} =
      ScoringConfig.new(
        epoch_id: "epoch_1",
        schema_version: "17.8.0",
        w_uncertainty: 0.2,
        w_impact: 0.2,
        w_feasibility: 0.2,
        w_civilization_relevance: 0.2,
        w_information_gain: 0.2,
        tie_break_field: "knowledge_gap_id",
        tie_break_direction: :asc
      )

    cfg
  end

  defp portfolio do
    {:ok, pf} =
      ExperimentPortfolio.new(
        epoch_id: "epoch_1",
        config_hash: "ch_v1",
        selected_program_ids: ["prog_pipe"],
        selected_experiment_ids: ["exp_pipe_1"],
        diversity_score: 0.8,
        expected_total_information_gain: 0.9,
        optimization_proof_hash: "opf_v1",
        budget_allocation_id: "bd_placeholder",
        selection_rationale_hash: "rat_v1"
      )

    pf
  end

  defp budget(pf) do
    {:ok, bd} =
      ExperimentBudget.new(
        portfolio_id: pf.portfolio_id,
        total_compute_units: 1000,
        total_evidence_units: 500,
        per_program_allocations: [
          %{
            program_id: "prog_pipe",
            compute_units: 500,
            evidence_units: 250,
            max_experiments: 50,
            priority_rank: 1
          }
        ],
        allocation_algorithm_version: "1.0.0",
        allocation_proof_hash: "apf_v1",
        config_hash: "ch_v1"
      )

    bd
  end

  defp schedule_config do
    {:ok, cfg} =
      ScheduleConfig.new(
        epoch_id: "epoch_1",
        schema_version: "17.8.0",
        max_parallel_campaigns: 3,
        max_inflight_compute_units: 1000,
        adaptive_scheduling_enabled: false,
        scheduling_algorithm_version: "1.0.0"
      )

    cfg
  end

  defp theory_config do
    {:ok, cfg} =
      TheoryEvolutionConfig.new(
        epoch_id: "epoch_1",
        schema_version: "17.8.0",
        support_threshold: 0.5,
        strength_threshold: 0.3,
        reject_support_threshold: 0.2,
        boost_factor: 0.1,
        penalty_factor: 0.2,
        rejection_confidence_threshold: 0.1,
        rejection_contradiction_score_threshold: 0.8,
        rejection_contradiction_confidence_threshold: 0.2,
        contradiction_difference_limit: 0.5,
        support_match_difference_limit: 0.5,
        min_sample_size: 10,
        sample_size_normalization_base: 10.0,
        w_confidence: 0.34,
        w_size: 0.33,
        w_effect: 0.33
      )

    cfg
  end

  defp pipeline_program do
    pf = portfolio()
    bd = budget(pf)
    scfg = schedule_config()
    thcfg = theory_config()

    %{
      priority_records: [
        gap_map("kg_1", 0.3, 1.0, 0.8, 0.7, 0.6, 0.5),
        gap_map("kg_2", 0.5, 1.0, 0.5, 0.5, 0.5, 0.5)
      ],
      scoring_config: scoring_config(),
      epoch_id: "epoch_1",
      experiments: [
        %{
          independent_variables: ["x"],
          dependent_variables: ["y"],
          control_variables: ["c"],
          treatments: [%{name: "low", value: 0.1}, %{name: "high", value: 0.9}],
          sample_size: 100,
          statistical_power: 0.8,
          effect_size: 0.5
        }
      ],
      portfolio: pf,
      budget: bd,
      schedule_config: scfg,
      evidence_ledger: [%{evidence_id: "ev_1", variable: "x", value: 0.5, confidence: 0.9}],
      theory_update_inputs: [
        %{
          theory: %{
            theory_id: "t_1",
            predictions: %{"x" => 1.0},
            confidence: 0.5,
            supporting_evidence_count: 0
          },
          evidence: %{
            evidence_id: "ev_1",
            data: %{"x" => 1.0},
            confidence: 0.9,
            sample_size: 100,
            effect_size: 0.5
          },
          config: thcfg
        }
      ],
      replay_timestamp: "2024-01-01T00:00:00Z"
    }
  end

  describe "C17.8.95.1 — Knowledge Gap Prioritization" do
    test "prioritize sorts gaps by priority score" do
      cfg = scoring_config()
      g1 = gap_map("g_a", 0.3, 1.0, 0.9, 0.8, 0.7, 0.8)
      g2 = gap_map("g_b", 0.5, 1.0, 0.5, 0.5, 0.4, 0.5)
      g3 = gap_map("g_c", 0.8, 1.0, 0.3, 0.2, 0.1, 0.2)
      assert {:ok, records} = KnowledgeGapPrioritizer.prioritize([g1, g2, g3], cfg, "epoch_1")
      assert length(records) == 3
      scores = Enum.map(records, & &1.composite_score)
      assert scores == Enum.sort(scores, :desc)
      assert hd(records).composite_score >= List.last(records).composite_score
    end

    test "compute_uncertainty returns clamped value" do
      cfg = scoring_config()
      gap = gap_map("g1", 0.3, 1.0, 0.5, 0.5, 0.5, 0.5)
      assert {:ok, [record]} = KnowledgeGapPrioritizer.prioritize([gap], cfg, "epoch_1")
      assert record.score_components.uncertainty == 0.7
      invalid = %{knowledge_gap_id: "g2", phase_17_8_ext: %{twin_provenance_hash: "h2"}}
      assert {:error, _} = KnowledgeGapPrioritizer.prioritize([invalid], cfg, "epoch_1")
    end

    test "compute_information_gain computes from entropy and scope" do
      cfg = scoring_config()
      gap = gap_map("g1", 0.3, 1.0, 0.5, 0.5, 0.5, 0.75)
      assert {:ok, [record]} = KnowledgeGapPrioritizer.prioritize([gap], cfg, "epoch_1")
      assert record.score_components.information_gain == 0.75
    end

    test "compute_civilization_relevance scores against constitution" do
      cfg = scoring_config()
      gap = gap_map("g1", 0.3, 1.0, 0.5, 0.5, 0.9, 0.5)
      assert {:ok, [record]} = KnowledgeGapPrioritizer.prioritize([gap], cfg, "epoch_1")
      assert record.score_components.civilization_relevance == 0.9
    end
  end

  describe "C17.8.95.2 — Experiment Planning" do
    test "plan creates complete experiment from hypothesis" do
      {:ok, rec} =
        KnowledgeGapPriorityRecord.new(
          knowledge_gap_id: "gap_1",
          epoch_id: "epoch_1",
          scoring_config_id: "scfg_ref",
          composite_score: 0.85,
          score_components: %{
            uncertainty: 0.7,
            impact: 0.8,
            feasibility: 0.7,
            civilization_relevance: 0.6,
            information_gain: 0.5
          },
          rank: 0,
          twin_provenance_hash: "th_1"
        )

      {:ok, dc} =
        ExperimentDesignConfig.new(
          epoch_id: "epoch_1",
          schema_version: "17.8.0",
          required_validation_types_by_gap_type: %{uncertainty: [:statistical, :robustness]},
          min_evidence_observables: 1,
          required_stopping_condition_types: ["confidence_reached"],
          seed_derivation_strategy: "blake3_from_id"
        )

      program = %{
        program_id: "rp_test",
        schema_version: "17.8.0",
        statistical_requirements: %{
          alpha: 0.05,
          target_power: 0.8,
          confidence_interval_target: 0.95
        },
        stopping_criteria: [%{criterion_type: :max_ticks_reached, threshold_ref: "thr_100"}],
        evidence_requirements: [%{evidence_type: "signal_strength", required_quality: "high"}],
        resource_constraints: %{max_experiments: 50, max_compute_units: 1000}
      }

      assert {:ok, design} =
               ExperimentPlanner.design(program, rec, dc, :uncertainty)

      assert is_list(design.measurement_definitions)
      assert length(design.measurement_definitions) > 0
      assert is_list(design.required_validation_types)
      assert length(design.required_validation_types) > 0
      assert is_list(design.stopping_criteria)
      assert length(design.stopping_criteria) > 0
      assert is_binary(design.scenario_name)
      assert String.starts_with?(design.scenario_name, "arpe_")
      assert is_list(design.evidence_observable_mappings)
      assert length(design.evidence_observable_mappings) > 0
      assert is_list(design.stopping_condition_mappings)
      assert is_binary(design.deterministic_seed)
      assert is_integer(design.total_ticks) and design.total_ticks > 0
    end

    test "design_variables extracts from hypothesis" do
      {:ok, rec} =
        KnowledgeGapPriorityRecord.new(
          knowledge_gap_id: "gap_2",
          epoch_id: "epoch_1",
          scoring_config_id: "scfg_ref",
          composite_score: 0.75,
          score_components: %{
            uncertainty: 0.5,
            impact: 0.6,
            feasibility: 0.7,
            civilization_relevance: 0.5,
            information_gain: 0.4
          },
          rank: 1,
          twin_provenance_hash: "th_2"
        )

      {:ok, dc} =
        ExperimentDesignConfig.new(
          epoch_id: "epoch_1",
          schema_version: "17.8.0",
          required_validation_types_by_gap_type: %{contradiction: [:statistical, :replay]},
          min_evidence_observables: 1,
          required_stopping_condition_types: ["budget_exhausted"],
          seed_derivation_strategy: "blake3_from_id"
        )

      prog_a = %{
        program_id: "rp_a",
        schema_version: "17.8.0",
        statistical_requirements: %{
          alpha: 0.05,
          target_power: 0.8,
          confidence_interval_target: 0.95
        },
        stopping_criteria: [%{criterion_type: :max_ticks_reached, threshold_ref: "thr_50"}],
        evidence_requirements: [%{evidence_type: "temp", required_quality: "medium"}],
        resource_constraints: %{max_experiments: 30, max_compute_units: 500}
      }

      assert {:ok, design_a} = ExperimentPlanner.design(prog_a, rec, dc, :contradiction)
      assert length(design_a.variable_mappings) == 1
      assert hd(design_a.variable_mappings).experiment_variable == "var_temp"
    end

    test "design_treatments generates treatment levels" do
      {:ok, rec} =
        KnowledgeGapPriorityRecord.new(
          knowledge_gap_id: "gap_3",
          epoch_id: "epoch_1",
          scoring_config_id: "scfg_ref",
          composite_score: 0.65,
          score_components: %{
            uncertainty: 0.4,
            impact: 0.5,
            feasibility: 0.6,
            civilization_relevance: 0.4,
            information_gain: 0.3
          },
          rank: 2,
          twin_provenance_hash: "th_3"
        )

      {:ok, dc} =
        ExperimentDesignConfig.new(
          epoch_id: "epoch_1",
          schema_version: "17.8.0",
          required_validation_types_by_gap_type: %{uncertainty: [:robustness]},
          min_evidence_observables: 2,
          required_stopping_condition_types: ["effect_size_met"],
          seed_derivation_strategy: "blake3_from_id"
        )

      program = %{
        program_id: "rp_b",
        schema_version: "17.8.0",
        statistical_requirements: %{
          alpha: 0.01,
          target_power: 0.95,
          confidence_interval_target: 0.99
        },
        stopping_criteria: [%{criterion_type: :budget_exhausted, threshold_ref: "thr_200"}],
        evidence_requirements: [
          %{evidence_type: "pressure", required_quality: "high"},
          %{evidence_type: "volume", required_quality: "exact"}
        ],
        resource_constraints: %{max_experiments: 100, max_compute_units: 2000}
      }

      assert {:ok, design} = ExperimentPlanner.design(program, rec, dc, :uncertainty)
      assert length(design.measurement_definitions) == 2
      assert length(design.evidence_observable_mappings) == 2
      assert length(design.variable_mappings) == 2
    end

    test "calculate_statistical_power returns valid power" do
      {:ok, rec} =
        KnowledgeGapPriorityRecord.new(
          knowledge_gap_id: "gap_4",
          epoch_id: "epoch_1",
          scoring_config_id: "scfg_ref",
          composite_score: 0.55,
          score_components: %{
            uncertainty: 0.3,
            impact: 0.4,
            feasibility: 0.5,
            civilization_relevance: 0.3,
            information_gain: 0.2
          },
          rank: 3,
          twin_provenance_hash: "th_4"
        )

      {:ok, dc} =
        ExperimentDesignConfig.new(
          epoch_id: "epoch_1",
          schema_version: "17.8.0",
          required_validation_types_by_gap_type: %{missing_evidence: [:statistical]},
          min_evidence_observables: 1,
          required_stopping_condition_types: ["max_ticks_reached"],
          seed_derivation_strategy: "blake3_from_id"
        )

      program = %{
        program_id: "rp_c",
        schema_version: "17.8.0",
        statistical_requirements: %{
          alpha: 0.05,
          target_power: 0.9,
          confidence_interval_target: 0.95
        },
        stopping_criteria: [%{criterion_type: :max_ticks_reached, threshold_ref: "thr_300"}],
        evidence_requirements: [%{evidence_type: "measurement_x", required_quality: "precise"}],
        resource_constraints: %{max_experiments: 75, max_compute_units: 1500}
      }

      assert {:ok, design} = ExperimentPlanner.design(program, rec, dc, :missing_evidence)
      assert design.total_ticks == 75
      assert design.sampling_plan.sample_strategy == "stratified"
      assert is_binary(design.sampling_plan.seeds.deterministic_seed_source)
    end
  end

  describe "C17.8.95.3 — Portfolio Optimization" do
    test "optimize allocates budget across portfolios" do
      {:ok, pf_a} =
        ExperimentPortfolio.new(
          epoch_id: "epoch_1",
          config_hash: "ch_a",
          selected_program_ids: ["prog_a"],
          selected_experiment_ids: ["exp_a1", "exp_a2"],
          diversity_score: 0.7,
          expected_total_information_gain: 0.9,
          optimization_proof_hash: "opf_a",
          budget_allocation_id: "bd_a",
          selection_rationale_hash: "rat_a"
        )

      {:ok, pf_b} =
        ExperimentPortfolio.new(
          epoch_id: "epoch_1",
          config_hash: "ch_b",
          selected_program_ids: ["prog_b"],
          selected_experiment_ids: ["exp_b1"],
          diversity_score: 0.5,
          expected_total_information_gain: 0.6,
          optimization_proof_hash: "opf_b",
          budget_allocation_id: "bd_b",
          selection_rationale_hash: "rat_b"
        )

      {:ok, pf_c} =
        ExperimentPortfolio.new(
          epoch_id: "epoch_1",
          config_hash: "ch_c",
          selected_program_ids: ["prog_c"],
          selected_experiment_ids: ["exp_c1", "exp_c2", "exp_c3"],
          diversity_score: 0.3,
          expected_total_information_gain: 0.3,
          optimization_proof_hash: "opf_c",
          budget_allocation_id: "bd_c",
          selection_rationale_hash: "rat_c"
        )

      {:ok, bd} =
        ExperimentBudget.new(
          portfolio_id: "pf_ref",
          total_compute_units: 3000,
          total_evidence_units: 1500,
          per_program_allocations: [
            %{
              program_id: "prog_a",
              compute_units: 1000,
              evidence_units: 500,
              max_experiments: 100,
              priority_rank: 1
            },
            %{
              program_id: "prog_b",
              compute_units: 1000,
              evidence_units: 500,
              max_experiments: 100,
              priority_rank: 2
            },
            %{
              program_id: "prog_c",
              compute_units: 1000,
              evidence_units: 500,
              max_experiments: 100,
              priority_rank: 3
            }
          ],
          allocation_algorithm_version: "1.0.0",
          allocation_proof_hash: "apf_abc",
          config_hash: "ch_abc"
        )

      {:ok, pcfg} =
        PortfolioConfig.new(
          epoch_id: "epoch_1",
          schema_version: "17.8.0",
          w_information_gain: 0.2,
          w_scientific_diversity: 0.2,
          w_constitutional_priority: 0.2,
          w_resource_utilization: 0.2,
          w_long_term_impact: 0.2,
          min_domain_diversity_threshold: 0.0,
          min_value_threshold: 0.0,
          max_portfolio_size: 3,
          optimization_algorithm_version: "1.0.0"
        )

      assert {:ok, result} = PortfolioOptimizer.optimize([pf_a, pf_b, pf_c], bd, pcfg)
      assert is_list(result.selected_program_ids)
      assert is_list(result.selected_experiment_ids)
      assert result.expected_total_information_gain > 0
      assert result.diversity_score >= 0
      assert is_binary(result.optimization_proof_hash)
    end

    test "compute_diversity measures topic variety" do
      {:ok, pf_same1} =
        ExperimentPortfolio.new(
          epoch_id: "epoch_1",
          config_hash: "ch_d1",
          selected_program_ids: ["prog_d"],
          selected_experiment_ids: ["exp_d1"],
          diversity_score: 0.2,
          expected_total_information_gain: 0.4,
          optimization_proof_hash: "opf_d1",
          budget_allocation_id: "bd_d1",
          selection_rationale_hash: "rat_d1"
        )

      {:ok, pf_same2} =
        ExperimentPortfolio.new(
          epoch_id: "epoch_1",
          config_hash: "ch_d2",
          selected_program_ids: ["prog_d"],
          selected_experiment_ids: ["exp_d2"],
          diversity_score: 0.2,
          expected_total_information_gain: 0.3,
          optimization_proof_hash: "opf_d2",
          budget_allocation_id: "bd_d2",
          selection_rationale_hash: "rat_d2"
        )

      {:ok, pf_diff} =
        ExperimentPortfolio.new(
          epoch_id: "epoch_1",
          config_hash: "ch_e",
          selected_program_ids: ["prog_e"],
          selected_experiment_ids: ["exp_e1"],
          diversity_score: 0.9,
          expected_total_information_gain: 0.8,
          optimization_proof_hash: "opf_e",
          budget_allocation_id: "bd_e",
          selection_rationale_hash: "rat_e"
        )

      {:ok, bd} =
        ExperimentBudget.new(
          portfolio_id: "pf_ref2",
          total_compute_units: 2000,
          total_evidence_units: 1000,
          per_program_allocations: [
            %{
              program_id: "prog_d",
              compute_units: 1000,
              evidence_units: 500,
              max_experiments: 50,
              priority_rank: 1
            },
            %{
              program_id: "prog_e",
              compute_units: 1000,
              evidence_units: 500,
              max_experiments: 50,
              priority_rank: 2
            }
          ],
          allocation_algorithm_version: "1.0.0",
          allocation_proof_hash: "apf_de",
          config_hash: "ch_de"
        )

      {:ok, pcfg} =
        PortfolioConfig.new(
          epoch_id: "epoch_1",
          schema_version: "17.8.0",
          w_information_gain: 0.2,
          w_scientific_diversity: 0.4,
          w_constitutional_priority: 0.1,
          w_resource_utilization: 0.2,
          w_long_term_impact: 0.1,
          min_domain_diversity_threshold: 0.0,
          min_value_threshold: 0.0,
          max_portfolio_size: 3,
          optimization_algorithm_version: "1.0.0"
        )

      assert {:ok, result} =
               PortfolioOptimizer.optimize([pf_same1, pf_same2, pf_diff], bd, pcfg)

      assert length(result.selected_program_ids) >= 2
      assert is_binary(result.budget_allocation_id)
    end

    test "prune_low_value removes low-gain portfolios" do
      {:ok, pf_high} =
        ExperimentPortfolio.new(
          epoch_id: "epoch_1",
          config_hash: "ch_f",
          selected_program_ids: ["prog_f"],
          selected_experiment_ids: ["exp_f1"],
          diversity_score: 0.9,
          expected_total_information_gain: 1.0,
          optimization_proof_hash: "opf_f",
          budget_allocation_id: "bd_f",
          selection_rationale_hash: "rat_f"
        )

      {:ok, pf_low} =
        ExperimentPortfolio.new(
          epoch_id: "epoch_1",
          config_hash: "ch_g",
          selected_program_ids: ["prog_g"],
          selected_experiment_ids: ["exp_g1"],
          diversity_score: 0.1,
          expected_total_information_gain: 0.05,
          optimization_proof_hash: "opf_g",
          budget_allocation_id: "bd_g",
          selection_rationale_hash: "rat_g"
        )

      {:ok, bd} =
        ExperimentBudget.new(
          portfolio_id: "pf_ref3",
          total_compute_units: 1000,
          total_evidence_units: 500,
          per_program_allocations: [
            %{
              program_id: "prog_f",
              compute_units: 500,
              evidence_units: 250,
              max_experiments: 50,
              priority_rank: 1
            },
            %{
              program_id: "prog_g",
              compute_units: 500,
              evidence_units: 250,
              max_experiments: 50,
              priority_rank: 2
            }
          ],
          allocation_algorithm_version: "1.0.0",
          allocation_proof_hash: "apf_fg",
          config_hash: "ch_fg"
        )

      {:ok, pcfg} =
        PortfolioConfig.new(
          epoch_id: "epoch_1",
          schema_version: "17.8.0",
          w_information_gain: 0.2,
          w_scientific_diversity: 0.2,
          w_constitutional_priority: 0.2,
          w_resource_utilization: 0.2,
          w_long_term_impact: 0.2,
          min_domain_diversity_threshold: 0.0,
          min_value_threshold: 0.5,
          max_portfolio_size: 2,
          optimization_algorithm_version: "1.0.0"
        )

      assert {:ok, result} = PortfolioOptimizer.optimize([pf_high, pf_low], bd, pcfg)
      assert result.expected_total_information_gain > 0
      assert is_binary(result.optimization_proof_hash)
    end
  end

  describe "C17.8.95.4 — Experiment Scheduling" do
    test "schedule creates schedule with execution groups" do
      pf = portfolio()
      bd = budget(pf)
      scfg = schedule_config()
      assert {:ok, schedule} = ExperimentScheduler.schedule(pf, bd, scfg)
      assert is_list(schedule.dispatch_intents)
      assert is_binary(schedule.schedule_id)
      assert String.starts_with?(schedule.schedule_id, "sc_")
      assert is_binary(schedule.schedule_fingerprint)
      assert String.starts_with?(schedule.schedule_fingerprint, "fp_")
    end

    test "schedule_sequential orders campaigns" do
      {:ok, pf_one} =
        ExperimentPortfolio.new(
          epoch_id: "epoch_1",
          config_hash: "ch_seq",
          selected_program_ids: ["prog_seq"],
          selected_experiment_ids: ["exp_seq_1"],
          diversity_score: 0.5,
          expected_total_information_gain: 0.5,
          optimization_proof_hash: "opf_seq",
          budget_allocation_id: "bd_seq",
          selection_rationale_hash: "rat_seq"
        )

      {:ok, bd_one} =
        ExperimentBudget.new(
          portfolio_id: pf_one.portfolio_id,
          total_compute_units: 500,
          total_evidence_units: 250,
          per_program_allocations: [
            %{
              program_id: "prog_seq",
              compute_units: 500,
              evidence_units: 250,
              max_experiments: 10,
              priority_rank: 1
            }
          ],
          allocation_algorithm_version: "1.0.0",
          allocation_proof_hash: "apf_seq",
          config_hash: "ch_seq"
        )

      {:ok, cfg} =
        ScheduleConfig.new(
          epoch_id: "epoch_1",
          schema_version: "17.8.0",
          max_parallel_campaigns: 1,
          max_inflight_compute_units: 100,
          adaptive_scheduling_enabled: true,
          scheduling_algorithm_version: "1.0.0"
        )

      assert {:ok, schedule} = ExperimentScheduler.schedule(pf_one, bd_one, cfg)
      assert length(schedule.dispatch_intents) == 1
      intent = hd(schedule.dispatch_intents)
      assert intent.dispatch_mode == :sequential
      assert is_binary(intent.intent_id)
      assert is_binary(intent.experiment_id)
    end

    test "schedule_parallel creates parallel groups" do
      {:ok, pf_multi} =
        ExperimentPortfolio.new(
          epoch_id: "epoch_1",
          config_hash: "ch_par",
          selected_program_ids: ["prog_par"],
          selected_experiment_ids: ["exp_p1", "exp_p2", "exp_p3"],
          diversity_score: 0.6,
          expected_total_information_gain: 0.7,
          optimization_proof_hash: "opf_par",
          budget_allocation_id: "bd_par",
          selection_rationale_hash: "rat_par"
        )

      {:ok, bd_multi} =
        ExperimentBudget.new(
          portfolio_id: pf_multi.portfolio_id,
          total_compute_units: 2000,
          total_evidence_units: 1000,
          per_program_allocations: [
            %{
              program_id: "prog_par",
              compute_units: 2000,
              evidence_units: 1000,
              max_experiments: 50,
              priority_rank: 1
            }
          ],
          allocation_algorithm_version: "1.0.0",
          allocation_proof_hash: "apf_par",
          config_hash: "ch_par"
        )

      {:ok, cfg} =
        ScheduleConfig.new(
          epoch_id: "epoch_1",
          schema_version: "17.8.0",
          max_parallel_campaigns: 2,
          max_inflight_compute_units: 500,
          adaptive_scheduling_enabled: true,
          scheduling_algorithm_version: "1.0.0"
        )

      assert {:ok, schedule} = ExperimentScheduler.schedule(pf_multi, bd_multi, cfg)
      assert length(schedule.dispatch_intents) == 3
    end

    test "resolve_dependencies builds dependency map" do
      pf = portfolio()
      bd = budget(pf)

      {:ok, cfg} =
        ScheduleConfig.new(
          epoch_id: "epoch_1",
          schema_version: "17.8.0",
          max_parallel_campaigns: 2,
          max_inflight_compute_units: 500,
          adaptive_scheduling_enabled: true,
          scheduling_algorithm_version: "1.0.0"
        )

      assert {:ok, schedule} = ExperimentScheduler.schedule(pf, bd, cfg)
      completed = ["exp_pipe_1"]
      assert {:ok, reschedule} = ExperimentScheduler.adaptive_reschedule(schedule, completed, cfg)
      assert is_list(reschedule.dispatch_intents)
      assert is_binary(reschedule.schedule_fingerprint)
      assert reschedule.schedule_id != schedule.schedule_id
      assert {:ok, {updated, interruptions}} =
               ExperimentScheduler.handle_interruption(schedule, "exp_pipe_1", :resource_exhausted, cfg)

      assert is_list(interruptions)
      assert is_binary(updated.schedule_fingerprint)
    end
  end

  describe "C17.8.95.5 — Theory Update" do
    test "update strengthens theory with confirming evidence" do
      cfg = theory_config()
      theory = %{theory_id: "t_str", predictions: %{"x" => 1.0}, confidence: 0.5, supporting_evidence_count: 0}
      evidence = %{evidence_id: "ev_str", data: %{"x" => 1.0}, confidence: 0.9, sample_size: 100, effect_size: 0.5}
      assert {:ok, _updated, record} = TheoryUpdater.update(theory, evidence, cfg, "2024-01-01T00:00:00Z")
      assert record.action == :strengthened
    end

    test "update detects contradiction" do
      cfg = theory_config()
      theory = %{theory_id: "t_con", predictions: %{"x" => 1.0}, confidence: 0.5}
      evidence = %{evidence_id: "ev_con", data: %{variable: "x", value: 10.0}, confidence: 0.9, sample_size: 100, effect_size: 0.5}
      assert {:ok, _updated, record} = TheoryUpdater.update(theory, evidence, cfg, "2024-01-01T00:00:00Z")
      assert record.contradiction_detected == true
    end

    test "merge combines two theories" do
      cfg = theory_config()
      ta = %{theory_id: "t_a", text: "Theory alpha", confidence: 0.6, supporting_evidence_count: 2, equations: ["x=1"]}
      tb = %{theory_id: "t_b", text: "Theory beta", confidence: 0.4, supporting_evidence_count: 3, equations: ["y=2"]}
      merged = TheoryUpdater.merge(ta, tb, cfg, "2024-01-01T00:00:00Z")
      assert String.contains?(merged.text, "[merged with]")
      assert merged.confidence == 0.5
      assert merged.supporting_evidence_count == 5
    end

    test "split divides theory into sub-theories" do
      cfg = theory_config()
      theory = %{theory_id: "t_sp", equations: ["y=2*x", "z=3*y"], confidence: 0.6}
      result = TheoryUpdater.split(theory, cfg, "2024-01-01T00:00:00Z")
      assert length(result) == 2
      assert hd(result).type == :sub_theory
    end
  end

  describe "C17.8.95.6 — Research Archaeology" do
    test "record creates archaeology entry" do
      artifact = %{program_id: "rp_arch_1", objective: "test objective"}
      assert {:ok, entry} = ResearchArchaeology.record(artifact)
      assert is_binary(entry.artifact_id)
      assert is_map(entry.lineage)
      assert entry.artifact_type == :program
    end

    test "determine_type detects program type" do
      artifact = %{program_id: "rp_detect", hypothesis_id: "h_detect"}
      assert {:ok, entry} = ResearchArchaeology.record(artifact)
      assert entry.artifact_type == :program
    end

    test "get_lineage returns lineage info" do
      assert {:ok, result} = ResearchArchaeology.get_lineage("artifact_abc")
      assert result.artifact_id == "artifact_abc"
      assert is_list(result.lineage_chain)
    end
  end

  describe "C17.8.95.7 — Math Verification" do
    test "verify_experiment returns proof hash" do
      experiment = %{
        independent_variables: ["x"],
        dependent_variables: ["y"],
        control_variables: ["c"],
        treatments: [%{name: "low", value: 0.1}],
        sample_size: 100,
        statistical_power: 0.8,
        effect_size: 0.5
      }

      assert {:ok, proof_hash, details} = ResearchMathVerification.verify_experiment(experiment)
      assert is_binary(proof_hash)
      assert byte_size(proof_hash) > 0
      assert details.verified == true
    end

    test "verify_statistical_assumptions checks normality" do
      large = %{sample_size: 100, effect_size: 0.5, statistical_power: 0.8}
      result = ResearchMathVerification.verify_statistical_assumptions(large)
      assert result.status == :pass or result.status == :warning
      assert length(result.checks) >= 3
    end

    test "fingerprint is deterministic" do
      data = %{a: 1, b: "hello", c: [1, 2, 3]}
      fp1 = ResearchMathVerification.fingerprint(data)
      fp2 = ResearchMathVerification.fingerprint(data)
      assert fp1 == fp2
      assert String.starts_with?(fp1, "fp_")
      other = %{a: 2, b: "hello", c: [1, 2, 3]}
      fp3 = ResearchMathVerification.fingerprint(other)
      assert fp1 != fp3
    end
  end

  describe "C17.8.95.8 — Struct Validation" do
    test "ResearchProgram has required fields" do
      assert {:ok, program} =
               ResearchProgram.new(
                 schema_version: "17.8.0",
                 primary_question_id: "pq_1",
                 portfolio_rank_hint: 1,
                 objectives: [%{objective_id: "obj_1", description: "Test objective"}],
                 milestones: [%{milestone_id: "ms_1", description: "Test milestone"}],
                 experiments: ["exp_1"],
                 evidence_requirements: [%{evidence_type: "type_a", required_quality: "high"}],
                 statistical_requirements: %{
                   alpha: 0.05,
                   target_power: 0.8,
                   confidence_interval_target: 0.95
                 },
                 stopping_criteria: [%{criterion_type: :max_ticks_reached, threshold_ref: "thr_100"}],
                 resource_constraints: %{max_compute_units: 1000, max_experiments: 50},
                 status: :active,
                 config_hash: "ch_v1"
               )

      assert String.starts_with?(program.program_id, "rp_")
      assert program.status == :active
      assert program.schema_version == "17.8.0"
    end

    test "ResearchCampaign generates rc_ prefix" do
      assert {:ok, campaign} =
               ResearchCampaign.new(
                 program_id: "rp_camp",
                 portfolio_id: "pf_camp",
                 schedule_id: "sc_camp",
                 experiment_ids: ["exp_c1"],
                 execution_order: ["exp_c1"],
                 status: :pending
               )

      assert String.starts_with?(campaign.campaign_id, "rc_")
    end

    test "ResearchEvidence generates re_ prefix" do
      assert {:ok, evidence} =
               ResearchEvidence.new(
                 schema_version: "17.8.0",
                 experiment_id: "exp_ev",
                 evidence_type: :normalized,
                 evidence_schema_id: "es_v1",
                 provenance: %{source_artifact_ids: ["exp_ev"], capture_context: "test"},
                 evidence_records: [
                   %{
                     record_id: "r_1",
                     record_type: "measurement",
                     content_hash: "ch_1",
                     content_pointer: "cp_1"
                   }
                 ],
                 normalization_proof: %{normalizer_id: "n_1", normalization_rules_hash: "nrh_1"},
                 phase_17_8_ext: %{
                   twin_outcome_id: "to_1",
                   simulation_fingerprint: "sf_1",
                   normalization_proof_hash: "nph_1"
                 }
               )

      assert String.starts_with?(evidence.evidence_bundle_id, "re_")
    end
  end

  describe "C17.8.95.9 — Full Pipeline Execution" do
    test "create_program creates active program" do
      assert {:ok, program} =
               ResearchProgramEngine.create_program(
                 "test objective",
                 [],
                 schema_version: "17.8.0",
                 primary_question_id: "pq_pipe",
                 portfolio_rank_hint: 1,
                 objectives: [%{objective_id: "obj_pipe"}],
                 milestones: [%{milestone_id: "ms_pipe"}],
                 experiments: ["exp_pipe"],
                 evidence_requirements: [%{evidence_type: "t", required_quality: "h"}],
                 statistical_requirements: %{
                   alpha: 0.05,
                   target_power: 0.8,
                   confidence_interval_target: 0.95
                 },
                 stopping_criteria: [%{criterion_type: :max_ticks_reached, threshold_ref: "thr_100"}],
                 resource_constraints: %{max_compute_units: 1000, max_experiments: 50},
                 status: :active,
                 config_hash: "ch_pipe"
               )

      assert program.status == :active
      assert String.starts_with?(program.program_id, "rp_")
    end

    test "execute_pipeline runs full lifecycle" do
      prog = pipeline_program()
      assert {:ok, updated} = ResearchProgramEngine.execute_pipeline(prog)
      assert is_binary(updated.replay_fingerprint)
      assert String.starts_with?(updated.replay_fingerprint, "rf_")
      assert is_list(updated.evidence_ledger)
      assert length(updated.evidence_ledger) > 0
      assert is_list(updated.theories)
      assert length(updated.theories) > 0
      assert is_list(updated.archaeology_entries)
      assert length(updated.archaeology_entries) > 0
    end

    test "pause_and_terminate lifecycle" do
      assert {:ok, program} =
               ResearchProgramEngine.create_program(
                 "lifecycle test",
                 [],
                 schema_version: "17.8.0",
                 primary_question_id: "pq_life",
                 portfolio_rank_hint: 1,
                 objectives: [%{objective_id: "obj_life"}],
                 milestones: [%{milestone_id: "ms_life"}],
                 experiments: ["exp_life"],
                 evidence_requirements: [%{evidence_type: "t", required_quality: "h"}],
                 statistical_requirements: %{
                   alpha: 0.05,
                   target_power: 0.8,
                   confidence_interval_target: 0.95
                 },
                 stopping_criteria: [%{criterion_type: :max_ticks_reached, threshold_ref: "thr_100"}],
                 resource_constraints: %{max_compute_units: 1000, max_experiments: 50},
                 status: :active,
                 config_hash: "ch_life"
               )

      assert {:ok, paused} = ResearchProgramEngine.pause_program(program, "2024-06-15T12:00:00Z")
      assert paused.status == :paused
      assert {:ok, terminated} =
               ResearchProgramEngine.terminate_program(paused, "2024-06-15T12:30:00Z", :success)

      assert terminated.status == :terminated
      assert terminated.termination_record.reason == :success
    end
  end

  describe "C17.8.95.10 — Replay Determinism" do
    test "compute_fingerprint is deterministic" do
      prog = pipeline_program()
      fp1 = ResearchProgramEngine.compute_fingerprint(prog)
      fp2 = ResearchProgramEngine.compute_fingerprint(prog)
      assert fp1 == fp2
      assert String.starts_with?(fp1, "rf_")
    end

    test "fingerprint differs for different programs" do
      prog_a = pipeline_program()

      prog_b =
        prog_a
        |> Map.put(:epoch_id, "epoch_2")
        |> Map.put(:replay_timestamp, "2025-01-01T00:00:00Z")

      fp_a = ResearchProgramEngine.compute_fingerprint(prog_a)
      fp_b = ResearchProgramEngine.compute_fingerprint(prog_b)
      assert fp_a != fp_b
    end
  end
end
