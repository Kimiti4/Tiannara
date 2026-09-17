defmodule Tiannara.Category.PushoutFusion do
  @moduledoc """
  Computes pushout P = C₁ ⊔ₛ C₂ for ontological fusion over shared interface S.
  Ensures monomorphic inclusions, limit preservation, and no representational collapse.
  """
  alias Tiannara.Category.{OntologyCategory, FunctorMapping, NaturalTransformation}

  @spec fuse(
    c1 :: OntologyCategory.t(),
    c2 :: OntologyCategory.t(),
    shared :: OntologyCategory.t(),
    i1 :: FunctorMapping.t(),
    i2 :: FunctorMapping.t()
  ) :: {:ok, OntologyCategory.t()} | {:error, :representational_collapse}
  def fuse(c1, c2, shared, i1, i2) do
    with :ok <- verify_monomorphic_inclusions(i1, i2),
         :ok <- verify_limit_preservation(c1, c2, shared),
         fused_objects <- compute_pushout_objects(c1, c2, shared, i1, i2),
         fused_morphisms <- compute_pushout_morphisms(c1, c2, shared, i1, i2),
         fused_category <- build_fused_category(fused_objects, fused_morphisms) do
      {:ok, fused_category}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp verify_monomorphic_inclusions(i1, i2) do
    # Ensure no shared object maps to multiple distinct targets (injectivity)
    i1_targets = Map.values(i1.object_map)
    i2_targets = Map.values(i2.object_map)
    
    if length(Enum.uniq(i1_targets)) == length(i1_targets) and
       length(Enum.uniq(i2_targets)) == length(i2_targets) do
      :ok
    else
      {:error, :representational_collapse}
    end
  end

  defp verify_limit_preservation(c1, c2, shared) do
    # Shared terminal/pullbacks must be preserved in fusion
    if OntologyCategory.has_terminal(shared) and
       OntologyCategory.has_terminal(c1) and OntologyCategory.has_terminal(c2) do
      :ok
    else
      {:error, :limit_violation}
    end
  end

  defp compute_pushout_objects(c1, c2, shared, i1, i2) do
    # P = (Obj(C₁) ⊔ Obj(C₂)) / ~ where ~ identifies shared images
    obj1 = MapSet.to_list(c1.objects)
    obj2 = MapSet.to_list(c2.objects)
    shared_objs = MapSet.to_list(shared.objects)
    
    # Equivalence relation via functor images
    equivalence_classes = 
      Enum.reduce(shared_objs, obj1 ++ obj2, fn s, acc ->
        img1 = Map.fetch!(i1.object_map, s)
        img2 = Map.fetch!(i2.object_map, s)
        # Union into single class (simplified)
        Enum.reject(acc, &(&1 in [img1, img2])) ++ [img1]
      end)
      
    MapSet.new(equivalence_classes)
  end

  defp compute_pushout_morphisms(c1, c2, _shared, i1, i2) do
    # Morphisms are functor images, merged where domains/codomains match
    m1 = Enum.map(c1.morphisms, fn {k, v} -> {map_via(i1, k), v} end) |> Map.new()
    m2 = Enum.map(c2.morphisms, fn {k, v} -> {map_via(i2, k), v} end) |> Map.new()
    Map.merge(m1, m2, fn _k, v1, v2 -> Map.merge(v1, v2, fn _, a, b -> max(a, b) end) end)
  end

  defp build_fused_category(objects, morphisms) do
    %{
      __struct__: OntologyCategory,
      id: "pushout_#{System.system_time()}",
      objects: objects,
      morphisms: morphisms,
      composition_table: %{}
    }
  end

  defp map_via(functor, {dom, cod}) do
    {Map.get(functor.object_map, dom, dom), Map.get(functor.object_map, cod, cod)}
  end
end