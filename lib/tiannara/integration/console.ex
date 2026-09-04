defmodule Tiannara.Integration.Console do
  @moduledoc """
  Renders a ViewModel as dashboard text for soak reports.
  """

  alias Tiannara.Integration.ViewModel

  def render(%ViewModel{} = vm) do
    """
    ── FUNNEL ──────────────────────────────────────────
    #{render_funnel(vm.funnel_counts)}

    ── OBSERVATORY ─────────────────────────────────────
    #{render_observatory(vm.observatory_summary)}

    ── KNOWLEDGE ───────────────────────────────────────
    #{render_knowledge(vm.knowledge)}
    """
  end

  defp render_funnel(%{} = counts) when counts == %{}, do: "No funnel events recorded."

  defp render_funnel(counts) do
    counts
    |> Enum.sort()
    |> Enum.map_join("\n", fn {kind, count} -> "#{kind}: #{count}" end)
  end

  defp render_observatory(%{} = summary) when summary == %{}, do: "No observatory samples."

  defp render_observatory(summary) do
    "Samples: #{summary.samples}\n" <>
      "Avg event throughput: #{Float.round(summary.avg_event_throughput, 2)}\n" <>
      "Avg discovery cycle latency: #{Float.round(summary.avg_discovery_cycle_latency, 2)}"
  end

  defp render_knowledge(nil), do: "No knowledge artifacts."
  defp render_knowledge(_), do: "Knowledge artifacts present."
end