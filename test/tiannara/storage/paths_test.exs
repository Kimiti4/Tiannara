defmodule Tiannara.Storage.PathsTest do
  use ExUnit.Case, async: false

  alias Tiannara.Storage.Paths

  test "test context never resolves into the production tree" do
    assert Paths.context() == :test

    checkpoint = Paths.path("checkpoints/latest.json")
    assert String.ends_with?(checkpoint, Path.join(["test", "checkpoints/latest.json"]))
    refute String.starts_with?(checkpoint, "data/production/")
    refute String.starts_with?(checkpoint, "dev_data/")
    refute String.contains?(checkpoint, "soak")
    # D-A5: active base is the per-run test isolation root, not the shared data/
    assert String.starts_with?(checkpoint, Paths.base())
    assert String.contains?(checkpoint, "test_data")
  end

  test "explicit contexts resolve to distinct trees under the active base" do
    production = Paths.path(:production, "x.json")
    soak = Paths.path(:soak, "x.json")
    test = Paths.path(:test, "x.json")

    assert production == Path.join([Paths.base(), "production", "x.json"])
    assert soak == Path.join([Paths.base(), "soak", "x.json"])
    assert test == Path.join([Paths.base(), "test", "x.json"])

    refute production == soak
    refute production == test
    refute soak == test

    # Context segment remains the isolation key even under a per-run base.
    assert String.contains?(production, "/production/") or
             String.contains?(production, "\\production\\")
  end

  test "unknown context raises instead of writing anywhere" do
    assert_raise ArgumentError, fn -> Paths.path(:unknown_ctx, "x.json") end
  end

  test "checkpointer writes inside the test tree only, never production" do
    production_file = Paths.path(:production, "checkpoints/latest.json")
    File.rm(production_file)
    refute File.exists?(production_file)

    assert Tiannara.CRAV.SoakCheckpointer.save(%{probe: 1}) == :ok

    assert File.exists?(Paths.path("checkpoints/latest.json"))
    refute File.exists?(production_file)

    File.rm(Paths.path("checkpoints/latest.json"))
  end

  test "soak artifacts resolve under the soak context for the server" do
    assert Paths.path(:soak, "checkpoints/latest.json") ==
             Path.join([Paths.base(), "soak", "checkpoints/latest.json"])

    assert Paths.path(:soak, "logs/") == Path.join([Paths.base(), "soak", "logs"])

    assert Paths.path(:soak, "soak_final_report.json") ==
             Path.join([Paths.base(), "soak", "soak_final_report.json"])
  end
end
