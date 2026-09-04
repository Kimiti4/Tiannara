defmodule Tiannara.Simulation.MultiWorld.ConstraintRelaxer do
  alias Tiannara.Simulation.MultiWorld.Domain.ConstraintRelaxation

  @spec generate_schedule([map()], non_neg_integer()) :: [ConstraintRelaxation.t()]
  def generate_schedule(constraints, steps \\ 5) when is_list(constraints) do
    Enum.flat_map(constraints, fn constraint ->
      generate_relaxation_steps(constraint, steps)
    end)
  end

  @spec analyze_sensitivity([ConstraintRelaxation.t()]) :: map()
  def analyze_sensitivity(relaxations) when is_list(relaxations) do
    if relaxations == [] do
      %{binding_constraints: [], slack_constraints: [], sensitivities: %{}}
    else
      grouped = Enum.group_by(relaxations, & &1.original_constraint)

      sensitivities =
        Map.new(grouped, fn {constraint, rels} ->
          avg_sensitivity =
            rels
            |> Enum.map(& &1.sensitivity)
            |> Enum.sum()
            |> Kernel./(length(rels))

          {constraint, avg_sensitivity}
        end)

      {binding, slack} =
        Enum.split_with(sensitivities, fn {_constraint, sensitivity} -> sensitivity > 0.5 end)

      %{
        binding_constraints: Enum.map(binding, fn {c, _s} -> c end),
        slack_constraints: Enum.map(slack, fn {c, _s} -> c end),
        sensitivities: sensitivities,
        most_binding: if(binding != [], do: Enum.max_by(binding, fn {_c, s} -> s end) |> elem(0), else: nil)
      }
    end
  end

  defp generate_relaxation_steps(constraint, steps) do
    name = Map.get(constraint, :name, "unnamed")
    _current_value = Map.get(constraint, :value, 1.0)

    Enum.map(1..steps, fn step ->
      factor = step / steps

      ConstraintRelaxation.new(%{
        original_constraint: name,
        relaxed_constraint: "#{name} relaxed by #{Float.round(factor * 100, 0)}%",
        relaxation_factor: factor,
        sensitivity: 0.0
      })
    end)
  end
end
