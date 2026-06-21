defmodule Tiannara.REA.Causal.Signal do
  @moduledoc """
  A causal signal emitted by a source organism and propagating toward a target.
  
  Signals are typed, scalar values with metadata for attribution.
  They are the atoms of cross-level causality.
  """
  
  @type signal_type ::
    :truth_retention | :compute_capacity | :economic_output | :cohesion |
    :cognitive_yield | :operator_success | :coherence | :adaptability |
    :symmetry_stability | :perturbation_survival | :diversity_index |
    :innovation_rate | :resilience | :meta_fitness |
    atom()
  
  @type scale :: :individual | :species | :civilization | :law | :meta_law
  
  @type t :: %__MODULE__{
    type: signal_type(),
    value: float(),
    source_id: binary(),
    source_scale: scale(),
    source_population: atom(),
    emitted_epoch: non_neg_integer(),
    confidence: float()
  }
  
  defstruct [
    :type,
    :value,
    :source_id,
    :source_scale,
    :source_population,
    :emitted_epoch,
    confidence: 1.0
  ]
  
  @doc "Construct a signal from an emitting organism's identity."
  @spec emit(signal_type(), float(), Tiannara.REA.EvolutionaryIdentity.t(), atom(), non_neg_integer()) :: t()
  def emit(type, value, identity, population, epoch) when is_float(value) do
    %__MODULE__{
      type: type,
      value: value,
      source_id: identity.id,
      source_scale: identity.scale,
      source_population: population,
      emitted_epoch: epoch,
      confidence: 1.0
    }
  end
end
