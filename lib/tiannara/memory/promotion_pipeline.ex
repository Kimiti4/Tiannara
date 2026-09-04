defmodule Tiannara.Memory.PromotionPipeline do
  @moduledoc """
  Guardrails for memory artifact promotion between rungs.

  Ensures memory promotion never skips a rung without evidence, and always
  returns explicit diagnostics.

    data → information → knowledge → pattern → model → principle → insight → discovery

  Constitutional basis: Evidence Before Confidence, "No evidence is upgraded
  to fact without provenance."
  """

  @rung_order [:data, :information, :knowledge, :pattern, :model, :principle, :insight, :discovery]

  def promote(artifact, target_rung, context) do
    current_rung = artifact.rung || :data

    case required_evidence(current_rung, target_rung) do
      {:ok, required} ->
        missing = missing_evidence(required, context)

        if missing == [] do
          {:ok, do_promote(artifact, target_rung, context)}
        else
          {:halted, target_rung, missing, context}
        end

      {:error, reason} ->
        {:halted, target_rung, [:invalid_rung_transition, reason], context}
    end
  end

  defp required_evidence(from, to) do
    from_idx = Enum.find_index(@rung_order, &(&1 == from))
    to_idx = Enum.find_index(@rung_order, &(&1 == to))

    cond do
      from_idx == nil -> {:error, :unknown_source_rung}
      to_idx == nil -> {:error, :unknown_target_rung}
      to_idx <= from_idx -> {:error, :cannot_demote}
      to_idx - from_idx > 1 -> {:ok, rungs_between(from, to)}
      true -> {:ok, []}
    end
  end

  defp rungs_between(from, to) do
    from_idx = Enum.find_index(@rung_order, &(&1 == from))
    to_idx = Enum.find_index(@rung_order, &(&1 == to))

    @rung_order
    |> Enum.slice(from_idx + 1, to_idx - from_idx - 1)
    |> Enum.map(&{&1, :required_evidence})
  end

  defp missing_evidence(required, context) do
    Enum.filter(required, fn {rung, _} ->
      not has_evidence_for?(rung, context)
    end)
  end

  defp has_evidence_for?(rung, context) do
    case Map.get(context, rung) do
      nil -> false
      artifacts when is_list(artifacts) -> length(artifacts) > 0
      artifacts when is_map(artifacts) -> map_size(artifacts) > 0
      _ -> true
    end
  end

  defp do_promote(artifact, target_rung, _context) do
    %{artifact | rung: target_rung, confidence: artifact.confidence}
  end
end
