defmodule Tiannara.Executive.Telemetry do
  @moduledoc """
  Telemetry emission for the Executive Memory subsystem.
  """

  @prefix [:tiannara, :executive]

  def emit_read(name, result) do
    emit(:read, %{name: name, result: tag(result), timestamp: DateTime.utc_now()})
  end

  def emit_write(name, result) do
    emit(:write, %{name: name, result: tag(result), timestamp: DateTime.utc_now()})
  end

  def emit_delete(name, result) do
    emit(:delete, %{name: name, result: tag(result), timestamp: DateTime.utc_now()})
  end

  def emit_sync(name, result) do
    emit(:sync, %{name: name, result: tag(result), timestamp: DateTime.utc_now()})
  end

  def emit_checkpoint(name) do
    emit(:checkpoint, %{name: name, timestamp: DateTime.utc_now()})
  end

  def emit_snapshot_created do
    emit(:snapshot, %{action: :created, timestamp: DateTime.utc_now()})
  end

  def emit_recovery do
    emit(:recovery, %{timestamp: DateTime.utc_now()})
  end

  def emit_corruption(details) do
    emit(:corruption, Map.put(details, :timestamp, DateTime.utc_now()))
  end

  def emit_startup(status) do
    emit(:startup, %{status: status, timestamp: DateTime.utc_now()})
  end

  def emit_shutdown(reason) do
    emit(:shutdown, %{reason: reason, timestamp: DateTime.utc_now()})
  end

  def emit_compaction(name, result) do
    emit(:compaction, %{name: name, result: result, timestamp: DateTime.utc_now()})
  end

  def emit_gc(name) do
    emit(:gc, %{name: name, timestamp: DateTime.utc_now()})
  end

  def emit_health(status) do
    emit(:health, %{status: status, timestamp: DateTime.utc_now()})
  end

  @doc "Emits a telemetry event using the executive prefix."
  def emit(event_name, metadata) when is_atom(event_name) do
    :telemetry.execute(@prefix ++ [event_name], %{}, metadata)
  end

  @doc "Emits a telemetry event with a custom prefix."
  def emit(custom_prefix, event_name, metadata) when is_list(custom_prefix) and is_atom(event_name) do
    :telemetry.execute(custom_prefix ++ [event_name], %{}, metadata)
  end

  defp tag(:ok), do: :ok
  defp tag(:error), do: :error
  defp tag({:ok, _}), do: :ok
  defp tag({:error, _}), do: :error
  defp tag(other), do: other
end
