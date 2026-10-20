defmodule TiannaraRuntime.Mathematics.OntologyTest do
  @moduledoc "Phase 16.X.1 — Mathematical Ontology tests: structs, validators, IDs, serialization."
  use ExUnit.Case, async: true

  alias TiannaraRuntime.Mathematics.MathematicalID

  describe "MathematicalID" do
    test "from_canonical_map produces lowercase hex" do
      id = MathematicalID.from_canonical_map(%{"a" => 1, "b" => 2})
      assert String.match?(id, ~r/^[0-9a-f]{64}$/)
    end

    test "from_canonical_map is deterministic regardless of key order" do
      a = MathematicalID.from_canonical_map(%{"x" => 1, "y" => 2})
      b = MathematicalID.from_canonical_map(%{"y" => 2, "x" => 1})
      assert a == b
    end

    test "from_bytes produces SHA-256 hex" do
      id = MathematicalID.from_bytes("hello")
      assert String.match?(id, ~r/^[0-9a-f]{64}$/)
    end
  end

  # ---------------------------------------------------------------------------
  # Core: Axiom
  # ---------------------------------------------------------------------------

  describe "Ontology.Axiom" do
    alias TiannaraRuntime.Mathematics.Ontology.Axiom

    test "new/1 creates a valid axiom" do
      assert {:ok, axiom} = Axiom.new("∀x. x = x")
      assert axiom.statement == "∀x. x = x"
      assert axiom.status == :active
    end

    test "new/2 accepts options" do
      assert {:ok, axiom} = Axiom.new("A ∨ ¬A", axiom_set_id: "set1", status: :active)
      assert axiom.axiom_set_id == "set1"
    end

    test "validate rejects empty statement" do
      assert {:error, _} = Axiom.new("")
    end

    test "id/1 produces deterministic ID" do
      assert {:ok, a} = Axiom.new("∀x. x = x")
      id1 = Axiom.id(a)
      assert {:ok, a2} = Axiom.new("∀x. x = x")
      id2 = Axiom.id(a2)
      assert id1 == id2
      assert String.match?(id1, ~r/^[0-9a-f]{64}$/)
    end
  end

  # ---------------------------------------------------------------------------
  # Core: Definition
  # ---------------------------------------------------------------------------

  describe "Ontology.Definition" do
    alias TiannaraRuntime.Mathematics.Ontology.Definition

    test "new/2 creates a valid definition" do
      assert {:ok, d} = Definition.new("Group", "A set with a binary operation satisfying associativity, identity, invertibility")
      assert d.name == "Group"
    end

    test "validate rejects empty name" do
      assert {:error, _} = Definition.new("", "something")
    end

    test "new/2 with options" do
      assert {:ok, d} = Definition.new("Ring", "A set with two operations", dependencies: ["Group"], introduced_in: "16.X.1")
      assert d.dependencies == ["Group"]
      assert d.introduced_in == "16.X.1"
    end
  end

  # ---------------------------------------------------------------------------
  # Core: Conjecture
  # ---------------------------------------------------------------------------

  describe "Ontology.Conjecture" do
    alias TiannaraRuntime.Mathematics.Ontology.Conjecture

    test "new/1 creates valid conjecture" do
      assert {:ok, c} = Conjecture.new("Every continuous function is differentiable")
      assert c.status == :open
    end

    test "validate rejects confidence out of range" do
      assert {:error, _} = Conjecture.new("test", confidence: 1.5)
    end

    test "id/1 produces deterministic ID" do
      assert {:ok, c1} = Conjecture.new("P = NP")
      assert {:ok, c2} = Conjecture.new("P = NP")
      assert Conjecture.id(c1) == Conjecture.id(c2)
    end
  end

  # ---------------------------------------------------------------------------
  # Core: Theorem
  # ---------------------------------------------------------------------------

  describe "Ontology.Theorem" do
    alias TiannaraRuntime.Mathematics.Ontology.Theorem

    test "new/2 creates valid theorem" do
      assert {:ok, t} = Theorem.new("Riemann-Roch theorem", "abc123")
      assert t.statement == "Riemann-Roch theorem"
      assert t.proof_hash == "abc123"
    end

    test "validate rejects empty proof_hash" do
      assert {:error, _} = Theorem.new("test", "")
    end

    test "id/1 produces deterministic ID" do
      assert {:ok, t1} = Theorem.new("Gödel's incompleteness", "proof1", dependencies: ["Peano"])
      assert {:ok, t2} = Theorem.new("Gödel's incompleteness", "proof1", dependencies: ["Peano"])
      assert Theorem.id(t1) == Theorem.id(t2)
    end
  end

  # ---------------------------------------------------------------------------
  # Core: Proof
  # ---------------------------------------------------------------------------

  describe "Ontology.Proof" do
    alias TiannaraRuntime.Mathematics.Ontology.Proof

    test "new/2 creates valid proof" do
      assert {:ok, p} = Proof.new("conj1", :direct)
      assert p.conjecture_id == "conj1"
      assert p.strategy == :direct
      assert p.verified == false
    end

    test "validate rejects empty conjecture_id" do
      assert {:error, _} = Proof.new("", :direct)
    end

    test "new/2 accepts all five strategies" do
      assert {:ok, _} = Proof.new("c1", :direct)
      assert {:ok, _} = Proof.new("c2", :contradiction)
      assert {:ok, _} = Proof.new("c3", :induction)
      assert {:ok, _} = Proof.new("c4", :constructive)
      assert {:ok, _} = Proof.new("c5", :computational)
    end
  end

  # ---------------------------------------------------------------------------
  # Core: Corollary, Algorithm, Application
  # ---------------------------------------------------------------------------

  describe "Ontology.Corollary" do
    alias TiannaraRuntime.Mathematics.Ontology.Corollary
    test "new/2 with valid args" do
      assert {:ok, c} = Corollary.new("Every finite integral domain is a field", "thm1")
      assert c.parent_theorem_id == "thm1"
    end
    test "rejects empty" do
      assert {:error, _} = Corollary.new("", "thm1")
    end
  end

  describe "Ontology.Algorithm" do
    alias TiannaraRuntime.Mathematics.Ontology.Algorithm
    test "new/2 with valid args" do
      assert {:ok, a} = Algorithm.new("Euclidean GCD", "thm_euclid")
      assert a.name == "Euclidean GCD"
    end
  end

  describe "Ontology.Application" do
    alias TiannaraRuntime.Mathematics.Ontology.Application
    test "new/2 with valid args" do
      assert {:ok, a} = Application.new("Cryptography", "RSA theorem")
      assert a.problem_domain == "Cryptography"
    end
  end

  describe "Ontology.Structure" do
    alias TiannaraRuntime.Mathematics.Ontology.Structure
    test "new/1 creates valid structure" do
      assert {:ok, s} = Structure.new("Group")
      assert s.name == "Group"
    end
  end

  describe "Ontology.Lemma" do
    alias TiannaraRuntime.Mathematics.Ontology.Lemma
    test "new/2 creates valid lemma" do
      assert {:ok, l} = Lemma.new("Zorn's lemma depends on AC", "proof_hash")
      assert l.statement == "Zorn's lemma depends on AC"
    end
  end

  # ---------------------------------------------------------------------------
  # Program: MathematicalProgram, MathematicalExperiment
  # ---------------------------------------------------------------------------

  describe "Ontology.MathematicalProgram" do
    alias TiannaraRuntime.Mathematics.Ontology.MathematicalProgram
    test "new/1 creates valid program" do
      assert {:ok, mp} = MathematicalProgram.new(["Prove Fermat's Last Theorem"])
      assert mp.objectives == ["Prove Fermat's Last Theorem"]
    end
    test "rejects empty objectives" do
      assert {:error, _} = MathematicalProgram.new([])
    end
  end

  describe "Ontology.MathematicalExperiment" do
    alias TiannaraRuntime.Mathematics.Ontology.MathematicalExperiment
    test "new/1 creates valid experiment" do
      assert {:ok, me} = MathematicalExperiment.new("prog1")
      assert me.program_id == "prog1"
    end
  end

  # ---------------------------------------------------------------------------
  # ArchaeologyRecord
  # ---------------------------------------------------------------------------

  describe "Ontology.ArchaeologyRecord" do
    alias TiannaraRuntime.Mathematics.Ontology.ArchaeologyRecord
    test "new/3 creates valid record" do
      assert {:ok, r} = ArchaeologyRecord.new("Phase 16.X.1", "Mathematical ontology", "Constitutional Research Council")
      assert r.origin == "Phase 16.X.1"
    end
    test "rejects empty fields" do
      assert {:error, _} = ArchaeologyRecord.new("", "test", "owner")
    end
  end

  # ---------------------------------------------------------------------------
  # Symbolic: SymbolicExpression, SymbolicRule, RuleSet, DomainRegistration
  # ---------------------------------------------------------------------------

  describe "Ontology.SymbolicExpression" do
    alias TiannaraRuntime.Mathematics.Ontology.SymbolicExpression
    test "new/2 creates valid expression" do
      assert {:ok, e} = SymbolicExpression.new(:constant, 42)
      assert e.value == 42
    end
    test "rejects nil value" do
      assert {:error, _} = SymbolicExpression.new(:constant, nil)
    end
    test "id/1 is deterministic" do
      assert {:ok, e1} = SymbolicExpression.new(:variable, "x")
      assert {:ok, e2} = SymbolicExpression.new(:variable, "x")
      assert SymbolicExpression.id(e1) == SymbolicExpression.id(e2)
    end
  end

  describe "Ontology.SymbolicRule" do
    alias TiannaraRuntime.Mathematics.Ontology.SymbolicRule
    test "new/2 creates valid rule" do
      assert {:ok, r} = SymbolicRule.new("x + 0", "x")
      assert r.pattern == "x + 0"
    end
  end

  describe "Ontology.RuleSet" do
    alias TiannaraRuntime.Mathematics.Ontology.{SymbolicRule, RuleSet}
    test "new/2 creates valid rule set" do
      assert {:ok, r} = SymbolicRule.new("x + 0", "x")
      assert {:ok, rs} = RuleSet.new("algebra_basics", [r])
      assert rs.id == "algebra_basics"
    end
  end

  describe "Ontology.DomainRegistration" do
    alias TiannaraRuntime.Mathematics.Ontology.{SymbolicRule, DomainRegistration}
    test "new/2 creates valid registration" do
      assert {:ok, r} = SymbolicRule.new("x + 0", "x")
      assert {:ok, dr} = DomainRegistration.new(:algebra, [r])
      assert dr.domain == :algebra
    end
  end

  describe "Ontology.RewriteStep" do
    alias TiannaraRuntime.Mathematics.Ontology.{SymbolicExpression, RewriteStep}
    test "new/4 creates valid step" do
      assert {:ok, expr_before} = SymbolicExpression.new(:operator, :+, children: [
        %SymbolicExpression{type: :variable, value: "x", children: [], metadata: %{}},
        %SymbolicExpression{type: :constant, value: 0, children: [], metadata: %{}}
      ])
      assert {:ok, expr_after} = SymbolicExpression.new(:variable, "x")
      assert {:ok, rs} = RewriteStep.new(0, "identity", expr_before, expr_after)
      assert rs.step_number == 0
    end
  end

  describe "Ontology.RewriteLog" do
    alias TiannaraRuntime.Mathematics.Ontology.RewriteLog
    test "rejects empty steps" do
      assert {:error, _} = RewriteLog.new([])
    end
  end

  # ---------------------------------------------------------------------------
  # Proof: ProofStep, ProofStrategy, InferenceRule, AxiomSet, ProofBundle
  # ---------------------------------------------------------------------------

  describe "Ontology.ProofStep" do
    alias TiannaraRuntime.Mathematics.Ontology.ProofStep
    test "new/3 creates valid step" do
      assert {:ok, ps} = ProofStep.new(0, "modus_ponens", "Q", premises: ["P", "P → Q"])
      assert ps.rule_applied == "modus_ponens"
    end
    test "id/1 is deterministic" do
      assert {:ok, ps1} = ProofStep.new(0, "MP", "Q")
      assert {:ok, ps2} = ProofStep.new(0, "MP", "Q")
      assert ProofStep.id(ps1) == ProofStep.id(ps2)
    end
  end

  describe "Ontology.ProofStrategy" do
    alias TiannaraRuntime.Mathematics.Ontology.ProofStrategy
    test "valid returns all five" do
      assert ProofStrategy.valid() == [:direct, :contradiction, :induction, :constructive, :computational]
    end
    test "validates correctly" do
      assert {:ok, :direct} = ProofStrategy.validate(:direct)
      assert {:error, _} = ProofStrategy.validate(:invalid_strategy)
    end
  end

  describe "Ontology.InferenceRule" do
    alias TiannaraRuntime.Mathematics.Ontology.InferenceRule
    test "new/3 creates valid rule" do
      assert {:ok, ir} = InferenceRule.new("modus_ponens", "P, P → Q", "Q")
      assert ir.name == "modus_ponens"
    end
  end

  describe "Ontology.AxiomSet" do
    alias TiannaraRuntime.Mathematics.Ontology.AxiomSet
    test "new/2 creates valid set" do
      assert {:ok, as} = AxiomSet.new("ZFC", ["Extensionality", "Pairing", "Union"])
      assert length(as.axioms) == 3
    end
  end

  describe "Ontology.ProofBundle" do
    alias TiannaraRuntime.Mathematics.Ontology.ProofBundle
    test "new/2 creates valid bundle" do
      assert {:ok, pb} = ProofBundle.new("bundle1", ["proof1", "proof2"])
      assert pb.id == "bundle1"
    end
  end

  # ---------------------------------------------------------------------------
  # Verification: MathematicalAssertion, Counterexample, SystemModel, Config
  # ---------------------------------------------------------------------------

  describe "Ontology.VerificationProperty" do
    alias TiannaraRuntime.Mathematics.Ontology.VerificationProperty
    test "valid returns all six" do
      assert VerificationProperty.valid() == [:correctness, :convergence, :safety, :stability, :consistency, :bounded]
    end
  end

  describe "Ontology.VerificationResult" do
    alias TiannaraRuntime.Mathematics.Ontology.VerificationResult
    test "validates correctly" do
      assert {:ok, :pass} = VerificationResult.validate(:pass)
      assert {:error, _} = VerificationResult.validate(:invalid)
    end
  end

  describe "Ontology.MathematicalAssertion" do
    alias TiannaraRuntime.Mathematics.Ontology.MathematicalAssertion
    test "new/3 creates valid assertion" do
      assert {:ok, ma} = MathematicalAssertion.new(:correctness, "sys1", :pass, proof_hash: "proof1")
      assert ma.property_type == :correctness
    end
    test "pass requires proof_hash" do
      assert {:error, _} = MathematicalAssertion.new(:safety, "sys1", :pass)
    end
    test "fail requires counterexample_hash" do
      assert {:error, _} = MathematicalAssertion.new(:safety, "sys1", :fail)
    end
    test "id/1 is deterministic" do
      assert {:ok, ma1} = MathematicalAssertion.new(:convergence, "sys1", :pass, proof_hash: "proof1")
      assert {:ok, ma2} = MathematicalAssertion.new(:convergence, "sys1", :pass, proof_hash: "proof1")
      assert MathematicalAssertion.id(ma1) == MathematicalAssertion.id(ma2)
    end
  end

  describe "Ontology.Counterexample" do
    alias TiannaraRuntime.Mathematics.Ontology.Counterexample
    test "new/2 creates valid counterexample" do
      assert {:ok, ce} = Counterexample.new("safety", "state where x < 0")
      assert ce.property == "safety"
    end
  end

  describe "Ontology.SystemModel" do
    alias TiannaraRuntime.Mathematics.Ontology.SystemModel
    test "new/2 creates valid model" do
      assert {:ok, sm} = SystemModel.new("model1", "formal specification text")
      assert sm.id == "model1"
    end
  end

  describe "Ontology.BoundedVerificationConfig" do
    alias TiannaraRuntime.Mathematics.Ontology.BoundedVerificationConfig
    test "new/1 creates valid config" do
      assert {:ok, bc} = BoundedVerificationConfig.new(100)
      assert bc.max_steps == 100
    end
    test "rejects confidence out of range" do
      assert {:error, _} = BoundedVerificationConfig.new(100, confidence: 1.5)
    end
  end

  # ---------------------------------------------------------------------------
  # Cross-module integration
  # ---------------------------------------------------------------------------

  describe "cross-module integration" do
    test "Axiom, Theorem, Proof form a chain" do
      alias TiannaraRuntime.Mathematics.Ontology.{Axiom, Theorem, Proof}
      assert {:ok, _axiom} = Axiom.new("Axiom of Choice")
      assert {:ok, _thm} = Theorem.new("Zorn's Lemma", "proof_abc")
      assert {:ok, _proof} = Proof.new("conj_zorn", :contradiction)
    end

    test "MathematicsEngine interface sketch compiles" do
      # Structural verification that types compose
      alias TiannaraRuntime.Mathematics.Ontology.MathematicalAssertion
      assert {:ok, _ma} = MathematicalAssertion.new(:correctness, "sys_hash", :pass, proof_hash: "proof_hash")
    end

    test "ArchaeologyRecord can reference any math artifact" do
      alias TiannaraRuntime.Mathematics.Ontology.ArchaeologyRecord
      assert {:ok, _r} = ArchaeologyRecord.new("Proof Engine", "Verify correctness", "CRC",
        dependencies: ["thm1", "axiom1"], lineage: ["v1"])
    end
  end
end
