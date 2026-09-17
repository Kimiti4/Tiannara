defmodule Tiannara.OPC.InjectionEngine do
  @moduledoc """
  Phase 5F.9 — Rule injection engine.
  Injects compiled physics rules into MSCL and OLEF runtime layers.
  """

  alias Tiannara.OPC.RuleStore
  require Logger

  def inject(rules) when is_list(rules) do
    Enum.each(rules, &inject_single/1)
  end

  defp inject_single(rule) do
    RuleStore.put(rule)
    notify_mscl(rule)
    notify_olef(rule)
  end

  defp notify_mscl(rule) do
    if Process.whereis(Tiannara.MSCL.Supervisor) do
      GenServer.cast(Tiannara.MSCL.Supervisor, {:inject_rule, rule})
    else
      Logger.debug("[OPC] MSCL supervisor not available; skipping rule injection.")
    end
  end

  defp notify_olef(rule) do
    if Process.whereis(Tiannara.OLEF.FieldSupervisor) do
      GenServer.cast(Tiannara.OLEF.FieldSupervisor, {:inject_rule, rule})
    else
      Logger.debug("[OPC] OLEF field supervisor not available; skipping rule injection.")
    end
  end
end
