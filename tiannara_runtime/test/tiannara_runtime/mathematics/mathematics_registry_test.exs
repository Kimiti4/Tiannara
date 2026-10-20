defmodule TiannaraRuntime.Mathematics.MathematicsRegistryTest do
  @moduledoc "Phase 16.X.2 — Mathematics Registry tests: registration, lookup, lifecycle, query."
  use ExUnit.Case, async: true

  alias TiannaraRuntime.Mathematics.MathematicsRegistry

  setup do
    MathematicsRegistry.reset_table()
    :ok
  end

  # ---------------------------------------------------------------------------
  # Registration
  # ---------------------------------------------------------------------------

  describe "register/3" do
    test "registers a valid artifact" do
      assert {:ok, reg_id} = MathematicsRegistry.register("Axiom", "math_abc123")
      assert String.starts_with?(reg_id, "reg_")
    end

    test "rejects invalid artifact type" do
      assert {:error, msg} = MathematicsRegistry.register("InvalidType", "id1")
      assert msg =~ "invalid artifact type"
    end

    test "rejects duplicate registration" do
      assert {:ok, _} = MathematicsRegistry.register("Theorem", "thm_001")
      assert {:error, msg} = MathematicsRegistry.register("Theorem", "thm_001")
      assert msg =~ "already registered"
    end

    test "rejects empty artifact_id" do
      assert {:error, msg} = MathematicsRegistry.register("Axiom", "")
      assert msg =~ "non-empty"
    end

    test "same type+id is rejected on second registration" do
      assert {:ok, _id1} = MathematicsRegistry.register("Lemma", "lemma_x")
      assert {:error, msg} = MathematicsRegistry.register("Lemma", "lemma_x")
      assert msg =~ "already registered"
    end
  end

  # ---------------------------------------------------------------------------
  # Lookup
  # ---------------------------------------------------------------------------

  describe "lookup/1" do
    test "returns stored registration" do
      assert {:ok, reg_id} = MathematicsRegistry.register("Definition", "def_group")
      assert {:ok, entry} = MathematicsRegistry.lookup(reg_id)
      assert entry["artifact_type"] == "Definition"
      assert entry["artifact_id"] == "def_group"
      assert entry["owner"] == "Constitutional Research Council"
      assert entry["lifecycle"] == "proposed"
    end

    test "returns error for missing registration" do
      assert {:error, _} = MathematicsRegistry.lookup("reg_nonexistent")
    end
  end

  # ---------------------------------------------------------------------------
  # Query
  # ---------------------------------------------------------------------------

  describe "find_by_type/1" do
    test "returns registrations filtered by type" do
      MathematicsRegistry.register("Axiom", "ax1")
      MathematicsRegistry.register("Axiom", "ax2")
      MathematicsRegistry.register("Theorem", "thm1")

      assert {:ok, axioms} = MathematicsRegistry.find_by_type("Axiom")
      assert length(axioms) == 2

      assert {:ok, theorems} = MathematicsRegistry.find_by_type("Theorem")
      assert length(theorems) == 1
    end

    test "returns empty list for unregistered type" do
      assert {:ok, results} = MathematicsRegistry.find_by_type("Conjecture")
      assert results == []
    end
  end

  # ---------------------------------------------------------------------------
  # Lifecycle
  # ---------------------------------------------------------------------------

  describe "lifecycle/1" do
    test "returns proposed for new registration" do
      assert {:ok, reg_id} = MathematicsRegistry.register("Axiom", "ax_test")
      assert {:ok, "proposed"} = MathematicsRegistry.lifecycle(reg_id)
    end

    test "returns error for missing registration" do
      assert {:error, _} = MathematicsRegistry.lifecycle("reg_missing")
    end
  end

  describe "transition/2" do
    test "transitions proposed → active" do
      assert {:ok, reg_id} = MathematicsRegistry.register("Axiom", "ax_trans")
      assert {:ok, entry} = MathematicsRegistry.transition(reg_id, "active")
      assert entry["lifecycle"] == "active"
    end

    test "transitions active → frozen" do
      assert {:ok, reg_id} = MathematicsRegistry.register("Theorem", "thm_frozen")
      MathematicsRegistry.transition(reg_id, "active")
      assert {:ok, entry} = MathematicsRegistry.transition(reg_id, "frozen")
      assert entry["lifecycle"] == "frozen"
    end

    test "rejects invalid lifecycle state" do
      assert {:ok, reg_id} = MathematicsRegistry.register("Axiom", "ax_inv")
      assert {:error, msg} = MathematicsRegistry.transition(reg_id, "invalid_state")
      assert msg =~ "invalid lifecycle"
    end

    test "rejects invalid transition from proposed to archived" do
      assert {:ok, reg_id} = MathematicsRegistry.register("Axiom", "ax_bad")
      assert {:error, msg} = MathematicsRegistry.transition(reg_id, "archived")
      assert msg =~ "invalid transition"
    end

    test "rejects transition from frozen" do
      assert {:ok, reg_id} = MathematicsRegistry.register("Theorem", "thm_lock")
      MathematicsRegistry.transition(reg_id, "active")
      MathematicsRegistry.transition(reg_id, "frozen")
      assert {:error, _} = MathematicsRegistry.transition(reg_id, "deprecated")
    end
  end

  # ---------------------------------------------------------------------------
  # List Active
  # ---------------------------------------------------------------------------

  describe "list_active/0" do
    test "excludes archived and frozen registrations" do
      assert {:ok, r1} = MathematicsRegistry.register("Axiom", "ax_a")
      assert {:ok, r2} = MathematicsRegistry.register("Theorem", "thm_b")
      assert {:ok, r3} = MathematicsRegistry.register("Lemma", "lem_c")

      MathematicsRegistry.transition(r1, "active")
      MathematicsRegistry.transition(r2, "active")
      MathematicsRegistry.transition(r2, "frozen")
      MathematicsRegistry.transition(r3, "active")
      MathematicsRegistry.transition(r3, "deprecated")
      MathematicsRegistry.transition(r3, "archived")

      assert {:ok, active} = MathematicsRegistry.list_active()
      active_ids = Enum.map(active, fn e -> e["artifact_id"] end)
      assert "ax_a" in active_ids
      assert "thm_b" not in active_ids
      assert "lem_c" not in active_ids
    end
  end

  # ---------------------------------------------------------------------------
  # Registered?
  # ---------------------------------------------------------------------------

  describe "registered?/1" do
    test "returns true for registered artifact" do
      MathematicsRegistry.register("Axiom", "ax_check")
      assert MathematicsRegistry.registered?("ax_check")
    end

    test "returns false for unregistered artifact" do
      refute MathematicsRegistry.registered?("nonexistent")
    end
  end

  # ---------------------------------------------------------------------------
  # Valid Types / Lifecycles
  # ---------------------------------------------------------------------------

  describe "valid_types/0" do
    test "returns all valid artifact types" do
      types = MathematicsRegistry.valid_types()
      assert "Axiom" in types
      assert "BoundedVerificationConfig" in types
    end
  end

  describe "valid_lifecycles/0" do
    test "returns all valid lifecycle states" do
      lifecycles = MathematicsRegistry.valid_lifecycles()
      assert "proposed" in lifecycles
      assert "frozen" in lifecycles
    end
  end
end
