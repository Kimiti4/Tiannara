defmodule TiannaraRuntime.CausalDiscovery.DiscoveryEvidenceTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.CausalDiscovery.DiscoveryEvidence

  describe "new/1" do
    test "creates valid DiscoveryEvidence with stage" do
      {:ok, de} = DiscoveryEvidence.new(stage: :independence)
      assert de.stage == :independence
      assert String.starts_with?(de.discovery_id, "de_")
      assert de.created_at =~ ~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/
    end

    test "rejects invalid stage atom" do
      assert {:error, _} = DiscoveryEvidence.new(stage: :invalid_stage)
    end
  end

  describe "validate/1" do
    test "validates a valid struct" do
      {:ok, de} = DiscoveryEvidence.new(stage: :skeleton)
      assert {:ok, _} = DiscoveryEvidence.validate(de)
    end

    test "rejects invalid stage" do
      de = %DiscoveryEvidence{stage: :bad_stage}
      assert {:error, _} = DiscoveryEvidence.validate(de)
    end

    test "rejects empty output_root" do
      de = %DiscoveryEvidence{stage: :independence, output_root: ""}
      assert {:error, _} = DiscoveryEvidence.validate(de)
    end

    test "rejects non-struct input" do
      assert {:error, _} = DiscoveryEvidence.validate(%{})
    end
  end
end
