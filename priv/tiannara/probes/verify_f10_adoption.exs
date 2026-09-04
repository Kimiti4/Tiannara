{:ok, _} = Supervisor.start_link([Tiannara.CIS.Supervisor], strategy: :one_for_one, name: :verify_sup)
t1 = %{executive_memory_health: :healthy, event_store_healthy: true, event_bus_health: :healthy, memory_pressure: 0.1, dets_health: true}
t2 = %{executive_memory_health: :unhealthy, event_store_healthy: false, event_bus_health: :unhealthy, memory_pressure: 0.95, dets_health: false}
r1 = Tiannara.CIS.CollapsePredictor.assess_risk(t1)
r2 = Tiannara.CIS.CollapsePredictor.assess_risk(t2)
r_nil = Tiannara.CIS.CollapsePredictor.assess_risk(nil)
r_missing = Tiannara.CIS.CollapsePredictor.assess_risk(%{event_store_healthy: true})
r_100 = for _ <- 1..100, do: Tiannara.CIS.CollapsePredictor.assess_risk(t1)
uniq = r_100 |> Enum.map(& &1.risk_score) |> Enum.uniq() |> length()
IO.puts("VERIFY_F10 r1_score=#{r1.risk_score} r2_score=#{r2.risk_score} r_nil=#{inspect(r_nil)} r_missing=#{inspect(r_missing)} deterministic_uniq=#{uniq} r1_factors=#{length(r1.contributing_factors)} r2_factors=#{length(r2.contributing_factors)}")
