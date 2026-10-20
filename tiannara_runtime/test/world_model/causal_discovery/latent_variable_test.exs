defmodule TiannaraRuntime.CausalDiscovery.LatentVariableTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.CausalDiscovery.LatentVariable

  describe "new/1" do
    test "creates valid LatentVariable with manifest_variables" do
      {:ok, lv} = LatentVariable.new(manifest_variables: ["x", "y"])
      assert lv.manifest_variables == ["x", "y"]
      assert lv.confidence == 0.5
      assert lv.detection_method == :residual_correlation
      assert String.starts_with?(lv.latent_id, "lv_")
    end

    test "creates with custom confidence and detection_method" do
      {:ok, lv} = LatentVariable.new(manifest_variables: ["a", "b", "c"], confidence: 0.8, detection_method: :mediation_gap)
      assert lv.confidence == 0.8
      assert lv.detection_method == :mediation_gap
    end
  end

  describe "validate/1" do
    test "validates a valid struct" do
      {:ok, lv} = LatentVariable.new(manifest_variables: ["x", "y"])
      assert {:ok, _} = LatentVariable.validate(lv)
    end

    test "rejects manifest_variables with length 0" do
      lv = %LatentVariable{manifest_variables: []}
      assert {:error, _} = LatentVariable.validate(lv)
    end

    test "rejects manifest_variables with length 1" do
      lv = %LatentVariable{manifest_variables: ["x"]}
      assert {:error, _} = LatentVariable.validate(lv)
    end

    test "rejects confidence below 0.0" do
      lv = %LatentVariable{manifest_variables: ["x", "y"], confidence: -0.1}
      assert {:error, _} = LatentVariable.validate(lv)
    end

    test "rejects confidence above 1.0" do
      lv = %LatentVariable{manifest_variables: ["x", "y"], confidence: 1.5}
      assert {:error, _} = LatentVariable.validate(lv)
    end

    test "rejects invalid detection_method" do
      lv = %LatentVariable{manifest_variables: ["x", "y"], detection_method: :invalid}
      assert {:error, _} = LatentVariable.validate(lv)
    end

    test "rejects non-struct input" do
      assert {:error, _} = LatentVariable.validate(%{})
    end
  end
end
