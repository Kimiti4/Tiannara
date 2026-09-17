defmodule Tiannara.OPC.RealityCompiler.InjectionEngine do

  def inject(rules) do
    Enum.each(rules, fn rule ->
      Tiannara.OPC.RuleStore.put(rule)

      # Try to inject into MSCL if available
      case Process.whereis(Tiannara.MSCL.ConstraintEngine) do
        nil -> :ok  # MSCL not running
        pid -> GenServer.cast(pid, {:inject_rule, rule})
      end

      # Try to inject into OLEF if available
      case Process.whereis(Tiannara.OLEF.FieldSupervisor) do
        nil -> :ok  # OLEF not running
        pid -> GenServer.cast(pid, {:inject_rule, rule})
      end
    end)
  end
end
