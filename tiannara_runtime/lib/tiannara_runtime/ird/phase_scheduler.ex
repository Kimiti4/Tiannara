defmodule TiannaraRuntime.IRD.PhaseScheduler do
  @moduledoc """
  Phase 5F.12 — IRD Phase Scheduler

  Decides safe execution delay windows for interventions and smooths out
  competing stabilizer execution across the runtime mesh.
  """

  use GenServer
  require Logger

  @default_delay_ms 120
  @max_delay_ms 1_200
  @min_delay_ms 40

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{last_delay: @default_delay_ms}}
  end

  @doc "Compute a phase delay based on the current interference profile."
  def compute_delay(%{max_value: max_interference}) when is_number(max_interference) do
    delay = round(@default_delay_ms + max_interference * (@max_delay_ms - @default_delay_ms))
    max(@min_delay_ms, min(delay, @max_delay_ms))
  end

  @doc "Compute a phase delay for a single proposal if interference is unavailable."
  def compute_delay(_), do: @default_delay_ms
end
