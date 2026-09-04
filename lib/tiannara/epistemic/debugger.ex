defmodule Tiannara.Epistemic.Debugger do
  @moduledoc """
  The epistemic debugger: select any epistemic artifact and inspect its full
  provenance chain, blast radius, and audit metadata.

  READ-ONLY by construction. It explains what each Ω layer produced; it never
  mutates, executes, or communicates — preserving the layer-authority boundary
  (Sentinel observes · Research Director investigates · Cognitive Interface
  communicates · Human judges).

  Constitutional basis: Explainability, Observability, "Maintain audit trails",
  "Uncertainty should never be hidden", "Every architectural decision should
  remain traceable."
  """

  alias Tiannara.Epistemic.{Node, View}

  defstruct nodes: %{}

  @doc "Build a debugger over a collection of Epistemic.Node structs."
  def new(nodes) when is_list(nodes) do
    %__MODULE__{nodes: Map.new(nodes, &{&1.id, &1})}
  end

  @doc "Fetch a node by id."
  def get(%__MODULE__{nodes: nodes}, id), do: Map.get(nodes, id)

  @doc """
  Trace the provenance chain from a node back to its root observation.
  Returns the chain root-first. Cycle-safe.
  """
  def provenance_chain(%__MODULE__{} = dbg, id) do
    do_chain(dbg, id, [], MapSet.new())
  end

  defp do_chain(dbg, id, acc, seen) do
    if MapSet.member?(seen, id) do
      acc
    else
      case Map.get(dbg.nodes, id) do
        nil ->
          acc

        %Node{} = node ->
          seen = MapSet.put(seen, id)
          acc = [node | acc]

          case node.lineage do
            [] -> acc
            [parent | _] -> do_chain(dbg, parent, acc, seen)
          end
      end
    end
  end

  @doc "All nodes that transitively depend on the given node (forward reach)."
  def blast_radius(%__MODULE__{} = dbg, id) do
    children_index = build_children_index(dbg)

    children_index
    |> do_blast([id], MapSet.new([id]))
    |> MapSet.delete(id)
    |> MapSet.to_list()
  end

  defp build_children_index(%__MODULE__{nodes: nodes}) do
    Enum.reduce(nodes, %{}, fn {id, node}, acc ->
      Enum.reduce(node.lineage, acc, fn parent_id, acc2 ->
        Map.update(acc2, parent_id, [id], &[id | &1])
      end)
    end)
  end

  defp do_blast(_index, [], visited), do: visited

  defp do_blast(index, [id | rest], visited) do
    children = Map.get(index, id, [])

    {rest2, visited2} =
      Enum.reduce(children, {rest, visited}, fn c, {r, v} ->
        if MapSet.member?(v, c), do: {r, v}, else: {[c | r], MapSet.put(v, c)}
      end)

    do_blast(index, rest2, visited2)
  end

  @doc "Rich inspection of one node: its depth, root, and blast radius."
  def inspect_node(%__MODULE__{} = dbg, id) do
    case get(dbg, id) do
      nil ->
        nil

      %Node{} = node ->
        chain = provenance_chain(dbg, id)
        blast = blast_radius(dbg, id)

        %{
          node: node,
          depth: length(chain),
          distance_from_root: length(chain) - 1,
          root: List.first(chain),
          blast_radius: blast
        }
    end
  end

  @doc "Render the full provenance view for a selected node."
  def render_provenance(%__MODULE__{} = dbg, id) do
    case get(dbg, id) do
      nil ->
        "epistemic node #{inspect(id)} not found"

      %Node{} = node ->
        chain = provenance_chain(dbg, id)
        blast = blast_radius(dbg, id)
        View.render_provenance(node, chain, blast)
    end
  end

  # --- audit queries ------------------------------------------------------

  @doc "Nodes that carry unresolved contradictions."
  def find_contradictions(%__MODULE__{nodes: nodes}) do
    nodes |> Map.values() |> Enum.filter(&(length(&1.contradictions) > 0))
  end

  @doc "Nodes that have no constitutional checks recorded (audit gaps)."
  def find_unchecked(%__MODULE__{nodes: nodes}) do
    nodes |> Map.values() |> Enum.filter(&(length(&1.constitutional_checks) == 0))
  end

  @doc "Nodes below a confidence threshold (candidates for more evidence)."
  def find_low_confidence(%__MODULE__{nodes: nodes}, threshold \\ 0.5) do
    nodes
    |> Map.values()
    |> Enum.filter(fn n -> is_number(n.confidence) and n.confidence < threshold end)
  end
end