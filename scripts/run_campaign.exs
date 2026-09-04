IO.puts("==========================================================")
IO.puts(" RUNNING FULL PHASE 6-10 CAMPAIGN SEQUENCE")
IO.puts("==========================================================")
IO.puts("")

result = Tiannara.ASC.CivilizationRunner.run_all()

IO.puts("")
IO.puts("=== Campaign Run Result ===")
IO.inspect(result, label: "Result", width: 120)

IO.puts("")
IO.puts("=== Post-Run Topology ===")
topology = Tiannara.Operations.CampaignIntegration.topology()
IO.inspect(topology, label: "Topology")

IO.puts("")
IO.puts("=== Post-Run Feedback Loop State ===")
feedback_state = Tiannara.Operations.FeedbackLoop.state()
IO.inspect(feedback_state, label: "FeedbackLoop")

IO.puts("")
IO.puts("=== Post-Run Scheduler Status ===")
sched_status = Tiannara.Operations.CampaignScheduler.status()
IO.inspect(sched_status, label: "CampaignScheduler")

IO.puts("")
IO.puts("==========================================================")
IO.puts(" CAMPAIGN SEQUENCE COMPLETE")
IO.puts("==========================================================")
