defmodule Tiannara.REA.EvolutionaryOrganism do
  @moduledoc """
  The universal contract for every evolving entity in Tiannara.
  
  ## Core Principles
  1. Topological Uniformity
  2. Contextual Fitness
  3. Archaeological Completeness
  4. Niche Awareness
  """
  
  alias Tiannara.REA.{EvolutionaryIdentity, EvolutionaryRuin, EvolutionaryEnvironment}
  
  @type organism :: term()
  @type environment :: EvolutionaryEnvironment.t()
  
  @callback evolutionary_level() :: EvolutionaryIdentity.level()
  
  @callback identity(organism()) :: EvolutionaryIdentity.t()
  
  @callback niche(organism()) :: term()
  
  @callback fitness(organism(), environment()) :: float()
  
  @callback mutate(organism(), environment()) :: organism()
  
  @callback recombine(organism(), [organism()], environment()) :: organism()
  
  @callback extinct?(organism(), environment()) :: boolean()
  
  @callback archive(organism(), keyword()) :: EvolutionaryRuin.t()
  
  @doc """
  Returns a list of descendant identity IDs.
  """
  @callback descendants(organism()) :: [binary()]
  
  @doc """
  Extract causal signals this organism emits this epoch.
  """
  @callback emit_signals(organism()) :: [Tiannara.REA.Causal.Signal.t()]
  
  @doc """
  Apply incoming causal pressure to organism state.
  """
  @callback receive_pressure(organism(), %{Tiannara.REA.Causal.Signal.signal_type() => float()}) :: organism()

  @optional_callbacks [descendants: 1, emit_signals: 1, receive_pressure: 2]
end
