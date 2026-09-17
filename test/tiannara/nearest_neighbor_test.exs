defmodule Tiannara.NearestNeighborTest do
  use ExUnit.Case, async: true

  alias Tiannara.NearestNeighbor

  @artifacts [
    %{artifact_id: :a, embedding: %{x: 1.0, y: 0.0}},
    %{artifact_id: :b, embedding: %{x: 0.0, y: 1.0}},
    %{artifact_id: :c, embedding: %{x: 0.7, y: 0.7}}
  ]

  test "find/2 returns the closest artifact by Euclidean distance" do
    nearest = NearestNeighbor.find(%{x: 1.0, y: 0.1}, @artifacts)
    assert nearest.artifact_id == :a
    assert_in_delta nearest.distance, 0.1, 1.0e-9
  end

  test "empty corpus returns nil" do
    assert NearestNeighbor.find(%{x: 1.0}, []) == nil
  end

  test "non-list corpus returns nil" do
    assert NearestNeighbor.find(%{x: 1.0}, :not_a_corpus) == nil
  end
end