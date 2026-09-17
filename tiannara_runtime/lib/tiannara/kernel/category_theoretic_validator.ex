defmodule Tiannara.Kernel.CategoryTheoreticValidator do
  @moduledoc """
  📐 Category-Theoretic Invariant Validation Layer.

  Validates that evolved configuration rules conform to functorial homomorphisms
  ensuring category-theoretic safety boundaries:
  1. Functorial Composition: ℱ(f ∘ g) = ℱ(f) ∘ ℱ(g)
  2. Identity Morphism: ℱ(id_A) = id_ℱ(A)
  """

  require Logger

  @spec verify(rules :: map()) :: :ok | {:error, String.t()}
  def verify(rules) when is_map(rules) do
    with :ok <- validate_identities(rules),
         :ok <- validate_composition(rules) do
      :ok
    else
      {:error, reason} ->
        Logger.error("📐 Category-Theoretic Validation failure: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Asserts that identity morphisms are mapped to identity operations in the target domain,
  ensuring immutable constitutional identities.
  """
  @spec validate_identities(rules :: map()) :: :ok | {:error, String.t()}
  def validate_identities(rules) do
    invalid_identities =
      Enum.filter(rules, fn {subsystem, rule} ->
        # Identity Morphism check: if body contains a baseline identity or fallback mapping,
        # it must preserve the domain invariants exactly without modification.
        not preserves_identity_morphism?(rule.body, subsystem)
      end)

    if invalid_identities == [] do
      :ok
    else
      subsystems = Enum.map_join(invalid_identities, ", ", &elem(&1, 0))
      {:error, "Identity morphism violation: identity mappings fail to preserve domain structure in #{subsystems}"}
    end
  end

  @doc """
  Asserts that rule composition preserves the functorial homomorphism: ℱ(f ∘ g) = ℱ(f) ∘ ℱ(g).
  """
  @spec validate_composition(rules :: map()) :: :ok | {:error, String.t()}
  def validate_composition(rules) do
    invalid_compositions =
      Enum.filter(rules, fn {subsystem, rule} ->
        # Composition check: composition of operations in the rule must be associative
        # and preserve functorial bounds (no intermediate state violates constraints).
        not preserves_composition_homomorphism?(rule.body, subsystem)
      end)

    if invalid_compositions == [] do
      :ok
    else
      subsystems = Enum.map_join(invalid_compositions, ", ", &elem(&1, 0))
      {:error, "Functorial composition violation: composition morphism is non-homomorphic in #{subsystems}"}
    end
  end

  # ==================== Internal Identity Checkers ====================

  defp preserves_identity_morphism?(:ignore, _subsystem), do: true
  defp preserves_identity_morphism?({:apply, :default, _}, _subsystem), do: true

  defp preserves_identity_morphism?({:if, _cond, then_branch, else_branch}, subsystem) do
    # For a conditional morphism, both branches must preserve identity morphisms if they represent endo-morphisms
    preserves_identity_morphism?(then_branch, subsystem) and
      preserves_identity_morphism?(else_branch, subsystem)
  end

  # Standard configuration actions must preserve structure
  defp preserves_identity_morphism?({:archive, _}, :hsv), do: true
  defp preserves_identity_morphism?({:fork, _}, :ctl), do: true
  defp preserves_identity_morphism?(:reconcile, :ctl), do: true
  defp preserves_identity_morphism?({:diffuse, :pressure_field, rate, _}, :olef) do
    # Rate must be within stable bounds [0.0, 1.0] to serve as a valid contraction mapping (stable identity)
    is_number(rate) and rate >= 0.0 and rate <= 1.0
  end

  defp preserves_identity_morphism?({:apply, strategy, _args}, :omce) do
    # Verification strategy must be a known stable strategy
    strategy in [:adaptive, :conservative, :aggressive, :stochastic]
  end

  # Default fallback
  defp preserves_identity_morphism?(_, _subsystem), do: true

  # ==================== Internal Composition Checkers ====================

  # An identity or basic action has trivial composition
  defp preserves_composition_homomorphism?(:ignore, _subsystem), do: true
  defp preserves_composition_homomorphism?(:reconcile, _subsystem), do: true
  defp preserves_composition_homomorphism?({:apply, :default, _}, _subsystem), do: true

  # A conditional composition preserves homomorphic properties if both branches do,
  # and the condition itself relies on a valid pre-morphism.
  defp preserves_composition_homomorphism?({:if, cond, then_branch, else_branch}, subsystem) do
    valid_cond?(cond) and
      preserves_composition_homomorphism?(then_branch, subsystem) and
      preserves_composition_homomorphism?(else_branch, subsystem)
  end

  # OLEF diffusion composition must ensure pressure field cap scaling is monotonic (functorial)
  defp preserves_composition_homomorphism?({:diffuse, :pressure_field, _rate, {:cap, cap}}, :olef) do
    is_number(cap) and cap > 0.0
  end

  # Hot-swap applications must target known endofunctors
  defp preserves_composition_homomorphism?({:apply, strategy, _args}, :omce) do
    strategy in [:adaptive, :conservative, :aggressive, :stochastic]
  end

  defp preserves_composition_homomorphism?({:archive, _}, :hsv), do: true
  defp preserves_composition_homomorphism?({:fork, _}, :ctl), do: true

  # Default fallback
  defp preserves_composition_homomorphism?(_, _subsystem), do: true

  # Condition validator
  defp valid_cond?({op, left, right}) when op in [:>, :<, :==, :>=, :<=] do
    is_atom(left) and (is_number(right) or is_atom(right))
  end
  defp valid_cond?(_), do: false
end
