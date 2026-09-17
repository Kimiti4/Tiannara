defmodule Tiannara.Meta.CausalDataLayer do
  @moduledoc """
  Phase 5F — In-Memory DCG Data Layer (Mnesia Topology Engine)

  Tracks Causal Tensegrity Nodes (CTNs) and their elastic linkages using a
  hybrid Mnesia + Atomics data store. Enables:

    - O(log n) ordered_set lookup for node registry
    - Bag-typed edge table for multi-directional elastic strings
    - Transactional atomic graph mutation
    - Percolation detection when tension variance < 0.25

  Tables:
    :ctn_registry — ordered_set  — {id, forward_origin, backward_origin, tension, frequency, status}
    :ctn_edges    — bag          — {from_node, to_node, elasticity_modulus, sync_phase, updated_at}
  """

  use GenServer
  require Logger

  @registry_table :ctn_registry
  @edges_table    :ctn_edges

  # --------------------------------------------------------------------------
  # Public API
  # --------------------------------------------------------------------------

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Register a newly formed Causal Tensegrity Node."
  def register_knot(id, forward_origin, backward_origin, tension, frequency) do
    GenServer.call(__MODULE__, {:register_knot, id, forward_origin, backward_origin, tension, frequency})
  end

  @doc "Establish an elastic tensegrity thread between two distinct paradox nodes."
  def link_knots(from_id, to_id, elasticity, phase) do
    GenServer.call(__MODULE__, {:link_knots, from_id, to_id, elasticity, phase})
  end

  @doc "Trace a node's causal edge path to find macro-cycle loops."
  def find_macro_cycle(start_node_id) do
    GenServer.call(__MODULE__, {:find_macro_cycle, start_node_id})
  end

  @doc "List all registered CTN node IDs."
  def list_nodes do
    :mnesia.dirty_all_keys(@registry_table)
  end

  @doc "Read a single CTN record."
  def read_node(id) do
    case :mnesia.dirty_read(@registry_table, id) do
      [] -> {:error, :not_found}
      [record | _] -> {:ok, record_to_map(record)}
    end
  end

  @doc "Read all edges from a node."
  def read_edges(from_id) do
    :mnesia.dirty_read(@edges_table, from_id)
    |> Enum.map(&edge_to_map/1)
  end

  # --------------------------------------------------------------------------
  # GenServer Callbacks
  # --------------------------------------------------------------------------

  @impl true
  def init(_opts) do
    init_mnesia_topology()
    {:ok, %{network_elasticity_counter: :atomics.new(1, [{:signed, false}])}}
  end

  @impl true
  def handle_call({:register_knot, id, forward_origin, backward_origin, tension, frequency}, _from, state) do
    transaction = fn ->
      :mnesia.write({@registry_table, id, forward_origin, backward_origin, tension, frequency, :isolated})
    end

    result = case :mnesia.transaction(transaction) do
      {:atomic, :ok} ->
        evaluate_percolation(id, tension, frequency)
        :ok

      {:aborted, reason} ->
        Logger.error("[CausalDataLayer] Failed to inject knot #{id}: #{inspect(reason)}")
        {:error, reason}
    end

    {:reply, result, state}
  end

  @impl true
  def handle_call({:link_knots, from_id, to_id, elasticity, phase}, _from, state) do
    transaction = fn ->
      case :mnesia.read(@registry_table, from_id) do
        [] -> :mnesia.abort(:source_not_found)
        _ ->
          case :mnesia.read(@registry_table, to_id) do
            [] -> :mnesia.abort(:target_not_found)
            _ ->
              :mnesia.write({@edges_table, from_id, to_id, elasticity, phase, System.system_time(:millisecond)})
              update_node_status(from_id, :networked)
              update_node_status(to_id, :networked)
          end
      end
    end

    result = case :mnesia.transaction(transaction) do
      {:atomic, :ok} ->
        :ok

      {:aborted, reason} ->
        Logger.warning("[CausalDataLayer] Failed to link #{from_id}→#{to_id}: #{inspect(reason)}")
        {:error, reason}
    end

    {:reply, result, state}
  end

  @impl true
  def handle_call({:find_macro_cycle, start_node_id}, _from, state) do
    visited = MapSet.new([start_node_id])
    result = trace_path(start_node_id, start_node_id, visited, [])
    {:reply, result, state}
  end

  # --------------------------------------------------------------------------
  # Mnesia Init
  # --------------------------------------------------------------------------

  defp init_mnesia_topology do
    :mnesia.stop()
    :mnesia.create_schema([node()])
    :mnesia.start()

    # Node registry: ordered_set for O(log n) lookup
    :mnesia.create_table(@registry_table, [
      {:attributes, [:id, :forward_origin, :backward_origin, :tension, :frequency, :status]},
      {:type, :ordered_set},
      {:ram_copies, [node()]}
    ])

    # Edge store: bag allows multiple directed edges per source node
    :mnesia.create_table(@edges_table, [
      {:attributes, [:from_node, :to_node, :elasticity_modulus, :sync_phase, :updated_at]},
      {:type, :bag},
      {:ram_copies, [node()]}
    ])

    Logger.info("🌌 [CausalDataLayer] Mnesia CTN topology tables initialized (Phase 5F)")
  end

  # --------------------------------------------------------------------------
  # Percolation Detection
  # --------------------------------------------------------------------------

  defp evaluate_percolation(new_id, tension, frequency) do
    all_keys = :mnesia.dirty_all_keys(@registry_table)

    Enum.each(all_keys, fn existing_id ->
      if existing_id != new_id do
        case :mnesia.dirty_read(@registry_table, existing_id) do
          [{_, _, _, _, ext_tension, _, _}] ->
            # Percolation trigger: tension variance < 0.25
            if abs(ext_tension - tension) < 0.25 do
              # Link the percolating pair
              GenServer.cast(self(), {:auto_link, new_id, existing_id, 0.85, 0.0})

              # Publish network linkage event down NATS
              publish_percolation(new_id, existing_id, tension, ext_tension)
            end

          _ -> :ok
        end
      end
    end)
  end

  # Internal auto-link without going through call to avoid deadlock in handle_call
  @impl true
  def handle_cast({:auto_link, from_id, to_id, elasticity, phase}, state) do
    transaction = fn ->
      case :mnesia.read(@registry_table, from_id) do
        [] -> :ok
        _ ->
          case :mnesia.read(@registry_table, to_id) do
            [] -> :ok
            _ ->
              :mnesia.write({@edges_table, from_id, to_id, elasticity, phase, System.system_time(:millisecond)})
              update_node_status(from_id, :networked)
              update_node_status(to_id, :networked)
          end
      end
    end

    :mnesia.transaction(transaction)
    {:noreply, state}
  end

  defp publish_percolation(new_id, existing_id, t1, t2) do
    payload = %{
      nodes: [new_id, existing_id],
      net_tension: t1 + t2,
      oscillation_sync: true
    }

    try do
      Tiannara.NATS.MetaEvolutionStreamManager.publish(
        "tiannara.meta.causal.tensegrity.network",
        payload
      )
    rescue
      e -> Logger.warning("[CausalDataLayer] NATS publish failed: #{inspect(e)}")
    end
  end

  # --------------------------------------------------------------------------
  # Traversal (Cycle Extractor)
  # --------------------------------------------------------------------------

  defp trace_path(current_id, target_id, visited, path_acc) do
    edges = :mnesia.dirty_read(@edges_table, current_id)

    Enum.reduce_while(edges, {:error, :no_cycle}, fn edge, acc ->
      to_node = elem(edge, 2)
      tension = elem(edge, 3)

      cond do
        to_node == target_id ->
          {:halt, {:ok, Enum.reverse([current_id | path_acc]), tension}}

        MapSet.member?(visited, to_node) ->
          {:cont, acc}

        true ->
          new_visited = MapSet.put(visited, to_node)
          case trace_path(to_node, target_id, new_visited, [current_id | path_acc]) do
            {:ok, full_path, cycle_tension} -> {:halt, {:ok, full_path, cycle_tension}}
            _ -> {:cont, acc}
          end
      end
    end)
  end

  # --------------------------------------------------------------------------
  # Internal Helpers
  # --------------------------------------------------------------------------

  defp update_node_status(node_id, new_status) do
    case :mnesia.read(@registry_table, node_id) do
      [record] ->
        updated = put_elem(record, 6, new_status)
        :mnesia.write(updated)
      _ -> :ok
    end
  end

  defp record_to_map({_, id, fwd, bwd, tension, freq, status}) do
    %{id: id, forward_origin: fwd, backward_origin: bwd,
      tension: tension, frequency: freq, status: status}
  end

  defp edge_to_map({_, from, to, elasticity, phase, updated_at}) do
    %{from_node: from, to_node: to, elasticity_modulus: elasticity,
      sync_phase: phase, updated_at: updated_at}
  end
