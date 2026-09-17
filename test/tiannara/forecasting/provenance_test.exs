defmodule Tiannara.Forecasting.ProvenanceTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.{Signal, Provenance}

  describe "content_hash/1" do
    test "is deterministic and reproducible" do
      a = Signal.new(source: :market, observation: [1, 2, 3])
      b = Signal.new(source: :market, observation: [1, 2, 3])
      assert Provenance.content_hash(a) == Provenance.content_hash(b)
    end

    test "differs for different observations" do
      a = Signal.new(source: :market, observation: [1, 2, 3])
      b = Signal.new(source: :market, observation: [1, 2, 4])
      refute Provenance.content_hash(a) == Provenance.content_hash(b)
    end
  end

  describe "build/1" do
    test "builds provenance from signal fields" do
      s = Signal.new(source: :market, observation: 0.1)
      p = Provenance.build(s)
      assert p.kind == :observation
      assert is_binary(p.sha256)
      assert p.source == :market
      assert p.transformation_history == []
      assert p.lineage == []
    end

    test "reflects derived signals with lineage" do
      original = Signal.new(source: :market, observation: 0.1)
      derived = Signal.version(original, observation: 0.2)
      p = Provenance.build(derived)
      assert p.kind == :derived
      assert original.id in p.lineage
    end
  end

  describe "integrity?/1" do
    test "true when stored provenance matches recomputed hash" do
      s = Signal.new(source: :market, observation: 0.1, provenance: %{kind: :observation})
      assert Provenance.integrity?(s)
    end

    test "true when no stored hash (cannot disprove)" do
      s = Signal.new(source: :market, observation: 0.1)
      assert Provenance.integrity?(s)
    end
  end

  describe "valid?/1" do
    test "accepts a well-formed provenance map" do
      assert Provenance.valid?(%{kind: :observation, sha256: "abc"})
    end

    test "rejects nil and malformed maps" do
      refute Provenance.valid?(nil)
      refute Provenance.valid?(%{kind: :bad_kind, sha256: "abc"})
      refute Provenance.valid?(%{kind: :observation})
    end
  end

  describe "derived?/1" do
    test "true for derived kind or lineage" do
      assert Provenance.derived?(%{kind: :derived})
      assert Provenance.derived?(%{lineage: ["a", "b"]})
      refute Provenance.derived?(%{kind: :observation, lineage: []})
      refute Provenance.derived?(nil)
    end
  end
end
