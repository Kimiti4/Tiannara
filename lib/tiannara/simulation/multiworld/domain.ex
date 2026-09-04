defmodule Tiannara.Simulation.MultiWorld.Domain do
  defmodule WorldFork do
    defstruct [:id, :parent_snapshot_id, :name, :description, :divergence_point,
      :injected_changes, :constraint_modifications, :parameters, :status, :created_at, :seed]

    @type t :: %__MODULE__{}

    @statuses [:created, :running, :completed, :failed, :abandoned]

    def statuses, do: @statuses

    def new(attrs) do
      %__MODULE__{
        id: "fork_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        injected_changes: [],
        constraint_modifications: [],
        parameters: %{},
        status: :created,
        created_at: DateTime.utc_now(),
        seed: :crypto.strong_rand_bytes(4) |> :binary.decode_unsigned()
      }
      |> struct(attrs)
    end
  end

  defmodule CounterfactualScenario do
    defstruct [:id, :question, :baseline_world_id, :counterfactual_world_id,
      :divergence_description, :variables_changed, :variables_held_constant,
      :expected_outcome, :actual_outcome, :causal_attribution, :confidence, :created_at]

    @type t :: %__MODULE__{}

    def new(attrs) do
      %__MODULE__{
        id: "cf_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        variables_changed: [],
        variables_held_constant: [],
        confidence: 0.5,
        created_at: DateTime.utc_now()
      }
      |> struct(attrs)
    end
  end

  defmodule WorldComparison do
    defstruct [:id, :world_ids, :baseline_world_id, :dimensions, :divergences,
      :convergences, :causal_insights, :composite_divergence, :created_at]

    @type t :: %__MODULE__{}

    def new(attrs) do
      %__MODULE__{
        id: "cmp_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        dimensions: [],
        divergences: [],
        convergences: [],
        causal_insights: [],
        created_at: DateTime.utc_now()
      }
      |> struct(attrs)
    end
  end

  defmodule ConstraintRelaxation do
    defstruct [:id, :original_constraint, :relaxed_constraint, :relaxation_factor,
      :boundary_discovered, :sensitivity, :created_at]

    @type t :: %__MODULE__{}

    def new(attrs) do
      %__MODULE__{
        id: "relax_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        relaxation_factor: 0.5,
        boundary_discovered: false,
        sensitivity: 0.5,
        created_at: DateTime.utc_now()
      }
      |> struct(attrs)
    end
  end
end
