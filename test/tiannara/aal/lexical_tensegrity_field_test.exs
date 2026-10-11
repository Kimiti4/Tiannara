defmodule Tiannara.AAL.LexicalTensegrityFieldTest do
  use ExUnit.Case, async: true

  alias Tiannara.AAL.LexicalTensegrityField

  test "does not invent an intent or engineering route for empty input" do
    assert {:unknown, []} = LexicalTensegrityField.map_intent_vectors("")
  end

  test "returns unknown when no supported action is expressed" do
    assert {:unknown, _domains} = LexicalTensegrityField.map_intent_vectors("hello there")
  end

  test "classifies one explicit action family" do
    assert {:analysis, _domains} =
             LexicalTensegrityField.map_intent_vectors("Analyze this engineering system")
  end

  test "marks requests spanning multiple action families as ambiguous" do
    assert {:ambiguous, _domains} =
             LexicalTensegrityField.map_intent_vectors("Analyze and optimize this system")
  end

  test "does not match action terms as substrings" do
    assert {:unknown, _domains} =
             LexicalTensegrityField.map_intent_vectors("the builder is waiting")
  end
end
