defmodule Tiannara.Interface.Renderer.Console do
  @moduledoc """
  Dep-free console renderer composing all four panels. Surfaces warnings
  prominently because "Uncertainty should never be hidden."
  """

  @behaviour Tiannara.Interface.Renderer

  alias Tiannara.Interface.{ViewModel, PipelinePanel}
  alias Tiannara.Repro.Manifest
  alias Tiannara.Observatory

  @impl true
  def render(%ViewModel{} = vm) do
    [
      header(vm),
      pipeline(vm.funnel),
      recovery(vm.manifest),
      bottlenecks(vm.observatory),
      knowledge(vm.knowledge)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n\n")
  end

  defp header(vm),
    do: "TIANNARA — Scientific & Engineering Dashboard\ngenerated: #{vm.generated_at}"

  defp pipeline(nil), do: nil
  defp pipeline(funnel), do: PipelinePanel.render(funnel)

  defp recovery(nil), do: nil

  defp recovery(manifest),
    do: "── RECOVERY / EVIDENCE TRUST ─────────────\n" <> Manifest.recovery_attestation(manifest)

  defp bottlenecks(nil), do: nil

  defp bottlenecks(observatory) when is_map(observatory) do
    bottlenecks = Map.get(observatory, :bottlenecks, [])
    watch = Map.get(observatory, :watch, [])
    healthy = Map.get(observatory, :healthy, [])

    lines = [
      "── BOTTLENECK OBSERVATORY ─────────────────",
      "bottlenecks: #{length(bottlenecks)}   watch: #{length(watch)}   healthy: #{length(healthy)}"
    ]

    warns = Enum.map(bottlenecks, fn r -> "  ⚠ " <> to_string(Map.get(r, :interpretation, "bottleneck")) end)
    Enum.join(lines ++ warns, "\n")
  end

  defp knowledge([]), do: nil

  defp knowledge(artifacts) do
    by_rung = Enum.group_by(artifacts, & &1.rung)
    rung_lines = Enum.map(by_rung, fn {rung, list} -> "  #{rung}: #{length(list)}" end)
    principles = for a <- artifacts, a.rung == :principle, do: "  • " <> a.content

    Enum.join(
      ["── KNOWLEDGE (offline evolution) ──────────", "artifacts: #{length(artifacts)}"] ++
        rung_lines ++ principles,
      "\n"
    )
  end
end
