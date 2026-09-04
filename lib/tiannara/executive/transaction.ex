defmodule Tiannara.Executive.Transaction do
  @moduledoc """
  Auditable state transitions for Executive Memory.

  Each transaction records the before/after state, the operation
  performed, and a timestamp for full auditability.
  """

  defstruct [:id, :key, :old_value, :new_value, :operation, :timestamp, :metadata]

  @type operation :: :put | :delete | :migrate | :restore | :gc

  @type t :: %__MODULE__{
    id: String.t(),
    key: term(),
    old_value: term(),
    new_value: term(),
    operation: operation(),
    timestamp: DateTime.t(),
    metadata: map()
  }

  @doc "Creates a new transaction record."
  def begin(key, old_value, new_value, operation, metadata \\ %{}) do
    %__MODULE__{
      id: Tiannara.Executive.Types.new_id(),
      key: key,
      old_value: old_value,
      new_value: new_value,
      operation: operation,
      timestamp: DateTime.utc_now(),
      metadata: metadata
    }
  end

  @doc "Commits a transaction by returning its record."
  def commit(%__MODULE__{} = tx), do: tx

  @doc "Converts a transaction to a storage record."
  def to_record(%__MODULE__{} = tx) do
    {{:tx, tx.id}, tx}
  end

  @doc "Extracts a transaction from a storage record."
  def from_record({_, %__MODULE__{} = tx}), do: tx
end
