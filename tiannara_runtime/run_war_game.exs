alias Tiannara.OPC.RollbackManager
alias Tiannara.OED.ACM.WarGameOrchestrator

RollbackManager.start_link()
WarGameOrchestrator.start_link()

WarGameOrchestrator.launch_crucible("shard_omega_test")
WarGameOrchestrator.execute_rule_injection()
WarGameOrchestrator.execute_adversarial_pressure()
{:ok, report} = WarGameOrchestrator.execute_monitoring_and_rollback()
IO.puts(report)
