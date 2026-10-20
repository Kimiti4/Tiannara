defmodule TiannaraRuntime.CausalDiscovery.ArchaeologyEntryTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.CausalDiscovery.ArchaeologyEntry

  describe "new/1" do
    test "creates valid ArchaeologyEntry with stage and description" do
      {:ok, ae} = ArchaeologyEntry.new(stage: :scoring, description: "Computed scores")
      assert ae.stage == :scoring
      assert ae.description == "Computed scores"
      assert String.starts_with?(ae.entry_id, "ae_")
    end
  end

  describe "validate/1" do
    test "validates a valid struct" do
      {:ok, ae} = ArchaeologyEntry.new(stage: :scoring, description: "test")
      assert {:ok, _} = ArchaeologyEntry.validate(ae)
    end

    test "rejects nil stage" do
      ae = %ArchaeologyEntry{stage: nil, description: "desc"}
      assert {:error, _} = ArchaeologyEntry.validate(ae)
    end

    test "rejects empty description" do
      ae = %ArchaeologyEntry{stage: :scoring, description: ""}
      assert {:error, _} = ArchaeologyEntry.validate(ae)
    end

    test "rejects nil description" do
      ae = %ArchaeologyEntry{stage: :scoring, description: nil}
      assert {:error, _} = ArchaeologyEntry.validate(ae)
    end

    test "rejects confidence below 0.0" do
      ae = %ArchaeologyEntry{stage: :scoring, description: "desc", confidence: -0.1}
      assert {:error, _} = ArchaeologyEntry.validate(ae)
    end

    test "rejects confidence above 1.0" do
      ae = %ArchaeologyEntry{stage: :scoring, description: "desc", confidence: 1.5}
      assert {:error, _} = ArchaeologyEntry.validate(ae)
    end

    test "rejects non-struct input" do
      assert {:error, _} = ArchaeologyEntry.validate(%{})
    end
  end
end
