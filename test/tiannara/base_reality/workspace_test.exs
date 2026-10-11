defmodule Tiannara.BaseReality.WorkspaceTest do
  use ExUnit.Case, async: false

  alias Tiannara.BaseReality.Workspace

  setup do
    root = Path.join(System.tmp_dir!(), "tiannara-workspace-test-#{System.unique_integer([:positive])}")
    previous = Application.get_env(:tiannara, :workspace_path)
    Application.put_env(:tiannara, :workspace_path, root)

    on_exit(fn ->
      File.rm_rf(root)

      if is_nil(previous) do
        Application.delete_env(:tiannara, :workspace_path)
      else
        Application.put_env(:tiannara, :workspace_path, previous)
      end
    end)

    {:ok, root: root}
  end

  test "writes validated artifacts and reports that no Git commit occurred", %{root: root} do
    blueprint = %{
      domain: :engineering,
      status: :success,
      schematics: "module sample; endmodule"
    }

    assert {:ok, result} = Workspace.write_blueprints([blueprint], :synthesis)
    assert result.status == :artifacts_written
    assert result.source_control == :not_committed
    assert String.starts_with?(result.directory, root)
    assert result.files == ["engineering_schematic.v"]
    assert File.read!(Path.join(result.directory, "engineering_schematic.v")) == blueprint.schematics
    assert is_binary(result.manifest_sha256)
    assert byte_size(result.manifest_sha256) == 64
  end

  test "removes partial artifacts after a file collision", %{root: root} do
    blueprint = %{
      domain: :engineering,
      status: :success,
      schematics: "module sample; endmodule"
    }

    assert {:error, {:artifact_write_failed, "engineering_schematic.v", :eexist}} =
             Workspace.write_blueprints([blueprint, blueprint], :synthesis)

    assert File.ls!(root) == []
  end

  test "refuses empty or invalid blueprint sets" do
    assert {:error, :no_validated_blueprints} = Workspace.write_blueprints([], :synthesis)
    assert {:error, :unvalidated_blueprint} =
             Workspace.write_blueprints([%{status: :failed, reason: :timeout}], :synthesis)
  end
end
