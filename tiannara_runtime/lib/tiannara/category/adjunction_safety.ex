defmodule Tiannara.Category.AdjunctionSafety do
  @moduledoc """
  Free-Forgetful adjunction (F ⊣ U) for substrate-independent representation.
  Ensures U ∘ F ≅ Id_S on shared interfaces, preventing representational leakage.
  """
  @spec verify_unit_counit_laws(functor_f :: map(), functor_u :: map(), shared :: map()) :: boolean()
  def verify_unit_counit_laws(f, u, shared) do
    # Check (U ∘ F)(x) ≅ x for all x in shared
    Enum.all?(shared, fn {obj, _} ->
      mapped = Map.get(f.object_map, obj)
      recovered = Map.get(u.object_map, mapped)
      recovered == obj
    end)
  end
end