defmodule TiannaraRuntime.CausalDiscovery.CausalArchaeologyTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.CausalDiscovery.CausalArchaeology

  describe "new/1" do
    test "creates valid CausalArchaeology with model_id and empty entries" do
      {:ok, ca} = CausalArchaeology.new(model_id: "graph_123", entries: [])
      assert ca.model_id == "graph_123"
      assert ca.entries == []
      assert String.starts_with?(ca.archaeology_id, "ca_")
    end
  end

  describe "validate/1" do
    test "validates a valid struct" do
      {:ok, ca} = CausalArchaeology.new(model_id: "graph_123", entries: [])
      assert {:ok, _} = CausalArchaeology.validate(ca)
    end

    test "rejects empty model_id" do
      ca = %CausalArchaeology{model_id: "", entries: []}
      assert {:error, _} = CausalArchaeology.validate(ca)
    end

    test "rejects nil model_id" do
      ca = %CausalArchaeology{model_id: nil, entries: []}
      assert {:error, _} = CausalArchaeology.validate(ca)
    end

    test "rejects entries not a list" do
      ca = %CausalArchaeology{model_id: "graph_123", entries: :not_a_list}
      assert {:error, _} = CausalArchaeology.validate(ca)
    end

    test "rejects non-struct input" do
      assert {:error, _} = CausalArchaeology.validate(%{})
    end
  end
end
