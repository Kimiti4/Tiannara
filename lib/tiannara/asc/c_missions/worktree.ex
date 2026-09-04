defmodule Tiannara.ASC.CMissions.Worktree do
  @moduledoc """
  Isolated Git worktree sandbox for C4 implementation.

  Strict boundary: the sandbox lives outside the repository, on its own
  branch, and is destroyed after validation. The runner has no production
  write, merge, or deployment authority — nothing in this module touches
  the working branch of the main repository.

  Because the main repository carries large uncommitted state (this repo's
  working tree is not committed between missions), the sandbox is created
  at HEAD and then mirrored with the main working tree so the candidate
  builds against the real current sources and config. Mirroring is
  whitelist-based (lib, test, config, mix.*, deps, priv minus priv/asc),
  skips symlinks/junctions (loop safety), and never copies junk trees
  (logs, data, runtime bundles, binaries, ...).
  """

  @junk ["nul", "-p", "asc-sandbox-"]

  @whitelist ["lib", "test", "config", "deps", "priv", "mix.exs", "mix.lock", ".formatter.exs"]

  def create(branch_name) do
    root = File.cwd!()
    sandbox_path = Path.join(root, "../asc-sandbox-#{branch_name}")

    destroy(sandbox_path)
    drop_branch(root, branch_name)

    IO.puts("  [C4] Creating isolated worktree: #{sandbox_path} (branch #{branch_name})")

    {_, 0} =
      System.cmd(
        "git",
        ["worktree", "add", "-b", branch_name, sandbox_path, "HEAD"],
        cd: root,
        stderr_to_stdout: true
      )

    mirror_working_tree(sandbox_path)

    unless File.exists?(Path.join(sandbox_path, "mix.exs")) do
      raise "sandbox creation failed: mix.exs missing in #{sandbox_path}"
    end

    %{path: sandbox_path, branch: branch_name}
  end

  def destroy(sandbox_path) do
    if File.dir?(sandbox_path) do
      root = File.cwd!()

      case System.cmd("git", ["worktree", "remove", "--force", sandbox_path],
             cd: root,
             stderr_to_stdout: true
           ) do
        {_out, 0} -> :ok
        _ -> File.rm_rf!(sandbox_path)
      end

      System.cmd("git", ["worktree", "prune"], cd: root, stderr_to_stdout: true)
    end
  end

  defp drop_branch(root, branch_name) do
    {out, 0} = System.cmd("git", ["branch", "--list", branch_name], cd: root)
    if String.trim(out) != "", do: System.cmd("git", ["branch", "-D", branch_name], cd: root)
  end

  defp mirror_working_tree(sandbox_path) do
    root = File.cwd!()

    {:ok, entries} = File.ls(root)

    for entry <- entries do
      name = entry_name(entry)

      if copyable?(name) do
        src = Path.join(root, entry)
        dst = Path.join(sandbox_path, entry)

        if name == "priv" do
          mirror_priv(src, dst)
        else
          copy_entry(src, dst)
        end
      end
    end
  end

  defp copyable?(name) do
    name in @whitelist and name not in @junk and
      not String.starts_with?(name, "asc-sandbox-") and not String.starts_with?(name, "~c")
  end

  defp entry_name(entry) when is_binary(entry), do: entry

  defp entry_name(entry) when is_list(entry) do
    try do
      List.to_string(entry)
    rescue
      _ -> "~c#{inspect(entry)}"
    end
  end

  defp mirror_priv(src, dst) do
    {:ok, entries} = File.ls(src)

    for entry <- entries, entry_name(entry) != "asc" do
      copy_entry(Path.join(src, entry), Path.join(dst, entry))
    end
  end

  defp copy_entry(src, dst) do
    try do
      case File.lstat(src) do
        {:ok, %File.Stat{type: :symlink}} ->
          :skip

        _ ->
          if File.dir?(src) do
            File.mkdir_p!(dst)

            case File.ls(src) do
              {:ok, entries} ->
                for entry <- entries do
                  copy_entry(Path.join(src, entry), Path.join(dst, entry))
                end

              _ ->
                :ok
            end
          else
            File.cp!(src, dst)
          end
      end
    rescue
      _e -> :skip
    end
  end
end