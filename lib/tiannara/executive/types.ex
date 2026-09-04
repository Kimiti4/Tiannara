defmodule Tiannara.Executive.Types do
  @moduledoc """
  Canonical types and helpers for the Executive Memory subsystem.
  """

  @type memory_id :: String.t()
  @type memory_key :: String.t()
  @type memory_value :: term()
  @type memory_class :: :archaeological | :constitutional | :scientific | :operational
  @type evidence_level :: float()
  @type consensus_mode :: :simple | :majority | :constitutional | :emergency
  @type fault_type :: :read_delay | :write_failure | :corruption_sim

  @type fault_injection :: %{
    required(:enabled) => boolean(),
    optional(:read_delay_ms) => non_neg_integer(),
    optional(:write_failure_rate) => float(),
    optional(:corruption_sim_rate) => float()
  }

  @type metrics :: %{
    total_writes: non_neg_integer(),
    total_reads: non_neg_integer(),
    total_deletes: non_neg_integer(),
    total_syncs: non_neg_integer(),
    total_recoveries: non_neg_integer(),
    corruption_count: non_neg_integer(),
    checkpoint_count: non_neg_integer(),
    snapshot_count: non_neg_integer(),
    gc_runs: non_neg_integer(),
    total_compactions: non_neg_integer(),
    last_corruption: DateTime.t() | nil
  }

  @valid_classes [:archaeological, :constitutional, :scientific, :operational]
  @evidence_min 0.1

  @doc "Generates a new unique memory ID."
  def new_id, do: UUID.uuid4()

  @doc "Returns default metrics map."
  def default_metrics do
    %{
      total_writes: 0,
      total_reads: 0,
      total_deletes: 0,
      total_syncs: 0,
      total_recoveries: 0,
      corruption_count: 0,
      checkpoint_count: 0,
      snapshot_count: 0,
      gc_runs: 0,
      total_compactions: 0,
      last_corruption: nil
    }
  end

  @doc "Returns default fault injection config."
  def default_fault_injection do
    %{enabled: false}
  end

  @doc "Validates a memory class atom."
  def valid_class?(class), do: class in @valid_classes

  @doc "Returns the list of valid memory classes."
  def valid_classes, do: @valid_classes

  @doc "Minimum evidence threshold for audit."
  def evidence_min, do: @evidence_min
end
