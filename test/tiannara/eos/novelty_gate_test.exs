defmodule Tiannara.EOS.Constitution.NoveltyGateTest do
  use ExUnit.Case, async: true

  test "folds a candidate into the nearest artifact when close enough" do
    candidate = %{embedding: %{value: 1.05}, evidence: %{source: :test}}
    existing = [%{artifact_id: "artifact-1", embedding: %{value: 1.0}}]

    assert {:fold_into_existing, "artifact-1", %{source: :test}} =
             Tiannara.EOS.Constitution.NoveltyGate.route_candidate(candidate, existing)
  end

  test "mints a new artifact when the candidate is beyond threshold" do
    candidate = %{embedding: %{value: 5.0}, evidence: %{source: :test}}
    existing = [%{artifact_id: "artifact-1", embedding: %{value: 1.0}}]

    assert {:mint_new, %{embedding: %{value: 5.0}}} =
             Tiannara.EOS.Constitution.NoveltyGate.route_candidate(candidate, existing)
  end
end
