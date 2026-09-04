defmodule Tiannara.Funnel.Integrity do
  @moduledoc """
  Verifies funnel event streams for completeness and silent-loss detection.

  Given a list of funnel events (the canonical `{:created, stage, id, parents}`
  and `{:disposition, stage, id, kind, reason}` tuples from Discovery.Pipeline),
  this verifier checks:

    * Every `:created` item has a terminal disposition (advanced/rejected/blocked/
      failed/deferred/duplicate/not_applicable). Nothing is left dangling.
    * The funnel has a single terminal stage.
    * If discoveries exist but candidates don't advance, that's `:validation_rejected`.
    * If candidates exist but zero advance, that's `:blocked`.
    * If upstream exists but downstream is empty and not blocked, that's
      `:advanced_but_empty` (silent loss).

  Constitutional basis: "No silent loss", "Uncertainty should never be hidden."
  """

  defstruct [
    :stages,
    :complete?,
    :unexplained,
    :terminal_discoveries,
    :blockages,
    :diagnosis
  ]

  def verify(events) do
    stages = build_stage_map(events)
    unexplained = find_unexplained(stages)
    blockages = find_blockages(events)
    discoveries = count_stage(stages, :validated_discoveries)

    diagnosis = classify(discoveries, unexplained, blockages, stages)
    complete? = map_size(unexplained) == 0

    %__MODULE__{
      stages: stages,
      complete?: complete?,
      unexplained: unexplained,
      terminal_discoveries: discoveries,
      blockages: blockages,
      diagnosis: diagnosis
    }
  end

  defp build_stage_map(events) do
    events
    |> Enum.reduce(%{}, fn
      {:created, stage, id, _parents}, acc ->
        update_stage(acc, stage, id, :created, 1)

      {:disposition, stage, id, kind, _reason}, acc ->
        update_stage(acc, stage, id, kind, 1)
    end)
  end

  defp update_stage(acc, stage, id, kind, count) do
    stage_data = Map.get(acc, stage, %{created: 0, dispositions: %{}, ids: []})

    dispositions =
      if kind == :created do
        stage_data.dispositions
      else
        Map.update(stage_data.dispositions, kind, count, &(&1 + count))
      end

    ids = if id in stage_data.ids, do: stage_data.ids, else: [id | stage_data.ids]

    total_created =
      stage_data.created + if(kind == :created, do: count, else: 0)

    Map.put(acc, stage, %{
      created: total_created,
      dispositions: dispositions,
      ids: ids,
      unexplained: 0
    })
  end

  defp find_unexplained(stages) do
    Enum.reduce(stages, %{}, fn {stage, data}, acc ->
      total_disposed =
        data.dispositions
        |> Map.values()
        |> Enum.sum()

      unexplained = data.created - total_disposed

      if unexplained > 0 do
        Map.put(acc, stage, %{created: data.created, unexplained: unexplained})
      else
        acc
      end
    end)
  end

  defp find_blockages(events) do
    events
    |> Enum.filter(fn
      {:disposition, _, _, kind, _} when kind in [:blocked, :failed] -> true
      _ -> false
    end)
    |> Enum.map(fn {:disposition, stage, _id, kind, reason} ->
      %{stage: stage, kind: kind, reasons: %{reason => 1}}
    end)
  end

  defp count_stage(stages, stage_name) do
    case Map.get(stages, stage_name) do
      nil -> 0
      data -> map_size(data.dispositions) |> then(fn _ -> data.created end)
    end
  end

  defp classify(discoveries, unexplained, blockages, stages) do
    cond do
      map_size(unexplained) > 0 ->
        :silent_loss

      length(blockages) > 0 ->
        :blocked

      discoveries > 0 ->
        :discovery_generated

      count_stage(stages, :discovery_candidates) > 0 and
          count_stage(stages, :validated_discoveries) == 0 ->
        :validation_rejected

      count_stage(stages, :discovery_candidates) == 0 and
          count_stage(stages, :knowledge_integrated) > 0 ->
        :advanced_but_empty

      count_stage(stages, :observations) > 0 and
          count_stage(stages, :gaps) == 0 ->
        :no_signal

      true ->
        :no_discoveries
    end
  end
end
