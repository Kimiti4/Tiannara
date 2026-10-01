defmodule TiannaraRuntime.Mathematics.MultiObjectiveOptimizer do
  @moduledoc """
  Builds Pareto candidates for competing objectives without selecting a
  preferred trade-off on its own.

  The optimizer can identify dominated candidates. Choosing among
  non-dominated trade-offs requires an explicit policy or human authority.
  """

  def pareto_front(candidates, objectives) when is_list(candidates) and is_list(objectives) do
    if Enum.all?(candidates, &objective_vector?(&1, objectives)) do
      front = Enum.reject(candidates, fn candidate ->
        Enum.any?(candidates, fn other ->
          other != candidate and dominates?(other, candidate, objectives)
        end)
      end)
      {:ok, %{front: front, dominated: candidates -- front, selection_required: length(front) > 1}}
    else
      {:error, :objective_values_missing}
    end
  end

  defp objective_vector?(candidate, objectives),
    do: Enum.all?(objectives, &is_number(Map.get(candidate, &1)))

  defp dominates?(a, b, objectives) do
    values = Enum.map(objectives, fn objective -> {Map.fetch!(a, objective), Map.fetch!(b, objective)} end)
    Enum.all?(values, fn {x, y} -> x >= y end) and Enum.any?(values, fn {x, y} -> x > y end)
  end
end