end

# --------------------------------------------------------------------------
# Pipeline Consumer — routes NATS loop_bound events into the data layer
# --------------------------------------------------------------------------

defmodule Tiannara.Meta.CausalPipelineConsumer do
  @moduledoc """
  Consumes NATS events on `tiannara.meta.causal.tensegrity.bound` and
  ingests them into the CausalDataLayer Mnesia topology engine.
  """
  use GenServer
  require Logger

  alias Tiannara.Meta.CausalDataLayer

  @default_tension 0.73
  @default_freq    4.2

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    try do
      Gnat.sub(:tiannara_nats, self(), "tiannara.meta.causal.tensegrity.bound")
    catch
      _, _ -> Logger.warning("[CausalPipelineConsumer] NATS sub failed (process probably not running)")
    end

    {:ok, nil}
  end

  @impl true
  def handle_info({:msg, %{body: body}}, state) do
    case Jason.decode(body) do
      {:ok, %{"mode" => "loop_bound", "region" => r_id, "forward_anchor" => f, "backward_anchor" => b}} ->
        case CausalDataLayer.register_knot(r_id, f, b, @default_tension, @default_freq) do
          :ok ->
            Logger.debug("[CausalPipelineConsumer] Registered CTN knot #{r_id}")
          {:error, reason} ->
            Logger.error("[CausalPipelineConsumer] Failed to register knot #{r_id}: #{inspect(reason)}")
        end

      {:ok, _other} ->
        :ok

      {:error, reason} ->
        Logger.warning("[CausalPipelineConsumer] Failed to decode NATS body: #{inspect(reason)}")
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}
end
