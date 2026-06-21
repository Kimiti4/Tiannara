defmodule Tiannara.REA.Causal.PressureInjector do
  @moduledoc """
  Applies incoming causal pressure to organisms.
  """
  
  alias Tiannara.REA.Causal.PressureField
  
  @spec prepare_environment(atom(), non_neg_integer(), map()) :: map()
  def prepare_environment(population, epoch, base_env) do
    pressure = PressureField.compute(population, epoch)
    PressureField.inject_into_env(pressure, base_env)
  end
  
  @spec apply_to_organism(term(), map()) :: term()
  def apply_to_organism(organism, env_with_pressure) do
    pressure = Map.get(env_with_pressure, :causal_pressure, %{})
    mod = organism_module(organism)
    
    if function_exported?(mod, :receive_pressure, 2) do
      mod.receive_pressure(organism, pressure)
    else
      organism
    end
  end
  
  @spec adjusted_extinction_threshold(term(), map(), float()) :: float()
  def adjusted_extinction_threshold(_organism, env, base_threshold) do
    pressure = Map.get(env, :causal_pressure, %{})
    resilience = PressureField.get(pressure, :resilience, 0.0)
    base_threshold * (1.0 - 0.3 * resilience)
  end
  
  defp organism_module(%{__struct__: mod}), do: mod
  defp organism_module(_), do: nil
end
