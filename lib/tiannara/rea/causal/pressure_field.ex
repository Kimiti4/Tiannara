defmodule Tiannara.REA.Causal.PressureField do
  @moduledoc """
  Computes the aggregate causal pressure imposed on a population
  at a given epoch.
  """
  
  alias Tiannara.REA.Causal.Graph
  alias Tiannara.REA.Causal.Signal
  
  @type pressure :: %{Signal.signal_type() => float()}
  
  @spec compute(atom(), non_neg_integer()) :: pressure()
  def compute(population, epoch), do: Graph.collect_pressures(population, epoch)
  
  @spec inject_into_env(pressure(), map()) :: map()
  def inject_into_env(pressure, env) do
    Map.put(env, :causal_pressure, pressure)
  end
  
  @spec get(pressure(), Signal.signal_type(), float()) :: float()
  def get(pressure, signal_type, default \\ 0.0) do
    Map.get(pressure, signal_type, default)
  end
  
  @spec magnitude(pressure()) :: float()
  def magnitude(pressure) do
    pressure |> Map.values() |> Enum.map(&abs/1) |> Enum.sum()
  end
end
