defmodule Tiannara.Epistemic.View do
  @moduledoc """
  Rendering for the epistemic debugger. Produces a human-readable, auditable
  view of a provenance chain and its nodes.

  Constitutional basis: Explainability, "Transparent reasoning, reproducible
  methods, and evidence-based analysis" (augmentation clause).
  """

  alias Tiannara.Epistemic.Node

  def render_provenance(%Node{} = node, chain, blast) do
    """
    ════════ EPISTEMIC PROVENANCE — #{inspect(node.id)} ════════
    stage: #{node.stage}    depth: #{length(chain)}    blast_radius: #{length(blast)}

    #{render_chain(chain)}
    ════════ end provenance ════════
    """
  end

  def render_chain(chain) do
    chain
    |> Enum.with_index(1)
    |> Enum.map(fn {node, i} -> render_node(node, i) end)
    |> Enum.join("\n      ↓\n")
  end

  def render_node(%Node{} = node, index \\ nil) do
    idx = if index, do: "[#{index}] ", else: ""

    """
    #{idx}#{String.upcase(to_string(node.stage))}  (#{inspect(node.id)})
        subsystem:      #{inspect(node.responsible_subsystem)}
        timestamp:      #{inspect(node.timestamp)}
        confidence:     #{format_confidence(node.confidence)}
        disposition:    #{inspect(node.disposition)}
        content:        #{inspect(node.content)}
        lineage:        #{inspect(node.lineage)}
        assumptions:    #{inspect(node.assumptions)}
        unknowns:       #{inspect(node.unknowns)}
        contradictions: #{inspect(node.contradictions)}
        checks:         #{inspect(node.constitutional_checks)}
    """
    |> String.trim_trailing()
  end

  defp format_confidence(nil), do: "n/a"
  defp format_confidence(c) when is_number(c), do: to_string(Float.round(c * 1.0, 3))
  defp format_confidence(c), do: inspect(c)
end