
```
Tiannara-MindCache-Prosthetic
├─ .devcontainer
│  ├─ devcontainer.json
│  └─ Dockerfile
├─ docs
│  └─ README.md
├─ mindcache
│  ├─ orchestrator.py
│  └─ py_core
│     ├─ Documents.code-workspace
│     └─ tests
│        ├─ test_context.py
│        └─ test_memory.py
├─ requirements.txt
├─ runs
│  ├─ 20260303_142246_6c50c464_day10c_pipeline
│  │  ├─ meta.json
│  │  └─ packets.jsonl
│  ├─ 20260303_145533_b35d1a17_day10c_pipeline
│  │  ├─ meta.json
│  │  └─ packets.jsonl
│  ├─ 20260303_151242_de33df9d_day10c_pipeline
│  │  ├─ meta.json
│  │  └─ packets.jsonl
│  ├─ 20260303_152056_4953c5d5_day10c_pipeline
│  │  ├─ meta.json
│  │  └─ packets.jsonl
│  ├─ 20260303_152317_31b6275c_day10c_pipeline
│  │  ├─ meta.json
│  │  └─ packets.jsonl
│  ├─ 20260303_152618_e476e48a_day10c_pipeline
│  │  ├─ meta.json
│  │  └─ packets.jsonl
│  ├─ 20260303_184654_ca33b600_day10c_pipeline
│  │  └─ packets.jsonl
│  ├─ 20260303_220732_14f6d8aa_day10c_pipeline
│  │  └─ packets.jsonl
│  ├─ 20260304_005515_7a3244ead97d_23abb05c_day10c_pipeline
│  │  └─ packets.jsonl
│  ├─ 20260304_005930_468fe0fd34d6_b22d4b94_day10c_pipeline
│  │  └─ packets.jsonl
│  ├─ 20260304_174755_7bace122-9ad_day10c_pipeline
│  │  └─ packets.jsonl
│  ├─ 20260304_175126_3bea375b-77e_day10c_pipeline
│  │  └─ packets.jsonl
│  ├─ 20260304_175622_9e0c0ac2-417_day29_scenario
│  │  └─ packets.jsonl
│  ├─ day10c_pipeline.jsonl
│  └─ discovery_memory.jsonl
├─ rust_core
│  └─ ffi_bindings
│     ├─ Cargo.toml
│     └─ src
│        └─ lib.rs
├─ tiannara_api
│  ├─ main.py
│  ├─ routes
│  │  ├─ discovery.py
│  │  ├─ modules.py
│  │  └─ status.py
│  ├─ schemas.py
│  └─ __init__.py
├─ tiannara_core
│  ├─ action
│  │  ├─ action_layer.py
│  │  ├─ control_adapter.py
│  │  └─ __init__.py
│  ├─ cognition
│  │  ├─ context_processor.py
│  │  ├─ decision_engine.py
│  │  ├─ skill_memory.py
│  │  └─ __init__.py
│  ├─ discovery
│  │  ├─ experiment.py
│  │  ├─ extract.py
│  │  ├─ hypothesize.py
│  │  ├─ ingest.py
│  │  ├─ report.py
│  │  └─ __init__.py
│  ├─ memory
│  │  ├─ consolidator.py
│  │  ├─ discovery_memory.py
│  │  ├─ knowledge_store.py
│  │  ├─ memory_engine.py
│  │  └─ __init__.py
│  ├─ mission
│  │  ├─ alignment.py
│  │  ├─ constitution.py
│  │  └─ __init__.py
│  ├─ modules
│  │  ├─ base.py
│  │  ├─ registry.py
│  │  └─ __init__.py
│  ├─ safety
│  │  ├─ gate.py
│  │  ├─ policy.py
│  │  └─ __init__.py
│  ├─ sim
│  │  ├─ simulator.py
│  │  └─ __init__.py
│  └─ __init__.py
├─ tiannara_gui
│  ├─ eslint.config.js
│  ├─ index.html
│  ├─ package-lock.json
│  ├─ package.json
│  ├─ public
│  │  └─ vite.svg
│  ├─ README.md
│  ├─ src
│  │  ├─ api
│  │  │  ├─ client.js
│  │  │  ├─ discovery.js
│  │  │  ├─ modules.js
│  │  │  ├─ pros.js
│  │  │  └─ runs.js
│  │  ├─ App.css
│  │  ├─ App.jsx
│  │  ├─ assets
│  │  │  └─ react.svg
│  │  ├─ components
│  │  │  ├─ cards
│  │  │  │  ├─ MetricCard.jsx
│  │  │  │  ├─ ModuleCard.jsx
│  │  │  │  └─ StatusCard.jsx
│  │  │  ├─ charts
│  │  │  │  ├─ RetryChart.jsx
│  │  │  │  └─ RiskChart.jsx
│  │  │  ├─ discovery
│  │  │  │  ├─ ClaimsPanel.jsx
│  │  │  │  ├─ DiscoveryForm.jsx
│  │  │  │  ├─ ExperimentsPanel.jsx
│  │  │  │  ├─ HypthesesPanel.jsx
│  │  │  │  └─ SafetyPanel.jsx
│  │  │  └─ layout
│  │  │     ├─ PageShell.jsx
│  │  │     ├─ Sidebar.jsx
│  │  │     └─ Topbar.jsx
│  │  ├─ hooks
│  │  │  ├─ useApi.js
│  │  │  └─ usePlling.js
│  │  ├─ index.css
│  │  ├─ main.jsx
│  │  ├─ pages
│  │  │  ├─ Dashboard.jsx
│  │  │  ├─ DiscoveryLab.jsx
│  │  │  ├─ MemoryPage.jsx
│  │  │  ├─ ModulesPage.jsx
│  │  │  ├─ ProsControl.jsx
│  │  │  ├─ RunsPage.jsx
│  │  │  └─ SettingsPage.jsx
│  │  └─ router.jsx
│  └─ vite.config.js
└─ tiannara_pros
   ├─ actuators
   │  ├─ actuator_memory.py
   │  ├─ command_safety.py
   │  ├─ interfaces.py
   │  ├─ motor_controller.py
   │  ├─ retry_controller.py
   │  ├─ safety_monitor.py
   │  └─ __init__.py
   ├─ analytics
   │  ├─ failure_reasons.py
   │  └─ run_metrics.py
   ├─ config
   │  └─ limits.json
   ├─ docs
   │  ├─ ARCHITECTURE.md
   │  └─ FREEZE_v1.md
   ├─ io
   │  ├─ action_schema.py
   │  ├─ console_output.py
   │  ├─ emg_input.py
   │  ├─ fake_input.py
   │  ├─ input_interface.py
   │  ├─ jsonl_logger.py
   │  ├─ output_interface.py
   │  └─ run_recorder.py
   ├─ orchestrators
   │  ├─ orchestrator_day10B_skill_learning.py
   │  ├─ orchestrator_day10C_pipeline.py
   │  ├─ orchestrator_day10_realtime.py
   │  ├─ orchestrator_day20_replay.py
   │  ├─ orchestrator_day21_replay_cli.py
   │  ├─ orchestrator_day22_report.py
   │  ├─ orchestrator_day27_replay_cli.py
   │  ├─ orchestrator_day28_fail_report.py
   │  ├─ orchestrator_day29_run_scenario.py
   │  ├─ orchestrator_day4.py
   │  ├─ orchestrator_day5.py
   │  ├─ orchestrator_day6.py
   │  ├─ orchestrator_day7.py
   │  ├─ orchestrator_day8.py
   │  ├─ orchestrator_day9_feedback.py
   │  ├─ orchestrator_day9_realism.py
   │  └─ __init__.py
   ├─ scenarios
   │  ├─ crush_stress.json
   │  ├─ random_mix.json
   │  └─ slip_stress.json
   ├─ testing
   │  └─ fault_injection.py
   ├─ utils
   │  └─ config_fingerprint.py
   ├─ version.py
   └─ __init__.py

```
```
Tiannara-MindCache-Prosthetic
├─ .devcontainer
│  ├─ devcontainer.json
│  └─ Dockerfile
├─ docs
│  └─ README.md
├─ mindcache
│  ├─ orchestrator.py
│  └─ py_core
│     ├─ Documents.code-workspace
│     └─ tests
│        ├─ test_context.py
│        └─ test_memory.py
├─ README.md
├─ requirements.txt
├─ runs
│  ├─ 20260303_142246_6c50c464_day10c_pipeline
│  │  ├─ meta.json
│  │  └─ packets.jsonl
│  ├─ 20260303_145533_b35d1a17_day10c_pipeline
│  │  ├─ meta.json
│  │  └─ packets.jsonl
│  ├─ 20260303_151242_de33df9d_day10c_pipeline
│  │  ├─ meta.json
│  │  └─ packets.jsonl
│  ├─ 20260303_152056_4953c5d5_day10c_pipeline
│  │  ├─ meta.json
│  │  └─ packets.jsonl
│  ├─ 20260303_152317_31b6275c_day10c_pipeline
│  │  ├─ meta.json
│  │  └─ packets.jsonl
│  ├─ 20260303_152618_e476e48a_day10c_pipeline
│  │  ├─ meta.json
│  │  └─ packets.jsonl
│  ├─ 20260303_184654_ca33b600_day10c_pipeline
│  │  └─ packets.jsonl
│  ├─ 20260303_220732_14f6d8aa_day10c_pipeline
│  │  └─ packets.jsonl
│  ├─ 20260304_005515_7a3244ead97d_23abb05c_day10c_pipeline
│  │  └─ packets.jsonl
│  ├─ 20260304_005930_468fe0fd34d6_b22d4b94_day10c_pipeline
│  │  └─ packets.jsonl
│  ├─ 20260304_174755_7bace122-9ad_day10c_pipeline
│  │  └─ packets.jsonl
│  ├─ 20260304_175126_3bea375b-77e_day10c_pipeline
│  │  └─ packets.jsonl
│  ├─ 20260304_175622_9e0c0ac2-417_day29_scenario
│  │  └─ packets.jsonl
│  ├─ day10c_pipeline.jsonl
│  └─ discovery_memory.jsonl
├─ rust_core
│  └─ ffi_bindings
│     ├─ Cargo.toml
│     └─ src
│        └─ lib.rs
├─ tiannara_api
│  ├─ main.py
│  ├─ routes
│  │  ├─ autonomous.py
│  │  ├─ discovery.py
│  │  ├─ evolution.py
│  │  ├─ modules.py
│  │  └─ status.py
│  ├─ schemas.py
│  └─ __init__.py
├─ tiannara_core
│  ├─ action
│  │  ├─ action_layer.py
│  │  ├─ control_adapter.py
│  │  └─ __init__.py
│  ├─ autonomous
│  │  ├─ loop.py
│  │  ├─ orchestrator.py
│  │  └─ __init__.py
│  ├─ cognition
│  │  ├─ context_processor.py
│  │  ├─ decision_engine.py
│  │  ├─ skill_memory.py
│  │  └─ __init__.py
│  ├─ discovery
│  │  ├─ analyzer.py
│  │  ├─ engine.py
│  │  ├─ experiment.py
│  │  ├─ extract.py
│  │  ├─ hypothesize.py
│  │  ├─ ingest.py
│  │  ├─ report.py
│  │  └─ __init__.py
│  ├─ evolution
│  │  ├─ evolution.py
│  │  ├─ evolution_loop.py
│  │  ├─ meta_engine.py
│  │  ├─ neural_engine.py
│  │  ├─ population.py
│  │  └─ __init__.py
│  ├─ memory
│  │  ├─ consolidator.py
│  │  ├─ discovery_memory.py
│  │  ├─ experience_db.py
│  │  ├─ knowledge_store.py
│  │  ├─ memory.py
│  │  ├─ memory_engine.py
│  │  ├─ retrieval.py
│  │  └─ __init__.py
│  ├─ mission
│  │  ├─ alignment.py
│  │  ├─ constitution.py
│  │  └─ __init__.py
│  ├─ modules
│  │  ├─ base.py
│  │  ├─ registry.py
│  │  └─ __init__.py
│  ├─ safety
│  │  ├─ gate.py
│  │  ├─ policy.py
│  │  └─ __init__.py
│  ├─ sim
│  │  ├─ simulator.py
│  │  └─ __init__.py
│  └─ __init__.py
├─ tiannara_gui
│  ├─ eslint.config.js
│  ├─ index.html
│  ├─ package-lock.json
│  ├─ package.json
│  ├─ public
│  │  └─ vite.svg
│  ├─ README.md
│  ├─ src
│  │  ├─ api
│  │  │  ├─ client.js
│  │  │  ├─ discovery.js
│  │  │  ├─ modules.js
│  │  │  ├─ pros.js
│  │  │  └─ runs.js
│  │  ├─ App.css
│  │  ├─ App.jsx
│  │  ├─ assets
│  │  │  └─ react.svg
│  │  ├─ components
│  │  │  ├─ cards
│  │  │  │  ├─ MetricCard.jsx
│  │  │  │  ├─ ModuleCard.jsx
│  │  │  │  └─ StatusCard.jsx
│  │  │  ├─ charts
│  │  │  │  ├─ RetryChart.jsx
│  │  │  │  └─ RiskChart.jsx
│  │  │  ├─ discovery
│  │  │  │  ├─ ClaimsPanel.jsx
│  │  │  │  ├─ DiscoveryForm.jsx
│  │  │  │  ├─ ExperimentsPanel.jsx
│  │  │  │  ├─ HypthesesPanel.jsx
│  │  │  │  └─ SafetyPanel.jsx
│  │  │  └─ layout
│  │  │     ├─ PageShell.jsx
│  │  │     ├─ Sidebar.jsx
│  │  │     └─ Topbar.jsx
│  │  ├─ EvolutionLab.jsx
│  │  ├─ hooks
│  │  │  ├─ useApi.js
│  │  │  └─ usePlling.js
│  │  ├─ index.css
│  │  ├─ main.jsx
│  │  ├─ pages
│  │  │  ├─ AutonomousLab.jsx
│  │  │  ├─ ControlCenter.jsx
│  │  │  ├─ Dashboard.jsx
│  │  │  ├─ DiscoveryLab.jsx
│  │  │  ├─ EvolutionLab.jsx
│  │  │  ├─ MemoryLab.py
│  │  │  ├─ MemoryPage.jsx
│  │  │  ├─ ModulesPage.jsx
│  │  │  ├─ ProsControl.jsx
│  │  │  ├─ RunsPage.jsx
│  │  │  └─ SettingsPage.jsx
│  │  └─ router.jsx
│  └─ vite.config.js
└─ tiannara_pros
   ├─ actuators
   │  ├─ actuator_memory.py
   │  ├─ command_safety.py
   │  ├─ interfaces.py
   │  ├─ motor_controller.py
   │  ├─ retry_controller.py
   │  ├─ safety_monitor.py
   │  └─ __init__.py
   ├─ analytics
   │  ├─ failure_reasons.py
   │  └─ run_metrics.py
   ├─ config
   │  └─ limits.json
   ├─ docs
   │  ├─ ARCHITECTURE.md
   │  └─ FREEZE_v1.md
   ├─ io
   │  ├─ action_schema.py
   │  ├─ console_output.py
   │  ├─ emg_input.py
   │  ├─ fake_input.py
   │  ├─ input_interface.py
   │  ├─ jsonl_logger.py
   │  ├─ output_interface.py
   │  └─ run_recorder.py
   ├─ orchestrators
   │  ├─ orchestrator_day10B_skill_learning.py
   │  ├─ orchestrator_day10C_pipeline.py
   │  ├─ orchestrator_day10_realtime.py
   │  ├─ orchestrator_day20_replay.py
   │  ├─ orchestrator_day21_replay_cli.py
   │  ├─ orchestrator_day22_report.py
   │  ├─ orchestrator_day27_replay_cli.py
   │  ├─ orchestrator_day28_fail_report.py
   │  ├─ orchestrator_day29_run_scenario.py
   │  ├─ orchestrator_day4.py
   │  ├─ orchestrator_day5.py
   │  ├─ orchestrator_day6.py
   │  ├─ orchestrator_day7.py
   │  ├─ orchestrator_day8.py
   │  ├─ orchestrator_day9_feedback.py
   │  ├─ orchestrator_day9_realism.py
   │  └─ __init__.py
   ├─ scenarios
   │  ├─ crush_stress.json
   │  ├─ random_mix.json
   │  └─ slip_stress.json
   ├─ testing
   │  └─ fault_injection.py
   ├─ utils
   │  └─ config_fingerprint.py
   ├─ version.py
   └─ __init__.py

```