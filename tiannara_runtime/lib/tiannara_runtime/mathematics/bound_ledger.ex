defmodule TiannaraRuntime.Mathematics.BoundLedger do
  @moduledoc """
  Records mathematical bounds with provenance and epistemic status.

  Bounds are reusable constraints, not universal truths unless backed by a
  proof artifact from an approved kernel.
  """

  def record(bound, evidence) when is_map(bound) and is_map(evidence) do
    status = if Map.get(evidence, :status) == :proved, do: :proved, else: :supported
    {:ok, Map.merge(bound, %{
      epistemic_status: status,
      evidence: evidence,
      reusable_as_constraint: status == :proved
    })}
  end

  def record(_, _), do: {:error, :bound_evidence_required}
end
