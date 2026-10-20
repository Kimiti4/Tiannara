defmodule ColdIgnition.TelemetryAssertions do
  @moduledoc false

  alias TiannaraRuntime.Monitoring.ColdIgnitionSupport

  def attach_channels(channels) do
    Enum.each(channels, &ColdIgnitionSupport.attach_listener/1)

    ExUnit.Callbacks.on_exit(fn ->
      Enum.each(channels, &ColdIgnitionSupport.detach_listener/1)
    end)

    :ok
  end

  def await_channel(channel, timeout_ms) do
    receive do
      {:telemetry, ^channel, measurements} -> {:ok, measurements}
    after
      timeout_ms -> {:error, :timeout}
    end
  end
end
