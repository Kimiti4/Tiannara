defmodule Tiannara.Lineage.Entry do
  @moduledoc """
  A single entry in the durable lineage chain. Each entry is cryptographically
  chained to its parent via `parent_hash`, and its own `entry_hash` commits to
  its content + parent. This makes the lineage tamper-evident and
  reconstructable after restart.

  Constitutional basis: "Every architectural decision should remain traceable",
  "Maintain audit trails", "Support reproducibility."
  """

  @enforce_keys [:entry_id, :payload, :timestamp]
  defstruct [:entry_id, :parent_hash, :entry_hash, :payload, :timestamp, :lineage_type]

  @type t :: %__MODULE__{}

  @genesis_hash String.duplicate("0", 64)

  def genesis_hash, do: @genesis_hash

  @doc """
  Create a new lineage entry chained to a parent hash. The entry_hash commits
  to the entry_id, parent_hash, payload, timestamp, and lineage_type.
  """
  def new(payload, lineage_type, parent_hash \\ @genesis_hash) do
    entry_id = make_id()
    timestamp = System.system_time(:second)

    entry_hash = compute_hash(entry_id, parent_hash, payload, timestamp, lineage_type)

    %__MODULE__{
      entry_id: entry_id,
      parent_hash: parent_hash,
      entry_hash: entry_hash,
      payload: payload,
      timestamp: timestamp,
      lineage_type: lineage_type
    }
  end

  @doc "Recompute an entry's hash to verify integrity."
  def verify(%__MODULE__{} = entry) do
    expected = compute_hash(entry.entry_id, entry.parent_hash, entry.payload,
                            entry.timestamp, entry.lineage_type)
    expected == entry.entry_hash
  end

  defp compute_hash(entry_id, parent_hash, payload, timestamp, lineage_type) do
    data = {entry_id, parent_hash, payload, timestamp, lineage_type}

    data
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp make_id, do: :"line-#{System.unique_integer([:monotonic])}"
end