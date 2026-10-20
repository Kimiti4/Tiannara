defmodule Tiannara.Kernel.CategoryTheoreticValidatorTest do
  use ExUnit.Case, async: true

  alias Tiannara.Kernel.CategoryTheoreticValidator

  describe "validate_identities/1" do
    test "passes rules containing identity-preserving elements" do
      valid_rules = %{
        omce: %{
          body: {:apply, :adaptive, [:aggressive]},
          invariants: [:causal_conservation]
        },
        olef: %{
          body: {:diffuse, :pressure_field, 0.05, {:cap, 1.0}},
          invariants: [:causal_conservation]
        },
        hsv: %{
          body: :ignore,
          invariants: [:causal_conservation]
        }
      }

      assert :ok == CategoryTheoreticValidator.validate_identities(valid_rules)
    end

    test "fails rules violating identity-preserving bounds" do
      invalid_rules = %{
        olef: %{
          # Rate must be within [0, 1]. 1.5 is a non-contraction mapping.
          body: {:diffuse, :pressure_field, 1.5, {:cap, 1.0}}
        }
      }

      assert {:error, reason} = CategoryTheoreticValidator.validate_identities(invalid_rules)
      assert reason =~ "Identity morphism violation"
    end
  end

  describe "validate_composition/1" do
    test "passes homomorphic composed structures" do
      valid_rules = %{
        omce: %{
          body: {:if, {:>, :ontology_density, 0.7}, {:apply, :adaptive, [:aggressive]}, {:apply, :adaptive, [:conservative]}}
        },
        olef: %{
          body: {:diffuse, :pressure_field, 0.05, {:cap, 1.0}}
        }
      }

      assert :ok == CategoryTheoreticValidator.validate_composition(valid_rules)
    end

    test "fails rules with non-monotonic composed cap boundaries" do
      invalid_rules = %{
        olef: %{
          # Negative cap limits violate pressure monotonicity
          body: {:diffuse, :pressure_field, 0.05, {:cap, -1.0}}
        }
      }

      assert {:error, reason} = CategoryTheoreticValidator.validate_composition(invalid_rules)
      assert reason =~ "Functorial composition violation"
    end
  end

  describe "verify/1" do
    test "asserts overall category-theoretic safety" do
      valid_rules = %{
        omce: %{
          body: {:apply, :adaptive, [:aggressive]}
        }
      }

      assert :ok == CategoryTheoreticValidator.verify(valid_rules)
    end
  end
end
