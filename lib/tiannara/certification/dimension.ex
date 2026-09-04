defmodule Tiannara.Certification.Dimension do
  @moduledoc "One certification dimension with its criticality and evaluated status."
  @enforce_keys [:id, :criticality, :status]
  defstruct [:id, :criticality, :status, :evidence, :detail]
end

defmodule Tiannara.Certification.DimensionPolicy do
  @moduledoc """
  Declares the certification dimensions and their criticality, and enforces the
  core rule: NO `CERTIFIED` state if any critical dimension is failed OR
  unevaluated. An unevaluated critical dimension is treated as blocking, never
  assumed passing.

  Constitutional basis: "Never optimize for appearing correct. Optimize for
  being correct", "Capability must never outpace verification", "Truth has
  priority over confidence", "Uncertainty should never be hidden."
  """

  @dimensions %{
    constitutional_invariants: :critical,
    recovery: :critical,
    evidence_integrity: :critical,
    funnel_integrity: :critical,
    adversarial_detection: :critical,
    authorization_integrity: :critical,
    deterministic_replay: :advisory
  }

  def dimensions, do: @dimensions
  def dimension_ids, do: Map.keys(@dimensions)
  def criticality(id), do: Map.get(@dimensions, id, :advisory)

  @doc """
  Overall verdict. `:certified` only when every critical dimension has status
  `:pass`. Any critical `:fail` or `:unevaluated` blocks certification.
  Advisory dimensions never block.
  """
  def overall_verdict(dimensions) do
    critical = Enum.filter(dimensions, &(&1.criticality == :critical))
    failed = for d <- critical, d.status == :fail, do: d.id
    unevaluated = for d <- critical, d.status == :unevaluated, do: d.id

    cond do
      failed != [] -> {:not_certified, {:dimensions_failed, failed}}
      unevaluated != [] -> {:not_certified, {:dimensions_unevaluated, unevaluated}}
      true -> :certified
    end
  end
end