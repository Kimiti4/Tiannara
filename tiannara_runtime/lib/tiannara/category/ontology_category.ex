defmodule Tiannara.Category.OntologyCategory do
  @moduledoc """
  Represents an ontology as a category C = (Obj, Hom, ∘).
  Objects = concepts/entities, Morphisms = relationships/transformations.
  """
  defstruct [:id, :objects, :morphisms, :composition_table]

  @type t :: %__MODULE__{
    id: String.t(),
    objects: MapSet.t(atom()),
    morphisms: Map.t({atom(), atom()}, map()),
    composition_table: Map.t({{atom(), atom()}, atom()})
  }

  @spec compose(t(), atom(), atom(), atom()) :: {:ok, map()} | {:error, :undefined_morphism}
  def compose(%{morphisms: morphs, composition_table: comp}, f, g, target) do
    case Map.fetch(comp, {f, g}) do
      {:ok, h} -> Map.fetch(morphs, {f, target})
      :error -> {:error, :undefined_morphism}
    end
  end

  @spec has_terminal(t()) :: boolean()
  def has_terminal(%{objects: objs}), do: MapSet.member?(objs, :terminal)
end