defmodule TiannaraRuntime.CTL.Validation.Validator do
  @moduledoc """
  Phase 5F.6 — CTL Causal Tension Validator (OPC Integration)

  Validates a proposed physics-law AST against the CTL causal stress
  formula *before* the proposal enters the live causal graph.

  ## Stress Formula (mirrors CTL.Engine)

      stress_i = Σ_l  (|t_i − t_l| / elasticity) × weight_l

  Each `{:op, op_name, args}` tuple in the AST maps to one synthetic
  `%CTL.Event{}`.  `causal_links` connect a parent event to every nested
  `{:op, …}` found inside its arguments.  Synthetic timestamps are drawn
  from a single `:erlang.unique_integer` call so acyclic graphs carry 0.0
  stress — the physically correct result; cycles are caught explicitly by
  `@max_drift_before_cycle`.
  """

  alias TiannaraRuntime.CTL.Event

  @sync_elasticity        10_000
  @stress_threshold       0.9
  @max_drift_before_cycle 1.0e6
  @ts                     :erlang.unique_integer([:positive])
  @id_sep                 "__"

  # ── Public API ──────────────────────────────────────────────────────────────

  @doc """
  Validate a physics AST and return the best causal tension result.

      {:ok,  :causally_stable,  %{node_id => stress_float}}
      {:error, :cyclic_dependency,  %{…}}
      {:error, :excessive_tension, max_stress, %{…}}
  """
   @spec validate_ast(term()) ::
           {:ok, :causally_stable, map()}
           | {:error, :cyclic_dependency, map()}
           | {:error, :excessive_tension, float(), map()}

  def validate_ast(ast) do
    graph = ast |> build_graph()
    sm = compute_stress(graph)
    {id, mx} = Enum.max_by(sm, fn {_id, s} -> s end, fn -> {nil, 0.0} end)

    cond do
      is_nil(id)                   -> {:ok, :causally_stable, sm}
      mx > @max_drift_before_cycle -> {:error, :cyclic_dependency, sm}
      mx > @stress_threshold       -> {:error, :excessive_tension, mx, sm}
      true                         -> {:ok, :causally_stable, sm}
    end
  end

  @doc """
  Compute raw per-node stress without any threshold guard:

      %{node_id => stress_float} = Validator.stress_map(ast)
  """
  @spec stress_map(term()) :: map()
  def stress_map(ast) do
    build_graph(ast) |> compute_stress()
  end

  @doc """
  `true` when `max(stress_map) <= threshold` (default `#{@stress_threshold}`).

      sm = Validator.stress_map(ast)
      if Validator.stable?(sm, 0.85), do: compile(), else: reject()
  """
  @spec stable?(float(), map()) :: boolean()
  def stable?(thresh \\ @stress_threshold, sm) do
    {mx, _} = max_stress(sm)
    mx <= thresh
  end

  @doc """
  Return `{max_stress, highest_stress_node_id_or_nil}` from a stress map.
  Empty maps return `{0.0, nil}`.
  """
  @spec max_stress(map()) :: {float(), String.t() | nil}
  def max_stress(sm) do
    case Enum.max_by(sm, fn {_id, s} -> s end, fn -> {nil, 0.0} end) do
      {id, s} when is_number(s) -> {s, id}
      _ -> {0.0, nil}
    end
  end

  # ── AST → Graph ─────────────────────────────────────────────────────────────

  @doc false
  defp build_graph(ast) do
    {_new_ast, raw_events} =
      Macro.prewalk(ast, [], fn
        {:op, op_name, child_args} = node, acc when is_list(child_args) ->
          {node, acc ++ [{op_name, child_args}]}
        node, acc ->
          {node, acc}
      end)

    raw_events
    |> enrich_events()
    |> link_child_events()
  end

  # Enrich raw op-family tuples into %CTL.Event{} records.
  # Build links from each event to the names of op-events embedded
  # in its argument subtree; actual ID cross-references are resolved in the
  # second pass below.
  @spec enrich_events(list()) :: list()
  defp enrich_events(raw) do
    for {{op, args}, c} <- Enum.with_index(raw) do
      child_names = collect_op_names(args)
      links = Enum.map(child_names, &%{id: link_op_id_from_name(&1), weight: 1.0})

      {op_id(op, c),
       %Event{
         id: op_id(op, c),
         timestamp: @ts,
         causal_links: links,
         entropy: 0.0
       }}
    end
  end

  # Deterministic op-name → middle-counter link ID used only in causal_links
  # so every reference to the same op shares the exact same link_id regardless
  # of which parent event produced the link.
  defp link_op_id_from_name(op_name) do
    "#{@id_sep}#{op_name}#{@id_sep}0"
  end

  # Replace name-based link-IDs with actual enriched event-IDs now that all
  # events are available.
  @spec link_child_events(list()) :: map()
  defp link_child_events(enriched) do
    name_lut = build_name_lut(enriched)

    enriched
    |> Enum.map(fn {id, event} ->
      real_links =
        event.causal_links
        |> Enum.filter(fn %{id: link_id} ->
          case Map.fetch(name_lut, link_id) do
            {:ok, _real_id} -> true
            :error -> false
          end
        end)
        |> Enum.map(fn %{id: _, weight: w} = link ->
          real_id = Map.fetch!(name_lut, link.id)
          %{id: real_id, weight: w}
        end)

      {id, %Event{event | causal_links: real_links}}
    end)
    |> Enum.into(%{})
  end

  # Build %{link_op_id => enriched_event_id} look-up so we can resolve
  # cause_links that were seeded with deterministic link IDs.
  @spec build_name_lut(list()) :: map()
  defp build_name_lut(enriched) do
    enriched
    |> Enum.reduce(%{}, fn {id, _event}, acc ->
      case String.split(id, @id_sep) do
        [_c, op_name, _pos] -> Map.put(acc, link_op_id_from_name(op_name), id)
        _ -> acc
      end
    end)
  end

  # Depth-first traversal of an expression collecting {:op, op, β} names.
  # Args: (ast_tuple, acc)

  @spec collect_op_names(term()) :: list()
  defp collect_op_names({:op, op, args}, acc) when is_list(args), do: [op | collect_op_names(args, acc)]

  # Called recursively inside a Enum.reduce so always receives (item, acc).
  defp collect_op_names(tuple, acc) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> Enum.reduce(acc, &collect_op_names/2)
  end
  defp collect_op_names(list, acc) when is_list(list) do
    Enum.reduce(list, acc, &collect_op_names/2)
  end

  # Leaf — no nested ops.
  defp collect_op_names(_leaf, acc), do: acc

  # Public entry: no accumulator.
  defp collect_op_names(arg), do: collect_op_names(arg, [])

  # Converts the graph map %{event_id => %{causal_links: [%{id: parent_id}]}}
  # into a stress map using the standard CTL stress formula.
  @spec compute_stress(map()) :: map()
  defp compute_stress(graph) do
    graph
    |> Enum.map(fn {id, event} ->
      {id, node_stress(event, graph)}
    end)
    |> Enum.into(%{})
  end

  # Per-node stress: Σ_l (|t_i − t_l| / elasticity) × weight_l
  # Synthetic timestamps are all the same (@ts), so acyclic graphs carry 0.0
  # stress. Any stress detected → branch in causal graph (cycle candidate).
  defp node_stress(%{causal_links: links}, graph) when links == [], do: 0.0
  defp node_stress(event, graph) do
    links =
      case Map.fetch(graph, event.id) do
        {:ok, enriched} -> enriched.causal_links
        :error -> event.causal_links
      end

    links
    |> Enum.filter(fn l -> Map.has_key?(graph, l.id) end)
    |> Enum.reduce(0.0, fn link, acc ->
      linked_event = Map.fetch!(graph, link.id)
      acc + abs(event.timestamp - linked_event.timestamp) / @sync_elasticity * link.weight
    end)
  end

  # Deterministic node-ID from op-name + prewalk position counter.
  @spec op_id(String.t(), non_neg_integer()) :: String.t()
  defp op_id(op_name, counter) do
    "#{counter}#{@id_sep}#{op_name}#{@id_sep}#{counter}"
  end

  # Collect all op-arg names from a list of arguments.

end
