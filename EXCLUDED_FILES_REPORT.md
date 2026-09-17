=== SR-4 COMMIT PREP: 676 files in the working tree were NOT staged ===

Reasons (in order of prevalence):
  1. Already tracked in git, no changes: many of the *.py and lib/ files are already in HEAD; this commit only adds changed files
  2. Ignored by project .gitignore: *.txt (134), *.log (21), tests/ (0), archive/ (4)
  3. Other (sample below): 521

=== 134 .txt files excluded (project .gitignore has `*.txt`) ===
  project_files.txt
  requirements.txt
  phase5c_all_tests.txt
  layer6_5a1_fixed_output.txt
  markdown/chat-Event Horizon Tensor Cores.txt
  phase5c5_FINAL.txt
  long_horizon_output.txt
  phase14/certification/run_hash_42.txt
  phase5_final_campaign.txt
  archive/experiments/2026-Q2/test_results/baseline_full_output.txt
  scan_out.txt
  phase5b_results.txt
  simulation_v2.txt
  test-output.txt
  temp_gck.txt
  phase5_test_output.txt
  phase5c4_DOMAIN_FIXED.txt
  layer6_5c_domain_results.txt
  markdown/cTiannara sentinel.txt
  phase5c_campaign_fixed.txt
  phase5c_campaign_output.txt
  phase5c4_FINAL_COMPLETE.txt
  DELIVERY_SUMMARY.txt
  campaign_result.txt
  phase5c4_ecology_expansion.txt
  phase5c6_validation_results.txt
  phase48_final.txt
  artifact_gen_log.txt
  phase5c4_with_domain_extraction.txt
  gen_out.txt
  ... and 104 more

=== 21 .log files excluded (project .gitignore has `*.log`) ===
  evidence_package/raw/soak72.log
  phase14/certification/replay/cold_boot_test_output_fixed.log
  simulation_run.log
  LAYER_6.5D_100K_VALIDATION.log
  server_stdout.log
  scalability_test_output.log
  phase14/certification/replay/independent_auditor_output.log
  phase14/certification/replay/evidence_closure_output.log
  build_output.log
  phase14/certification/replay/cold_boot_test_output.log
  data/tiannara_launch.log
  compile.log
  simulation_run_v2.log
  nats-server.log
  server_stderr.log
  evidence_package/audits_capability/t24_raw.log
  nats-server-err.log
  certification_run.log
  soak72_renewed.log
  certification_output.log
  ... and 1 more

=== 0 files in test/ paths excluded (per user request to filter test files) ===

=== 4 archive/ files excluded ===
  archive/experiments/2026-Q2/test_results/baseline_full_output.txt
  archive/experiments/2026-Q2/test_results/baseline_fixed_output.txt
  archive/experiments/2026-Q2/test_results/baseline_final_output.txt
  archive/experiments/2026-Q2/test_results/baseline_output.txt

=== 521 other missing files (sample of 40) ===
  lib/tiannara/asc/observatory/project_observatory.ex
  validation/memory/test_retrieval_drift.py
  test_websocket_streaming.py
  lib/tiannara/asc/crucible/survival_curves.ex
  lib/tiannara/web/live/unknowns_live.ex
  lib/tiannara/ocm/consensus_mesh.ex
  lib/tiannara/ucc/macro_state_registry.ex
  priv/tiannara/probes/test_registry2.exs
  lib/tiannara/omcs/continuity_scorer.ex
  lib/tiannara/stabilization/ocm/voting_system.ex
  lib/tiannara/asc/research/telemetry_snapshot.ex
  run_cold_boot_test.exs
  lib/tiannara/sentinel/d2/failed_meta_archive.ex
  run_archaeological_reconstruction.exs
  lib/tiannara/asc/laws/law.ex
  lib/tiannara/rea/evolutionary_organism.ex
  lib/tiannara/rea/causal/pressure_field.ex
  lib/tiannara/base_reality/workspace.ex
  lib/tiannara/topology/dfg/supervisor.ex
  lib/tiannara/domains/extruder/energy.ex
  lib/tiannara/topology/dfg/folder.ex
  lib/tiannara/sopl/law_immune_system.ex
  lib/tiannara/meta/hardware/event_horizon_tensor_core.ex
  lib/tiannara/asc/crucible/transfer_observation.ex
  lib/tiannara/asc/interface/lineage.ex
  lib/tiannara/sentinel/epistemic_shadow_graph.ex
  lib/tiannara/rea/causal/signal.ex
  cUsersuserTiannaraTiannara-MindCache-Prosthetictiannara_corereasoning__init__.py
  lib/tiannara/web/live/orbit_ecology_live.ex
  test_saas_platform.py
  lib/tiannara/rea/simulation_runner.ex
  lib/tiannara/ros/shard_supervisor.ex
  test_adversarial_debate.py
  lib/tiannara/rea/topo/causal_genome.ex
  lib/tiannara/rel/economy_manager.ex
  lib/tiannara/asc/project_world.ex
  validation/causal/test_counterfactual_robustness.py
  run_1m_test.exs
  runs/autonomous_experience.jsonl
  lib/tiannara/ros/civilization_ruin.ex
  ... and 481 more

=== Project .gitignore rules that caused exclusions ===
  __pycache__/
  *.pyc
  *.pyo
  *.pyd
  .env
  .env.production
  .env.local
  token*.txt
  *.db
  erl_crash.dump
  pytest-cache-files-*/
  c?Users*/
  tiannara_corecognitive_domains/
  tiannara_coreevaluationtest_suites/
  tiannara_coresandbox/
  benchmarksreal_world_scenarios/
  testsintegrationcross_domain/
  monitoringgrafana/
  monitoringgrafanadashboards/
  monitoringgrafanaprovisioning/
  .venv/
  venv/
  node_modules
  tiannara_gui/
  tiannara_internal_dashboard/
  tiannara_mobile/
  tests/
  pytest_cache_files-*/
  *.txt
  *.log
  .gitdist/
  build/
  dist/
  SECURITY_AUDIT.md
  OPTIMIZATION_SUMMARY.md
  test_security_fixes.py
  node_modules
  node_modules
  node_modules