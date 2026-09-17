defmodule Tiannara.OS.CivilizationTestHelper do
  @moduledoc """
  Helper functions for civilization-level selection validation tests.
  
  Provides utilities for creating test worlds, programs, and running simulations.
  """
  
  alias TiannaraOS.State
  
  @doc """
  Create a test world with configurable needs.
  """
  def create_test_world(id, needs \\ %{}) do
    %{
      id: id,
      needs_vector: Map.merge(
        %{
          energy: 0.8,
          materials: 0.5,
          manufacturing: 0.4
        },
        needs
      ),
      wealth: 10_000.0
    }
  end
  
  @doc """
  Create a test program with domain preferences.
  """
  def create_test_program(id, world_id, domain_preferences \\ %{}) do
    %{
      id: id,
      world_id: world_id,
      status: :active,
      traits: %{
        domain_preferences: domain_preferences,
        risk_tolerance: 0.5,
        exploration_bias: 0.5
      },
      budget: %{
        credits: 1000.0,
        compute: 1000.0,
        attention: 1000.0
      }
    }
  end
  
  @doc """
  Run simulation for specified number of ticks.
  """
  def run_ticks(state, ticks, tick_fn) do
    Enum.reduce(1..ticks, state, fn tick, acc ->
      tick_fn.(acc, tick)
    end)
  end
  
  @doc """
  Calculate average fitness across all programs.
  """
  def calculate_average_fitness(programs) do
    values = programs
      |> Enum.map(fn {_id, p} ->
        Map.get(p, :fitness, 0.0)
      end)
    
    if values == [] do
      0.0
    else
      Enum.sum(values) / length(values)
    end
  end
end
