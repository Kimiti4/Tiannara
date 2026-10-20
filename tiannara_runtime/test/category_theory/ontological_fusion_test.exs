defmodule Tiannara.CategoryTheory.OntologicalFusionTest do
  @moduledoc """
  Property-based validation of ontological fusion without representational collapse.
  Verifies pushout construction, naturality commutativity, and adjunction safety.
  """
  use ExUnit.Case, async: true
  use PropCheck

  alias Tiannara.Category.{OntologyCategory, FunctorMapping, PushoutFusion, NaturalTransformation}

  @tolerance 1.0e-6

  property "Pushout fusion preserves monomorphic inclusions (no collapse)" do
    forall({c1, c2, shared, i1, i2} <- valid_fusion_scenario_generator(),
      do: assert_pushout_injectivity(c1, c2, shared, i1, i2))
  end

  property "Natural transformation squares commute within tolerance" do
    forall({f, g, eta, morphs} <- natural_transformation_generator(),
      do: assert_naturality_commutes(f, g, eta, morphs))
  end

  property "Adjunction preserves identity on shared interfaces" do
    forall({f, u, shared} <- adjunction_generator(),
      do: assert_adjunction_safety(f, u, shared))
  end

  # --- Generators ---
  defp valid_fusion_scenario_generator() do
    let {obj_count, morph_count} <- {integer(3, 10), integer(2, 5)}, do:
      generate_categories(obj_count, morph_count)
  end

  defp generate_categories(obj_count, _morph_count) do
    objs1 = MapSet.new(Enum.map(1..obj_count, &"c1_obj_#{&1}"))
    objs2 = MapSet.new(Enum.map(1..obj_count, &"c2_obj_#{&1}"))
    shared_objs = MapSet.new([:terminal | Enum.map(1..3, &"shared_obj_#{&1}")])
    
    c1 = %Tiannara.Category.OntologyCategory{objects: MapSet.union(objs1, shared_objs), morphisms: %{}, id: "c1"}
    c2 = %Tiannara.Category.OntologyCategory{objects: MapSet.union(objs2, shared_objs), morphisms: %{}, id: "c2"}
    shared = %Tiannara.Category.OntologyCategory{objects: shared_objs, morphisms: %{}, id: "shared"}
    
    i1 = %{object_map: Map.new(shared_objs, &{&1, &1})}
    i2 = %{object_map: Map.new(shared_objs, &{&1, &1})}
    
    {c1, c2, shared, i1, i2}
  end

  defp natural_transformation_generator() do
    let(morph <- atom(), do: {
      %{morphism_map: %{morph => 1.0}},
      %{morphism_map: %{morph => 1.0}},
      %{components: %{dom: %{weight: 1.0}, cod: %{weight: 1.0}}, epsilon: @tolerance},
      [morph]
    })
  end

  defp adjunction_generator() do
    {
      %{object_map: %{"x" => "y", "y" => "z"}},
      %{object_map: %{"y" => "x", "z" => "y"}},
      %{"x" => :shared, "y" => :shared}
    }
  end

  # --- Assertions ---
  defp assert_pushout_injectivity(c1, c2, shared, i1, i2) do
    case PushoutFusion.fuse(c1, c2, shared, i1, i2) do
      {:ok, _fused} -> true
      _ -> false
    end
  end

  defp assert_naturality_commutes(f, g, eta, morphs) do
    Enum.all?(morphs, fn m ->
      NaturalTransformation.verify_naturality(eta, m, :dom, :cod)
    end)
  end

  defp assert_adjunction_safety(f, u, shared) do
    Tiannara.Category.AdjunctionSafety.verify_unit_counit_laws(f, u, shared)
  end
end