defmodule TiannaraRuntime.CausalDiscovery.SkeletonTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.CausalDiscovery.Skeleton

  describe "new/1" do
    test "creates valid Skeleton with nodes list" do
      {:ok, s} = Skeleton.new(nodes: ["x", "y", "z"])
      assert s.nodes == ["x", "y", "z"]
      assert String.starts_with?(s.skeleton_id, "sk_")
    end

    test "fails on empty nodes" do
      assert {:error, _} = Skeleton.new(nodes: [])
    end

    test "fails when nodes is not a list" do
      assert {:error, _} = Skeleton.new(nodes: "not_a_list")
    end

    test "valid with adjacency map where keys match nodes" do
      {:ok, s} = Skeleton.new(nodes: ["x", "y"], adjacency: %{"x" => ["y"], "y" => ["x"]})
      assert s.adjacency == %{"x" => ["y"], "y" => ["x"]}
    end

    test "fails when adjacency key is not in nodes" do
      assert {:error, _} = Skeleton.new(nodes: ["x"], adjacency: %{"z" => ["x"]})
    end
  end

  describe "validate/1" do
    test "returns {:ok, struct} for valid Skeleton" do
      s = %Skeleton{nodes: ["x", "y"], adjacency: %{}}
      assert {:ok, _} = Skeleton.validate(s)
    end

    test "fails for invalid Skeleton" do
      s = %Skeleton{nodes: []}
      assert {:error, _} = Skeleton.validate(s)
    end
  end

  describe "compute_id/1" do
    test "returns string starting with sk_" do
      {:ok, s} = Skeleton.new(nodes: ["a", "b"])
      id = Skeleton.compute_id(s)
      assert String.starts_with?(id, "sk_")
    end
  end
end
