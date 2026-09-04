defmodule Tiannara.Executive.State do
  @moduledoc """
  State struct and management helpers for Executive Memory.
  """
  defstruct [
    :name,
    :dets_ref,
    :ets_table,
    :dets_file,
    :dets_dir,
    :snapshot_dir,
    :backup_path,
    status: :initializing,
    metrics: Tiannara.Executive.Types.default_metrics(),
    fault_injection: Tiannara.Executive.Types.default_fault_injection(),
    flush_interval: 300_000,
    checkpoint_interval: 1_800_000,
    maintenance_interval: 900_000,
    gc_interval: 21_600_000,
    flush_ref: nil,
    maintenance_ref: nil,
    gc_ref: nil,
    last_flush: nil,
    last_checkpoint: nil,
    last_maintenance: nil,
    last_gc: nil,
    corruption_detected: false
  ]

  @type t :: %__MODULE__{
    name: atom(),
    dets_ref: term() | nil,
    ets_table: :ets.tid() | nil,
    dets_file: String.t() | nil,
    dets_dir: String.t() | nil,
    snapshot_dir: String.t() | nil,
    backup_path: String.t() | nil,
    status: :initializing | :active | :degraded | :recovering | :corrupt,
    metrics: Tiannara.Executive.Types.metrics(),
    fault_injection: Tiannara.Executive.Types.fault_injection(),
    flush_interval: pos_integer(),
    checkpoint_interval: pos_integer(),
    maintenance_interval: pos_integer(),
    gc_interval: pos_integer(),
    flush_ref: reference() | nil,
    maintenance_ref: reference() | nil,
    gc_ref: reference() | nil,
    last_flush: DateTime.t() | nil,
    last_checkpoint: DateTime.t() | nil,
    last_maintenance: DateTime.t() | nil,
    last_gc: DateTime.t() | nil,
    corruption_detected: boolean()
  }

  def new(attrs \\ []) do
    struct!(__MODULE__, attrs)
  end

  def validate(%__MODULE__{dets_file: file, dets_dir: dir} = s)
      when is_binary(file) and is_binary(dir), do: s
  def validate(s), do: s

  def degrade(%__MODULE__{} = s, reason) do
    s = %{s | status: :degraded}
    Tiannara.Executive.Telemetry.emit([:tiannara, :executive], :degraded, %{reason: reason})
    s
  end

  def activate(%__MODULE__{} = s) do
    %{s | status: :active}
  end

  def increment_metric(%__MODULE__{metrics: m} = s, key) do
    %{s | metrics: Map.update!(m, key, &(&1 + 1))}
  end

  def record_recovery(%__MODULE__{metrics: m} = s) do
    %{s | metrics: %{m | total_recoveries: m.total_recoveries + 1}}
  end

  def record_corruption(%__MODULE__{metrics: m} = s) do
    %{s |
      metrics: %{m | corruption_count: m.corruption_count + 1, last_corruption: DateTime.utc_now()},
      corruption_detected: true}
  end

  def enable_fault_injection(%__MODULE__{} = s, config) do
    %{s | fault_injection: Map.merge(s.fault_injection, config)}
  end

  def disable_fault_injection(%__MODULE__{} = s) do
    %{s | fault_injection: %{enabled: false}}
  end
end
