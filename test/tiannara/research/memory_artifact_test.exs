defmodule Tiannara.Research.MemoryArtifactTest do
  use ExUnit.Case, async: true

  alias Tiannara.Research.Memory.Artifact

  @moduletag :research_memory_contract

  test "promotion requires evidence for knowledge and above" do
    artifact = Artifact.new(:a1, :information, "some info", confidence: 0.5)

    assert {:error, :insufficient_evidence} = Artifact.promote(artifact, :knowledge)

    artifact = %{artifact | evidence: [:e1]}
    assert {:ok, promoted} = Artifact.promote(artifact, :knowledge)
    assert promoted.memory_stage == :knowledge
  end

  test "promotion must be upward" do
    artifact = Artifact.new(:a1, :knowledge, "k", evidence: [:e], confidence: 0.5)
    assert {:error, :must_promote_upward} = Artifact.promote(artifact, :information)
  end

  test "principles require no unresolved contradictions" do
    artifact =
      Artifact.new(:a1, :models, "m",
        evidence: [:e], confidence: 0.7, contradictions: [{:c1}])

    assert {:error, :unresolved_contradictions} = Artifact.promote(artifact, :principles)
  end

  test "high stages require high confidence" do
    artifact = Artifact.new(:a1, :principles, "p", evidence: [:e], confidence: 0.4)

    assert {:error, {:insufficient_confidence, _, _}} =
             Artifact.promote(artifact, :scientific_discovery)
  end
end