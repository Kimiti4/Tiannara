defmodule Tiannara.TechDebt.Item do
  @moduledoc """
  A single tech-debt item: categorized, located, prioritized, and tracked.
  Constitutional basis: Continuous Self-Evaluation ("What technical debt
  exists?"), Observability, "Maintain audit trails."
  """

  @enforce_keys [:id, :category, :description]
  defstruct [:id, :category, :description, :severity, :location, :effort,
             status: :open, notes: []]

  @severities [:low, :medium, :high, :critical]
  def severities, do: @severities

  def severity_rank(:critical), do: 3
  def severity_rank(:high), do: 2
  def severity_rank(:medium), do: 1
  def severity_rank(:low), do: 0
  def severity_rank(_), do: 0
end