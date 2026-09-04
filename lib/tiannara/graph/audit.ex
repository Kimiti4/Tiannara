defmodule Tiannara.Graph.Audit do
  @moduledoc """
  Read-only graph analysis over any `Graph.Behaviour` implementation:
  lineage (ancestors), blast radius (descendants), cycle detection, and
  claim-contradiction detection.

  Constitutional basis: "Preserve lineage", "Maintain audit trails",
  "Every architectural decision should remain traceable".
  """

  alias Tiannara.Logic.Contradiction, as: KernelContradiction

  @doc """
  All contradiction records reachable from `:claims`-labeled edges.

  Claims edges carry `%{subject: s, value: v}` (or `%{quantity: s, value: v}`,
  the knowledge-domain spelling used by the constitutional registry) in their
  `:metadata`. Edges sharing a subject are paired and each pair is decided by
  the canonical kernel `Tiannara.Logic.Contradiction.detect/2` — the sole
  value-conflict engine. Returns a (possibly empty) list of
  `%{type: :contradiction, subject: _, claim_a: _, claim_b: _}` maps.
  """
  def find_contradictions(g) do
    g
    |> claim_edges(g)
    |> Enum.group_by(&claim_subject/1)
    |> Enum.flat_map(fn {subject, edges} ->
      edges
      |> ordered_pairs()
      |> Enum.filter(fn {a, b} ->
        KernelContradiction.detect(edge_claim(a), edge_claim(b)) == :contradiction
      end)
      |> Enum.map(fn {a, b} ->
        %{
          type: :contradiction,
          subject: subject,
          claim_a: edge_claim(a),
          claim_b: edge_claim(b)
        }
      end)
    end)
  end

  defp claim_edges(g, _g), do: Enum.filter(g.__struct__.edges(g), &(&1.label == :claims))

  defp claim_subject(%{metadata: %{subject: s}}) when not is_nil(s), do: s
  defp claim_subject(%{metadata: %{quantity: q}}) when not is_nil(q), do: q
  defp claim_subject(%{to: to}), do: to

  defp edge_claim(%{metadata: %{subject: s, value: v}, from: from}),
    do: %{subject: s, value: v, source: from}

  defp edge_claim(%{metadata: %{quantity: s, value: v}, from: from}),
    do: %{subject: s, value: v, source: from}

  defp edge_claim(%{metadata: %{value: v}, to: subject, from: from}),
    do: %{subject: subject, value: v, source: from}

  defp ordered_pairs(edges) do
    edges
    |> Enum.with_index()
    |> Enum.flat_map(fn {a, i} ->
      edges
      |> Enum.drop(i + 1)
      |> Enum.map(fn b -> {a, b} end)
    end)
  end

  @doc "All ancestor node ids reachable from `node` via `in_edges` (exclusive)."
  def lineage(g, node) do
    g
    |> do_walk([node], :in)
    |> MapSet.delete(node)
    |> MapSet.to_list()
  end

  @doc "All descendant node ids reachable from `node` via `out_edges` (exclusive)."
  def blast_radius(g, node) do
    g
    |> do_walk([node], :out)
    |> MapSet.delete(node)
    |> MapSet.to_list()
  end

  @doc "True when the graph contains at least one cycle."
  def has_cycle?(g) do
    g
    |> node_ids()
    |> Enum.any?(fn start -> detect_cycle(g, start, MapSet.new(), MapSet.new()) end)
  end

  defp do_walk(g, start_ids, direction) do
    {step, neighbor} =
      case direction do
        :in -> {&in_edges/2, & &1.from}
        :out -> {&out_edges/2, & &1.to}
      end

    walk(g, start_ids, step, neighbor, MapSet.new())
  end

  defp walk(_g, [], _step, _neighbor, seen), do: seen

  defp walk(g, [id | rest], step, neighbor, seen) do
    if MapSet.member?(seen, id) do
      walk(g, rest, step, neighbor, seen)
    else
      next =
        g
        |> step.(id)
        |> Enum.map(neighbor)

      walk(g, next ++ rest, step, neighbor, MapSet.put(seen, id))
    end
  end

  defp detect_cycle(g, start, _visited, stack) do
    if MapSet.member?(stack, start) do
      true
    else
      g
      |> out_edges(start)
      |> Enum.any?(fn %{to: to} ->
        detect_cycle(g, to, MapSet.put(stack, start), MapSet.put(stack, start))
      end)
    end
  end

  defp in_edges(g, id), do: g.__struct__.in_edges(g, id)
  defp out_edges(g, id), do: g.__struct__.out_edges(g, id)
  defp node_ids(g), do: g.__struct__.node_ids(g)
end