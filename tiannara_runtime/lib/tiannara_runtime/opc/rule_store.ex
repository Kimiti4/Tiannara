defmodule Tiannara.OPC.RuleStore do
  @moduledoc """
  Phase 5F.9 — Rule store.
  Persists compiled physics rules for runtime inspection and replay.
  """

  use Agent

  def start_link(opts \\ []) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def put(rule) do
    Agent.update(__MODULE__, fn rules -> [rule | rules] end)
  end

  def all do
    Agent.get(__MODULE__, & &1)
  end

  def reset do
    Agent.update(__MODULE__, fn _ -> [] end)
  end

  def count do
    Agent.get(__MODULE__, &length(&1))
  end

  # Define child_spec for supervisor compatibility
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end
end
