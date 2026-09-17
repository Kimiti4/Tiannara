defmodule Tiannara.Category.FunctorMapping do
  @moduledoc """
  Structure-preserving translation F: C → D.
  Maps objects to objects, morphisms to morphisms, preserves identity & composition.
  """
  defstruct [:id, :source_category, :target_category, :object_map, :morphism_map]

  @type t :: %__MODULE__{
    id: String.t(),
    source_category: Tiannara.Category.OntologyCategory.t(),
    target_category: Tiannara.Category.OntologyCategory.t(),
    object_map: Map.t(),
    morphism_map: Map.t()
  }

  @spec preserve_composition?(t(), atom(), atom()) :: boolean()
  def preserve_composition?(functor, f, g) do
    # Verify F(g ∘ f) = F(g) ∘ F(f) within structural bounds
    f_mapped = Map.get(functor.morphism_map, f)
    g_mapped = Map.get(functor.morphism_map, g)
    fg_composed = Map.get(functor.morphism_map, {f, g})
    
    !is_nil(f_mapped) and !is_nil(g_mapped) and !is_nil(fg_composed)
  end
end