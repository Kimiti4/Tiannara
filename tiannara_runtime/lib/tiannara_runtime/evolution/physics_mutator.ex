defmodule Tiannara.Meta.Evolution.PhysicsMutator do
  @moduledoc """
  PhysicsMutator - Safely mutates reality/physics law ASTs.
  """

  def mutate(law) do
    mutated_ast =
      case Map.get(law, :oir_ast) do
        {:const, val} when is_number(val) ->
          # Adjust by a small random delta, or simply change it safely
          {:const, val + 1.0}
        ast ->
          ast
      end

    Map.put(law, :oir_ast, mutated_ast)
  end
end
