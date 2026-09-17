defmodule TiannaraRuntime.WorldModel.Counterfactual.InterventionExecutor do
  @moduledoc """
  Phase 17.5.2 — InterventionExecutor: validates and applies deterministic
  interventions to certified world models.
  """
  alias TiannaraRuntime.WorldModel.Ontology.WorldModel
  alias TiannaraRuntime.WorldModel.Counterfactual.Intervention

  import Kernel, except: [apply: 2]

  @spec execute(WorldModel.t(), Intervention.t()) :: {:ok, WorldModel.t()} | {:error, String.t()}
  def execute(%WorldModel{} = world_model, %Intervention{} = intervention) do
    with :ok <- validate_intervention(world_model, intervention) do
      apply(world_model, intervention)
    end
  end

  @spec validate_intervention(WorldModel.t(), Intervention.t()) :: :ok | {:error, String.t()}
  def validate_intervention(%WorldModel{variables: vars} = wm, %Intervention{target: target, type: type}) do
    cond do
      type == :variable and not Enum.any?(vars, fn v -> v.name == target or v.variable_id == target end) ->
        {:error, "Intervention target #{target} not found in world model variables"}
      type == :structural and is_nil(wm.causal_graph) ->
        {:error, "Structural intervention requires a causal graph"}
      true ->
        :ok
    end
  end

  def validate_intervention(_, _), do: {:error, "Invalid intervention or world model"}

  @spec apply(WorldModel.t(), Intervention.t()) :: {:ok, WorldModel.t()} | {:error, String.t()}
  def apply(%WorldModel{} = world_model, %Intervention{type: :variable, target: target, operation: :fix, value: val}) do
    ss = world_model.state_space
    new_defaults = Map.put(Map.get(ss, :default_initial, %{}), target, val)
    new_ss = Map.put(ss, :default_initial, new_defaults)
    {:ok, %{world_model | state_space: new_ss}}
  end

  def apply(%WorldModel{} = world_model, %Intervention{operation: :remove, target: target}) do
    new_vars = Enum.reject(world_model.variables, fn v -> v.name == target or v.variable_id == target end)
    {:ok, %{world_model | variables: new_vars}}
  end

  def apply(%WorldModel{} = _world_model, %Intervention{type: type, operation: op}) do
    {:error, "Unsupported intervention: type #{inspect(type)}, operation #{inspect(op)}"}
  end

  def apply(%WorldModel{} = _world_model, _), do: {:error, "Invalid intervention struct"}
end
