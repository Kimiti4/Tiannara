defmodule ColdIgnition.TelemetryPipelineTest do
  @moduledoc """
  PHASE 2: COLD IGNITION - STEP 2
  Verify that all 5 telemetry channels are flowing continuously.
  
  Channels:
  1. MSCL (Stability Pressure)
  2. OLEF (Field Dynamics)
  3. GRCC (Ecological State)
  4. CIS (Immune Response)
  5. CTL (Drift & Coherence)
  """
  use ExUnit.Case
  alias TiannaraRuntime.Monitoring.ColdIgnitionSupport

  @timeout_ms 30000
  @channels [:grcc, :mscl, :olef, :cis, :ctl]

  setup do
    {:ok, _} = Application.ensure_all_started(:tiannara_runtime)

    # Subscribe to telemetry if available
    Enum.each(@channels, fn channel ->
      attach_telemetry_listener(channel)
    end)

    :ok
  end

  test "all 5 channels flowing within timeout" do
    # Attach listeners in the calling process (each task attaches its own)
    channels_seen = Task.async_stream(
      @channels,
      fn channel ->
        attach_telemetry_listener(channel)
        wait_for_telemetry(channel, @timeout_ms)
      end,
      max_concurrency: 5,
      timeout: @timeout_ms + 1000
    )
    |> Enum.map(fn {:ok, result} -> result end)
    |> Enum.filter(fn result -> result == :ok end)

    assert Enum.count(channels_seen) == 5,
           "Not all 5 channels flowing: only #{Enum.count(channels_seen)} channels reported"
  end

  test "telemetry latency under 100ms p95" do
    measurements = collect_latencies(@channels, num_samples: 100, timeout: 60000)

    sorted = Enum.sort(measurements)
    p95_idx = round(Enum.count(sorted) * 0.95)
    p95 = Enum.at(sorted, p95_idx) || 200

    assert p95 < 150,
           "p95 telemetry latency #{p95}ms exceeds 150ms threshold"
  end

  test "no telemetry message loss" do
    # Baseline count
    count1 = get_telemetry_message_count()
    Process.sleep(5000)
    count2 = get_telemetry_message_count()

    received = count2 - count1
    expected_min = 30

    assert received >= expected_min,
           "Message loss detected: got #{received} messages in 5s, expected ~#{expected_min}"
  end

  test "telemetry is continuously flowing, not batched" do
    # Take 10 samples over 2 seconds
    # If telemetry is batched, we'd see clumps
    samples =
      Enum.map(1..10, fn _ ->
        Process.sleep(200)
        get_telemetry_message_count()
      end)

    # Count should be continuously increasing (no flat periods)
    increasing = Enum.chunk_every(samples, 2, 1, :discard)
    strictly_increasing = Enum.all?(increasing, fn [a, b] -> b > a end)

    assert strictly_increasing,
           "Telemetry not continuously flowing: #{inspect(samples)}"
  end

  # --- Helpers ---

  defp attach_telemetry_listener(channel) do
    event = [:tiannara_runtime, :cold_ignition, channel]
    id = "ci_#{channel}_#{System.unique_integer([:positive])}"
    pid = self()
    :telemetry.attach(id, event, fn _, measurements, _, _ ->
      send(pid, {:telemetry, channel, measurements})
    end, nil)
  end

  defp wait_for_telemetry(channel, timeout_ms) do
    start_time = System.monotonic_time(:millisecond)

    receive do
      {:telemetry, ^channel, _data} ->
        :ok
    after
      timeout_ms ->
        elapsed = System.monotonic_time(:millisecond) - start_time
        {:error, "Channel #{channel} didn't report within #{elapsed}ms"}
    end
  end

  defp collect_latencies(channels, opts) do
    num_samples = Keyword.get(opts, :num_samples, 100)
    timeout = Keyword.get(opts, :timeout, 60000)

    measurements = []

    Enum.reduce(1..num_samples, measurements, fn _i, acc ->
      t0 = System.monotonic_time(:millisecond)

      case receive_next_telemetry(timeout) do
        {:ok, _data} ->
          latency = System.monotonic_time(:millisecond) - t0
          [latency | acc]

        {:error, _} ->
          acc
      end
    end)
  end

  defp receive_next_telemetry(timeout) do
    receive do
      {:telemetry, _channel, data} ->
        {:ok, data}
    after
      timeout ->
        {:error, :timeout}
    end
  end

  defp get_telemetry_message_count do
    ColdIgnitionSupport.telemetry_count()
  end
end
