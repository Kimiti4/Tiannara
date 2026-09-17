defmodule Tiannara.Storage.PathsTest do
  use ExUnit.Case, async: false

  alias Tiannara.Storage.Paths

  test "test context never resolves into the production tree" do
    assert Paths.context() == :test

    checkpoint = Paths.path("checkpoints/latest.json")
    assert checkpoint == "data/test/checkpoints/latest.json"
    refute String.starts_with?(checkpoint, "data/production/")
    refute String.contains?(checkpoint, "soak")
  end

  test "explicit contexts resolve to distinct trees" do
    assert Paths.path(:production, "x.json") == "data/production/x.json"
    assert Paths.path(:soak, "x.json") == "data/soak/x.json"
    assert Paths.path(:test, "x.json") == "data/test/x.json"
    refute Paths.path(:production, "x.json") == Paths.path(:soak, "x.json")
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
    assert Paths.path(:soak, "checkpoints/latest.json") == "data/soak/checkpoints/latest.json"
    assert Paths.path(:soak, "logs/") == "data/soak/logs"
    assert Paths.path(:soak, "soak_final_report.json") == "data/soak/soak_final_report.json"
  end
end
