defmodule Tiannara.Meta.OPC.Telemetry.OPCMetrics do
  @moduledoc """
  Phase 5F.6 — OPC Metrics

  Lightweight telemetry helpers for the Observer Physics Compiler.
  Computes derived metrics from raw counters collected by the
  ExecutionAuditor and EntropyMonitor.

  ## Usage

      rate = OPCMetrics.execution_rate(1200, 60)   # => 20.0 executions/sec
      util = OPCMetrics.cache_utilisation(750, 1000) # => 75.0 %
  """

  @doc """
  Computes executions per second.

  ## Parameters
  - `executions`: Total execution count
  - `seconds`: Elapsed time window in seconds

  ## Returns
  - Float executions/second (never negative; returns 0.0 for zero window)
  """
  def execution_rate(executions, seconds) when is_number(executions) and is_number(seconds) do
    executions / max(seconds, 1)
  end

  @doc """
  Computes cache utilisation as a percentage.

  ## Parameters
  - `used`: Number of occupied cache slots
  - `capacity`: Total cache capacity

  ## Returns
  - Float percentage in [0.0, 100.0]
  """
  def cache_utilisation(used, capacity) when capacity > 0 do
    (used / capacity) * 100.0
  end

  def cache_utilisation(_used, 0), do: 0.0

  @doc """
  Computes cache hit rate as a percentage.

  ## Parameters
  - `hits`: Number of cache hits
  - `total_requests`: Total lookup requests

  ## Returns
  - Float percentage in [0.0, 100.0]
  """
  def hit_rate(hits, total_requests) when total_requests > 0 do
    (hits / total_requests) * 100.0
  end

  def hit_rate(_hits, 0), do: 0.0

  @doc """
  Computes average entropy across a list of entropy samples.

  ## Parameters
  - `samples`: List of entropy floats

  ## Returns
  - Average entropy float, or 0.0 for empty list
  """
  def average_entropy([]), do: 0.0

  def average_entropy(samples) when is_list(samples) do
    Enum.sum(samples) / length(samples)
  end

  @doc """
  Formats a metric map for structured logging.

  ## Parameters
  - `metrics`: Map of metric name → value

  ## Returns
  - Formatted string
  """
  def format(metrics) when is_map(metrics) do
    metrics
    |> Enum.map_join(", ", fn {k, v} -> "#{k}=#{v}" end)
  end
end
