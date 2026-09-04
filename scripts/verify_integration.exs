IO.puts("==========================================================")
IO.puts(" PHASE 6-10 INTEGRATION VERIFICATION")
IO.puts("==========================================================")
IO.puts("")

IO.puts("--- CivilizationRunner Readiness ---")
readiness = Tiannara.ASC.CivilizationRunner.validate_readiness()
IO.inspect(readiness, label: "Readiness")

IO.puts("")
IO.puts("--- CampaignIntegration Topology ---")
topology = Tiannara.Operations.CampaignIntegration.topology()
IO.inspect(topology, label: "Topology")

IO.puts("")
IO.puts("--- FeedbackLoop State ---")
IO.puts("State: #{inspect(Tiannara.Operations.FeedbackLoop.state())}")

IO.puts("")
IO.puts("--- CampaignScheduler Status ---")
IO.puts("Status: #{inspect(Tiannara.Operations.CampaignScheduler.status())}")

IO.puts("")
IO.puts("==========================================================")
IO.puts(" INTEGRATION VERIFICATION COMPLETE")
IO.puts("==========================================================")
