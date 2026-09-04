defmodule Tiannara.Interface.PipelinePanel do
  @moduledoc """
  The Discovery Pipeline view — makes Tiannara's scientific activity
  transparent and EXPLAINABLE.

  Shows every funnel stage's count and provides `drill_down/2` to answer
  "why did the number drop here?" by returning the explicit disposition
  (promoted / rejected-by-reason / pending / silent loss).

  Constitutional basis: Explainability, Observability,
  "Uncertainty should never be hidden."
  """

  alias Tiannara.Diagnostics.DiscoveryFunnel

  @labels %{
    observations: "Observations",
    gaps: "Gaps",
    hypotheses: "Hypotheses",
    ranked_hypotheses: "Ranked Hypotheses",
    experiments_proposed: "Experiments Proposed",
    experiments_scheduled: "Experiments Scheduled",
    experiments_started: "Experiments Running",
    experiments_completed: "Experiments Completed",
    evidence_generated: "Evidence Generated",
    knowledge_integrated: "Knowledge Integrated",
    discovery_candidates: "Discovery Candidates",
    validated_discoveries: "Validated Discoveries"
  }

  def label(nil), do: "—"
  def label(stage), do: Map.get(@labels, stage, to_string(stage))

  def render(%DiscoveryFunnel{} = f) do
    rows = Enum.map(DiscoveryFunnel.stages(), fn s -> {label(s), count(f, s)} end)

    label_w = rows |> Enum.map(fn {l, _} -> String.length(l) end) |> Enum.max()
    count_w = rows |> Enum.map(fn {_, n} -> String.length(fmt(n)) end) |> Enum.max()
    cw = label_w + count_w + 2

    title = "│" <> center("SCIENTIFIC ACTIVITY", cw) <> "│"
    sep = "├" <> String.duplicate("─", cw) <> "┤"
    top = "┌" <> String.duplicate("─", cw) <> "┐"
    bot = "└" <> String.duplicate("─", cw) <> "┘"

    data_lines =
      Enum.map(rows, fn {l, n} ->
        "│ " <> String.pad_trailing(l, label_w) <> " " <>
          String.pad_leading(fmt(n), count_w) <> " │"
      end)

    box = Enum.join([top, title, sep | data_lines] ++ [bot], "\n")
    box <> "\n" <> status_block(f)
  end

  defp status_block(f) do
    inv = if f.violations == [], do: "SATISFIED", else: "VIOLATED"
    base = "state: #{f.zero_state}   invariant: #{inv}"

    case f.violations do
      [] -> base
      vs -> base <> "\n" <> Enum.map_join(vs, "\n", fn v -> "⚠ " <> v.message end)
    end
  end

  @doc """
  Returns the explicit disposition between `from_stage` and its next stage —
  the answer to "why did the number change?"
  """
  def drill_down(%DiscoveryFunnel{} = f, from_stage) do
    to_stage = next_stage(from_stage)
    upstream = count(f, from_stage)
    promoted = Map.get(f.promoted, from_stage, 0)
    reasons = Map.get(f.rejected_reasons, from_stage, %{})
    unexplained = Map.get(f.unexplained, from_stage, 0)

    %{
      from: from_stage,
      to: to_stage,
      upstream: upstream,
      downstream: count(f, to_stage),
      promoted: promoted,
      not_promoted: upstream - promoted,
      rejected: reasons |> Map.values() |> Enum.sum(),
      reasons: reasons,
      pending: Map.get(f.pending, from_stage, 0),
      closed: Map.get(f.closed, from_stage, 0),
      unexplained: unexplained,
      silent_loss?: unexplained > 0
    }
  end

  def render_drill_down(%DiscoveryFunnel{} = f, from_stage) do
    dd = drill_down(f, from_stage)

    reason_lines =
      dd.reasons
      |> Enum.sort_by(fn {_r, n} -> -n end)
      |> Enum.map(fn {r, n} -> "    #{String.pad_leading(to_string(n), 4)} #{r}" end)

    warn =
      if dd.silent_loss?,
        do: "\n  ⚠ SILENT LOSS: #{dd.unexplained} #{dd.from} have no disposition",
        else: ""

    """
    #{label(dd.from)} (#{fmt(dd.upstream)})
           ↓
    #{label(dd.to)} (#{fmt(dd.downstream)})

    #{fmt(dd.not_promoted)} not promoted
      promoted:   #{fmt(dd.promoted)}
      pending:    #{fmt(dd.pending)}
      closed:     #{fmt(dd.closed)}
      rejected:   #{fmt(dd.rejected)}
    Reasons:
    #{Enum.join(reason_lines, "\n")}#{warn}
    """
  end

  defp next_stage(stage) do
    stages = DiscoveryFunnel.stages()
    i = Enum.find_index(stages, &(&1 == stage))
    Enum.at(stages, i + 1)
  end

  defp count(f, stage), do: Map.get(f.counts, stage, 0)

  defp fmt(n) when is_integer(n), do: n |> Integer.to_string() |> thousands()
  defp fmt(n), do: to_string(n)

  defp thousands(s),
    do: s |> String.reverse() |> String.replace(~r/(\d{3})(?=\d)/, "\\1,") |> String.reverse()

  defp center(s, w) do
    pad = max(w - String.length(s), 0)
    left = div(pad, 2)
    String.duplicate(" ", left) <> s <> String.duplicate(" ", pad - left)
  end
end
