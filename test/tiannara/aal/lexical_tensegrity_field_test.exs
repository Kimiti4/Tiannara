defmodule Tiannara.AAL.LexicalTensegrityFieldTest do
  use ExUnit.Case, async: true

  alias Tiannara.AAL.LexicalTensegrityField

  test "does not invent an engineering route when no domain matches" do
    assert {_intent, []} = LexicalTensegrityField.map_intent_vectors("")
  end
end
