{:ok, _bridge} = Tiannara.Bridge.Supervisor.start_link([])
{:ok, _rrg} = Tiannara.RRG.Supervisor.start_link([])

IO.puts("--- Bridge evaluate_stability ---")
IO.inspect(Tiannara.Bridge.evaluate_stability())

IO.puts("--- Bridge tick (dummy states) ---")
IO.inspect(Tiannara.Bridge.tick(%{}, %{}))

IO.puts("--- RRG check_stability ---")
IO.inspect(Tiannara.RRG.check_stability())
