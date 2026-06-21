defmodule Tiannara.BaseReality.Workspace do
  @moduledoc "Bridges the simulation output directly into the human developer's IDE."

  @workspace_path "c:/Users/user/Tiannara/Deployments/"

  @spec commit_blueprints([map()], atom()) :: String.t()
  def commit_blueprints(blueprints, intent) do
    timestamp = System.system_time(:second)
    deployment_dir = Path.join(@workspace_path, "synthesis_#{timestamp}")
    File.mkdir_p!(deployment_dir)

    # 1. Write the extracted schematics to actual files
    Enum.each(blueprints, fn 
      %{status: :failed} -> :skip
      bp ->
        file_path = Path.join(deployment_dir, "#{bp.domain}_schematic.v")
        File.write!(file_path, bp.schematics)
    end)

    # 2. Execute local Git commands to commit the code autonomously
    System.cmd("git", ["init"], cd: deployment_dir, stderr_to_stdout: true)
    System.cmd("git", ["add", "."], cd: deployment_dir)
    System.cmd("git", ["commit", "-m", "Tiannara Auto-Synthesis: #{intent}"], cd: deployment_dir)

    # 3. CRITICAL FIX: Extract the actual short hash safely 
    # (git commit stdout includes the whole log line, not just the hash)
    {hash_output, 0} = System.cmd("git", ["rev-parse", "--short", "HEAD"], cd: deployment_dir)
    String.trim(hash_output)
  rescue
    e ->
      require Logger
      Logger.error("❌ Workspace commit failed: #{inspect(e)}")
      "error-#{System.system_time(:second)}"
  end
end
