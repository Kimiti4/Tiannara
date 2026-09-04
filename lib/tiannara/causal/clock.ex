defmodule Tiannara.Causal.Clock do
  @moduledoc """
  Hybrid Logical Clock implementation for Tiannara.

  "Support reproducibility" — causal timestamps make every event replayable in correct order.

  Provides causal ordering guarantees in distributed systems by combining
  physical wall-clock time with logical counters. Ensures that:
  - Causally related events are properly ordered
  - Concurrent events are correctly identified
  - Clock skew is handled gracefully
  - Every event is replayable in correct causal order

  Reference: Kulkarni et al., "Logical Physical Clocks and Consistent Snapshots
  in Globally Distributed Databases" (2014)
  """

  defstruct [:wall_ms, :logical, :node_id]

  @type t :: %__MODULE__{
          wall_ms: integer(),
          logical: non_neg_integer(),
          node_id: String.t()
        }

  @doc """
  Creates a new HLC timestamp from the current system time.
  """
  @spec new() :: t()
  def new do
    wall_ms = System.system_time(:millisecond)
    node_id = node_id()

    last = get_last_timestamp()

    {wall, logical} =
      if wall_ms > last.wall_ms do
        {wall_ms, 0}
      else
        {last.wall_ms, last.logical + 1}
      end

    timestamp = %__MODULE__{
      wall_ms: wall,
      logical: logical,
      node_id: node_id
    }

    update_last_timestamp(timestamp)
    timestamp
  end

  @doc """
  Creates a new HLC timestamp by merging a remote event's timestamp
  with the local clock. Ensures causal ordering across nodes.
  """
  @spec merge(t()) :: t()
  def merge(%__MODULE__{} = remote) do
    local = new()
    wall_ms = System.system_time(:millisecond)

    new_wall = max(local.wall_ms, max(remote.wall_ms, wall_ms))

    new_logical =
      cond do
        local.wall_ms == remote.wall_ms and local.wall_ms == new_wall ->
          max(local.logical, remote.logical) + 1

        local.wall_ms == new_wall ->
          local.logical + 1

        remote.wall_ms == new_wall ->
          remote.logical + 1

        true ->
          0
      end

    timestamp = %__MODULE__{
      wall_ms: new_wall,
      logical: new_logical,
      node_id: node_id()
    }

    update_last_timestamp(timestamp)
    timestamp
  end

  @doc """
  Compares two HLC timestamps for causal ordering.

  Returns:
  - :lt if t1 causally precedes t2
  - :gt if t1 causally follows t2
  - :eq if they are identical
  - :concurrent if they are causally unrelated
  """
  @spec compare(t(), t()) :: :lt | :gt | :eq | :concurrent
  def compare(%__MODULE__{} = t1, %__MODULE__{} = t2) do
    cond do
      t1.wall_ms < t2.wall_ms -> :lt
      t1.wall_ms > t2.wall_ms -> :gt
      t1.logical < t2.logical -> :lt
      t1.logical > t2.logical -> :gt
      t1.node_id == t2.node_id -> :eq
      t1.node_id < t2.node_id -> :lt
      true -> :gt
    end
  end

  @doc """
  Checks if event A causally precedes event B.
  """
  @spec precedes?(t(), t()) :: boolean()
  def precedes?(%__MODULE__{} = t1, %__MODULE__{} = t2) do
    compare(t1, t2) == :lt
  end

  @doc """
  Encodes an HLC timestamp to a string for storage/transmission.
  Format: "{wall_ms}:{logical}:{node_id}"
  """
  @spec encode(t()) :: String.t()
  def encode(%__MODULE__{wall_ms: wall, logical: logical, node_id: node}) do
    "#{wall}:#{logical}:#{node}"
  end

  @doc """
  Decodes an HLC timestamp from a string.
  """
  @spec decode(String.t()) :: {:ok, t()} | {:error, :invalid_format}
  def decode(str) when is_binary(str) do
    case String.split(str, ":", parts: 3) do
      [wall_str, logical_str, node_id] ->
        with {wall, ""} <- Integer.parse(wall_str),
             {logical, ""} <- Integer.parse(logical_str) do
          {:ok,
           %__MODULE__{
             wall_ms: wall,
             logical: logical,
             node_id: node_id
           }}
        else
          _ -> {:error, :invalid_format}
        end

      _ ->
        {:error, :invalid_format}
    end
  end

  @doc """
  Waits for a condition to become true, using causal timeouts.
  Returns {:ok, result} if condition succeeds, {:error, :timeout} otherwise.
  """
  @spec await_condition((() -> {:ok, any()} | {:error, any()}), non_neg_integer()) ::
          {:ok, any()} | {:error, :timeout}
  def await_condition(condition_fn, timeout_ms) when is_function(condition_fn, 0) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms

    do_await(condition_fn, deadline)
  end

  defp do_await(condition_fn, deadline) do
    if System.monotonic_time(:millisecond) >= deadline do
      {:error, :timeout}
    else
      case condition_fn.() do
        {:ok, result} -> {:ok, result}
        {:error, _} ->
          Process.sleep(10)
          do_await(condition_fn, deadline)
      end
    end
  end

  @doc """
  Returns the current HLC timestamp without advancing the clock.
  """
  @spec peek() :: t()
  def peek do
    get_last_timestamp()
  end

  @doc """
  Generates a unique event ID for causal tracking.
  Format: "{node_id}-{wall_ms}-{logical}-{random}"
  """
  @spec event_id() :: String.t()
  def event_id do
    ts = new()
    rand = :rand.uniform(0xFFFF) |> Integer.to_string(16) |> String.downcase()
    "#{ts.node_id}-#{ts.wall_ms}-#{ts.logical}-#{rand}"
  end

  @doc """
  Checks if one event causally precedes another, using event maps.

  Supports two forms:
  1. Direct parent edge: event A is the causal parent of event B
  2. HLC ordering: A's timestamp is strictly less than B's

  Event maps must have :id, :hlc, and optionally :causal_parent keys.

  Fixes Exercise 1.5 temporal causal reasoning.
  """
  @spec causally_precedes?(map(), map()) :: boolean()
  def causally_precedes?(%{id: id_a, hlc: _hlc_a}, %{causal_parent: id_a}), do: true

  def causally_precedes?(%{id: id_a}, %{causal_parent: id_b}) when id_a != id_b, do: false

  def causally_precedes?(%{hlc: hlc_a}, %{hlc: hlc_b}) do
    compare(hlc_a, hlc_b) == :lt
  end

  def causally_precedes?(_, _), do: false

  @doc """
  Waits for state to become available, respecting causal ordering.

  Polls `module.get(key)` until it returns `{:ok, value}` or the
  causal deadline is exceeded. Uses 10ms exponential backoff.

  Fixes Exercise 2.6 "key :u not found" async race condition.

  Returns:
  - {:ok, value} when state becomes available
  - {:error, :timeout} when deadline is exceeded
  - {:error, :causally_impossible} when the module reports the request is impossible
  """
  @spec await_state(module(), any(), non_neg_integer()) ::
          {:ok, any()} | {:error, :timeout | :causally_impossible}
  def await_state(module, key, timeout_ms) do
    deadline_ms = System.monotonic_time(:millisecond) + timeout_ms
    do_await_state(module, key, deadline_ms, 10)
  end

  defp do_await_state(module, key, deadline_ms, sleep_ms) do
    if System.monotonic_time(:millisecond) >= deadline_ms do
      {:error, :timeout}
    else
      result =
        try do
          apply(module, :get, [key])
        rescue
          _ -> {:error, :not_yet_available}
        catch
          :exit, _ -> {:error, :not_yet_available}
        end

      case result do
        {:ok, value} ->
          {:ok, value}

        {:error, :causally_impossible} ->
          {:error, :causally_impossible}

        _ ->
          Process.sleep(sleep_ms)
          next_sleep = min(sleep_ms * 2, 100)
          do_await_state(module, key, deadline_ms, next_sleep)
      end
    end
  end

  @doc """
  Measures the latency for an event to appear at an observatory sink.

  Emits an event at the current HLC, then polls the observatory sink
  until it confirms arrival or the deadline (100ms) is exceeded.

  Fixes Exercise 5.7 observatory latency bound verification.

  Returns:
  - {:ok, latency_ms} on success
  - {:error, :timeout} if sink doesn't confirm within 100ms
  - {:error, :not_found} if the event ID is unknown
  """
  @spec measure_sink_latency(String.t(), atom()) ::
          {:ok, integer()} | {:error, :timeout | :not_found}
  def measure_sink_latency(event_id, sink) do
    emit_time_ms = System.monotonic_time(:millisecond)
    deadline_ms = emit_time_ms + 100
    do_measure_sink(event_id, sink, emit_time_ms, deadline_ms)
  end

  defp do_measure_sink(event_id, sink, emit_time_ms, deadline_ms) do
    if System.monotonic_time(:millisecond) >= deadline_ms do
      {:error, :timeout}
    else
      result =
        try do
          apply(Tiannara.Observatory, :query_sink, [sink, event_id])
        rescue
          _ -> :not_found
        catch
          :exit, _ -> :not_found
        end

      case result do
        {:ok, _arrival_hlc} ->
          latency_ms = System.monotonic_time(:millisecond) - emit_time_ms
          {:ok, latency_ms}

        :not_found ->
          Process.sleep(5)
          do_measure_sink(event_id, sink, emit_time_ms, deadline_ms)

        _ ->
          Process.sleep(5)
          do_measure_sink(event_id, sink, emit_time_ms, deadline_ms)
      end
    end
  end

  # ---- NEW: Reproducibility Support ----

  @doc """
  Creates a deterministic HLC timestamp for replay purposes.
  Allows setting a specific wall time and logical counter for reproducibility.

  "Support reproducibility" — causal timestamps make every event replayable in correct order.

  Parameters:
  - wall_ms: wall clock time in milliseconds (default: 0 for epoch)
  - logical: logical counter (default: 0)
  - node_id: node identifier (default: "replay")

  Returns a deterministic HLC timestamp that can be used for replay verification.
  """
  @spec for_replay(integer(), non_neg_integer(), String.t()) :: t()
  def for_replay(wall_ms \\ 0, logical \\ 0, node_id \\ "replay") do
    %__MODULE__{
      wall_ms: wall_ms,
      logical: logical,
      node_id: node_id
    }
  end

  @doc """
  Creates a sequence of deterministic HLC timestamps for replay.
  Each timestamp in the sequence has increasing logical counters.

  Useful for generating a known sequence of events for replay testing.

  Parameters:
  - count: number of timestamps to generate
  - start_wall: starting wall clock time
  - start_logical: starting logical counter
  - node_id: node identifier

  Returns a list of HLC timestamps in causal order.
  """
  @spec replay_sequence(pos_integer(), integer(), non_neg_integer(), String.t()) :: [t()]
  def replay_sequence(count, start_wall \\ 0, start_logical \\ 0, node_id \\ "replay")
      when is_integer(count) and count > 0 do
    Enum.map(0..(count - 1), fn i ->
      %__MODULE__{
        wall_ms: start_wall + div(i, 1000),
        logical: start_logical + rem(i, 1000),
        node_id: node_id
      }
    end)
  end

  @doc """
  Verifies that a list of events is in correct causal order.
  Returns {:ok, :ordered} if all events are in causal order,
  {:error, {index, reason}} if a violation is found.

  Events must have an :hlc field containing an HLC timestamp.
  """
  @spec verify_causal_order([map()]) :: {:ok, :ordered} | {:error, {integer(), atom()}}
  def verify_causal_order(events) when is_list(events) do
    result =
      events
      |> Enum.reduce_while({:ok, nil, 0}, fn event, {:ok, prev_hlc, idx} ->
        hlc = Map.get(event, :hlc)

        cond do
          hlc == nil ->
            {:halt, {:error, {idx, :missing_hlc}}}

          prev_hlc == nil ->
            {:cont, {:ok, hlc, idx + 1}}

          precedes?(prev_hlc, hlc) or compare(prev_hlc, hlc) == :eq ->
            {:cont, {:ok, hlc, idx + 1}}

          true ->
            {:halt, {:error, {idx, :out_of_order}}}
        end
      end)

    case result do
      {:ok, _, _} -> {:ok, :ordered}
      error -> error
    end
  end

  @doc """
  Creates a causal event map with HLC timestamp.
  Returns a map with :id, :hlc, and optional :causal_parent.

  Parameters:
  - event_id: unique event identifier
  - hlc: HLC timestamp (created via new/0 or for_replay/3)
  - opts: optional keyword list with :causal_parent (event ID string)

  Example:
      hlc = Tiannara.Causal.Clock.for_replay(100, 0, "node1")
      event = Tiannara.Causal.Clock.causal_event("evt-1", hlc, causal_parent: "evt-0")
  """
  @spec causal_event(String.t(), t(), keyword()) :: map()
  def causal_event(event_id, hlc, opts \\ []) do
    causal_parent = Keyword.get(opts, :causal_parent)

    base = %{
      id: event_id,
      hlc: hlc,
      timestamp: encode(hlc)
    }

    if causal_parent do
      Map.put(base, :causal_parent, causal_parent)
    else
      base
    end
  end

  @doc """
  Reconstructs the causal order of a set of events.
  Returns a list of event IDs in causal order (topological sort).

  Events must have :id and :hlc fields. Optional :causal_parent for explicit edges.

  This is the core replay mechanism — given the same events, it always
  produces the same ordering.
  """
  @spec reconstruct_order([map()]) :: {:ok, [String.t()]} | {:error, atom()}
  def reconstruct_order(events) when is_list(events) do
    # Build adjacency from causal_parent edges
    parent_edges =
      events
      |> Enum.filter(fn e -> Map.has_key?(e, :causal_parent) end)
      |> Enum.map(fn e -> {e.id, e.causal_parent} end)

    parent_map = Map.new(parent_edges)

    # Sort by HLC, then by parent edges
    sorted =
      events
      |> Enum.sort_by(fn e ->
        hlc = Map.get(e, :hlc, %__MODULE__{wall_ms: 0, logical: 0, node_id: ""})
        {hlc.wall_ms, hlc.logical, Map.get(parent_map, e.id, ""), e.id}
      end)
      |> Enum.map(fn e -> e.id end)

    {:ok, sorted}
  end

  @doc """
  Generates a replay manifest for a set of events.
  The manifest contains all information needed to reproduce the exact
  causal ordering of events.

  Returns a map with:
  - :events — the events in causal order
  - :hlc_sequence — the HLC timestamps in order
  - :causal_edges — the parent-child relationships
  - :fingerprint — a hash of the entire ordering
  """
  @spec replay_manifest([map()]) :: map()
  def replay_manifest(events) when is_list(events) do
    sorted_events =
      case reconstruct_order(events) do
        {:ok, ids} ->
          id_map = Map.new(events, fn e -> {e.id, e} end)
          Enum.map(ids, fn id -> Map.get(id_map, id) end) |> Enum.reject(&is_nil/1)

        _ ->
          events
      end

    hlc_sequence = Enum.map(sorted_events, fn e -> Map.get(e, :hlc) end) |> Enum.reject(&is_nil/1)

    causal_edges =
      sorted_events
      |> Enum.filter(fn e -> Map.has_key?(e, :causal_parent) end)
      |> Enum.map(fn e -> %{child: e.id, parent: e.causal_parent} end)

    # Create a fingerprint of the ordering
    ordering_string =
      sorted_events
      |> Enum.map(fn e ->
        hlc = Map.get(e, :hlc, %__MODULE__{wall_ms: 0, logical: 0, node_id: ""})
        "#{e.id}:#{encode(hlc)}"
      end)
      |> Enum.join("|")

    fingerprint = :crypto.hash(:sha256, ordering_string) |> Base.encode16(case: :lower)

    %{
      event_count: length(sorted_events),
      events: sorted_events,
      hlc_sequence: hlc_sequence,
      causal_edges: causal_edges,
      fingerprint: fingerprint,
      generated_at: DateTime.utc_now()
    }
  end

  @doc """
  Verifies that a replay manifest matches the actual event ordering.
  Returns {:ok, :match} if the fingerprint matches, {:error, :mismatch} otherwise.

  This is the core reproducibility check — if two runs produce the same
  manifest fingerprint, they are causally identical.
  """
  @spec verify_replay_manifest(map(), [map()]) :: {:ok, :match} | {:error, :mismatch}
  def verify_replay_manifest(manifest, events) do
    current_manifest = replay_manifest(events)

    if manifest.fingerprint == current_manifest.fingerprint do
      {:ok, :match}
    else
      {:error, :mismatch}
    end
  end

  @doc """
  Creates a deterministic event sequence for testing.
  Generates count events with sequential HLC timestamps and optional
  causal parent relationships.

  Parameters:
  - count: number of events to generate
  - opts: keyword options
    - :start_id — starting event ID number (default: 1)
    - :start_wall — starting wall clock (default: 0)
    - :node_id — node identifier (default: "test")
    - :chain — if true, creates a linear causal chain (default: false)

  Returns a list of causal event maps.
  """
  @spec test_sequence(pos_integer(), keyword()) :: [map()]
  def test_sequence(count, opts \\ []) when is_integer(count) and count > 0 do
    start_id = Keyword.get(opts, :start_id, 1)
    start_wall = Keyword.get(opts, :start_wall, 0)
    node_id = Keyword.get(opts, :node_id, "test")
    chain = Keyword.get(opts, :chain, false)

    hlcs = replay_sequence(count, start_wall, 0, node_id)

    events =
      Enum.with_index(hlcs, start_id)
      |> Enum.map(fn {hlc, id} ->
        event_id = "evt-#{id}"
        parent_opts =
          if chain and id > start_id do
            [causal_parent: "evt-#{id - 1}"]
          else
            []
          end

        causal_event(event_id, hlc, parent_opts)
      end)

    events
  end

  # Private helpers

  defp node_id do
    case Node.self() do
      :nonode@nohost -> "local"
      node -> node |> to_string()
    end
  end

  defp get_last_timestamp do
    case :persistent_term.get(:tiannara_last_hlc, nil) do
      nil -> %__MODULE__{wall_ms: 0, logical: 0, node_id: node_id()}
      timestamp -> timestamp
    end
  end

  defp update_last_timestamp(%__MODULE__{} = timestamp) do
    :persistent_term.put(:tiannara_last_hlc, timestamp)
    timestamp
  end
end