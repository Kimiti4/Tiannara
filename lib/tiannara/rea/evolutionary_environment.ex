defmodule Tiannara.REA.EvolutionaryEnvironment do
  @moduledoc """
  A universal environment format passed to organism fitness checks.
  Allows REA to exert pressure consistently across all levels.
  """
  defstruct [
    world_id: "default-world",
    pressures: %{},        # e.g., %{acm: 0.9, economic: 0.5}
    resources: %{},        # e.g., %{compute_ceiling: 1000}
    predators: [],         # e.g., %LawSpecies{} acting as predators
    diseases: [],          # e.g., Epistemic viruses
    niches: %{},           # Niche conditions mapped out
    specialization_bias: %{}, # Map of the 20 domains -> bias float
    constitutional_constraints: %{}, # Hard ceilings defined by higher laws
    active_civilizations: []
  ]
  
  @type t :: %__MODULE__{}

  @doc """
  Advances the world by one epoch. Applies the environment's specialization 
  bias to all active civilizations during mutation.
  """
  @spec step(t()) :: t()
  def step(%__MODULE__{} = env) do
    new_civilizations =
      Enum.map(env.active_civilizations, fn civ ->
        Tiannara.Ecology.Civilization.mutate(civ, env)
      end)

    %__MODULE__{
      env
      | active_civilizations: new_civilizations
    }
  end

  @doc """
  Adds a newly spawned or migrated civilization to the world.
  """
  @spec add_civilization(t(), any()) :: t()
  def add_civilization(%__MODULE__{} = env, civ) do
    %__MODULE__{
      env
      | active_civilizations: [civ | env.active_civilizations]
    }
  end

  # Ensures all bias values are >= 1.0 (1.0 = neutral, >1.0 = amplified pressure)
  def normalize_bias(bias) do
    Map.new(bias, fn {k, v} -> {k, max(1.0, v)} end)
  end
end
