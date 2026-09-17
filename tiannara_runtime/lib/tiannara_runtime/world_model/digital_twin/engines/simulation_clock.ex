defmodule TiannaraRuntime.WorldModel.DigitalTwin.Engines.SimulationClock do
  @moduledoc """
  Phase 17.7.2 — SimulationClock engine.
  Deterministic simulation time management supporting fixed, variable, event-driven, and hybrid modes.
  """

  alias TiannaraRuntime.WorldModel.DigitalTwin.SimulationClock, as: Clock

  @doc """
  Creates a new SimulationClock with the given mode and delta.
  """
  def new(mode \\ :fixed, delta \\ 1.0, opts \\ []) do
    seed = Keyword.get(opts, :seed, :erlang.system_time())

    clock = %Clock{
      clock_id: nil,
      mode: mode,
      tick: 0,
      time: 0.0,
      delta: delta,
      total_ticks: 0,
      seed: seed,
      metadata: Keyword.get(opts, :metadata, %{})
    }

    compute_id(clock)
  end

  @doc """
  Advances the clock by one tick.
  """
  def tick(clock) do
    new_tick = clock.tick + 1
    new_time = clock.time + clock.delta

    updated = %{clock | tick: new_tick, time: new_time, total_ticks: clock.total_ticks + 1}
    compute_id(updated)
  end

  @doc """
  Sets a custom delta for variable timestep mode.
  """
  def set_delta(clock, delta) when delta > 0 do
    updated = %{clock | delta: delta}
    compute_id(updated)
  end

  @doc """
  Resets the clock to initial state.
  """
  def reset(clock) do
    %{clock | tick: 0, time: 0.0, total_ticks: 0}
    |> compute_id()
  end

  @doc """
  Computes the content-addressed clock_id.
  """
  def compute_id(clock) do
    canonical = %{
      mode: clock.mode,
      tick: clock.tick,
      time: clock.time,
      delta: clock.delta,
      seed: clock.seed
    }

    hash = :crypto.hash(:sha256, Jason.encode!(canonical)) |> Base.encode16(case: :lower)
    %{clock | clock_id: "sc_" <> hash}
  end
end
