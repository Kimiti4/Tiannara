defmodule Tiannara.TechDebt.Report do
  @moduledoc """
  Renders a prioritized tech-debt report. Constitutional basis: Observability,
  Continuous Self-Evaluation, Explainability.
  """

  alias Tiannara.TechDebt.Registry

  def render(%Registry{} = registry) do
    items = Registry.prioritize(registry)
    open = Enum.filter(items, &(&1.status == :open))

    header = """
    ════════ TECH-DEBT REPORT ════════
    total: #{length(items)}    open: #{length(open)}
    """

    lines =
      Enum.map(items, fn item ->
        "[#{String.upcase(to_string(item.severity))}] " <>
          "(#{item.status}) #{item.category} @ #{item.location} :: #{item.description}"
      end)

    header <> Enum.join(lines, "\n")
  end
end