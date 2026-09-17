defmodule Tiannara.Repro.ManifestTest do
  use ExUnit.Case, async: true

  alias Tiannara.Repro.{Manifest, ArtifactBundle, Verdict}

  test "capture uses real runtime introspection" do
    m = Manifest.capture("exp-001")
    assert is_binary(m.elixir_version)
    assert is_binary(m.otp_version)
    assert is_binary(m.os)
  end

  test "config_hash is deterministic across key insertion order" do
    m1 = Manifest.capture("exp-001", seed: 42, dataset_identifiers: ["ds1"])
    m2 = Manifest.capture("exp-001", dataset_identifiers: ["ds1"], seed: 42)
    assert Manifest.config_hash(m1) == Manifest.config_hash(m2)
  end

  test "config_hash differs when seed differs" do
    m1 = Manifest.capture("exp-001", seed: 1)
    m2 = Manifest.capture("exp-001", seed: 2)
    refute Manifest.config_hash(m1) == Manifest.config_hash(m2)
  end

  test "identical runs -> :reproduced" do
    m = Manifest.capture("exp-001", seed: 7)
    a = ArtifactBundle.new(m, %{discoveries: 3})
    b = ArtifactBundle.new(m, %{discoveries: 3})
    assert %Verdict{verdict: :reproduced} = Verdict.compare(a, b)
  end

  test "same inputs, different outcomes -> :divergent" do
    m = Manifest.capture("exp-001", seed: 7)
    a = ArtifactBundle.new(m, %{discoveries: 3})
    b = ArtifactBundle.new(m, %{discoveries: 0})
    assert %Verdict{verdict: :divergent, diffs: [_ | _]} = Verdict.compare(a, b)
  end

  test "different inputs -> :inconclusive" do
    a = ArtifactBundle.new(Manifest.capture("exp-001", seed: 1), %{discoveries: 3})
    b = ArtifactBundle.new(Manifest.capture("exp-001", seed: 2), %{discoveries: 3})
    assert %Verdict{verdict: :inconclusive} = Verdict.compare(a, b)
  end
end
