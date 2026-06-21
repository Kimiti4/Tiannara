defmodule Tiannara.Core.WorldModel.EpistemicDisease do
  @moduledoc """
  A first-class World Model Entity representing a cognitive pathology or
  destructive paradigm that spreads through the ecology.
  """

  @type disease_class :: 
    :reinforcement | 
    :novelty | 
    :conservatism | 
    :optimization | 
    :contradiction | 
    :authority

  @type t :: %__MODULE__{
    id: String.t(),
    parent_disease_ids: [String.t()],
    target_type: atom(),
    class: disease_class(),
    virulence: float(),
    persistence: float(),
    detectability: float(),
    mutation_rate: float(),
    origin_shard_id: String.t(),
    transmission_count: integer(),
    cure_count: integer(),
    extinction_count: integer(),
    created_at: integer()
  }

  @enforce_keys [:id, :class, :origin_shard_id, :target_type]
  defstruct [
    :id,
    :class,
    :origin_shard_id,
    :target_type,
    parent_disease_ids: [],
    virulence: 0.5,
    persistence: 0.5,
    detectability: 0.5,
    mutation_rate: 0.1,
    transmission_count: 0,
    cure_count: 0,
    extinction_count: 0,
    created_at: nil
  ]

  def new(attrs) do
    struct!(__MODULE__, Map.put(attrs, :created_at, System.system_time(:millisecond)))
  end
end
