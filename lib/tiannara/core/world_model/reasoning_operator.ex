defmodule Tiannara.Core.WorldModel.ReasoningOperator do
  @moduledoc """
  Phase 9 ERO: Represents the structural machinery of cognition.
  A fundamentally different ontological category than a Discovery.
  """

  @type operator_class ::
    :causal | :analogical | :counterfactual | :symbolic | :recursive |
    :adversarial | :topological | :narrative | :abductive | :systems |
    :probabilistic | :constraint

  @type t :: %__MODULE__{
    id: String.t(),
    name: String.t(),
    class: operator_class(),
    maturity: float(),
    stability: float(),
    compute_cost: float(),
    discovery_affinities: [atom()],
    prerequisite_operators: [String.t()],
    parent_operators: [String.t()],
    effectiveness: map(),
    disease_resistance: map(),
    originator_civ_id: String.t(),
    created_at: integer()
  }

  @enforce_keys [:id, :name, :class, :originator_civ_id]
  defstruct [
    :id,
    :name,
    :class,
    :originator_civ_id,
    maturity: 0.1,
    stability: 0.5,
    compute_cost: 100.0,
    discovery_affinities: [],
    prerequisite_operators: [],
    parent_operators: [],
    effectiveness: %{},
    disease_resistance: %{},
    created_at: nil
  ]

  def new(attrs) do
    struct!(__MODULE__, Map.put(attrs, :created_at, System.system_time(:millisecond)))
  end
end
