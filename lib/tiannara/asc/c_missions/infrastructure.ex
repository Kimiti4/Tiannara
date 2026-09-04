defmodule Tiannara.ASC.CMissions.Infrastructure do
  @moduledoc """
  Stable infrastructure shared by C-mission runners (v3+).

  Behaviors are extracted from RunnerV2 (v2 itself stays byte-identical;
  deduplication of v2 is recorded tech debt, not done here). All sandbox,
  patch, bench, and gate behaviors live here so later runners reuse them:

    - fresh_worktree/1, destroy_worktree/1 — mirror worktree sandbox
    - apply_patch/2 — bounded exact-once patch engine (EOL-adaptive, loud drift)
    - commit_candidate/3 — selective commit of whitelisted paths
    - compile_arm/1 — MIX_ENV=test compile
    - correctness/2 — scoped mix test gate (NEVER the full suite)
    - bench!/3 — env-driven benchmark run producing an eterm
    - rotate/2, sha256_file/1, sha256_bytes/1, git_rev/2
  """

  alias Tiannara.ASC.CMissions.Worktree

  # ---- sandbox lifecycle --------------------------------------------------------

  def fresh_worktree(name), do: Worktree.create(name)
  def destroy_worktree(path), do: Worktree.destroy(path)

  # ---- bounded patch engine (exact-once anchors, loud drift, syntax-verified) ---

  @doc """
  Applies a candidate's file ops as working-tree changes in `wt`.
  Anchors must occur exactly once in the (EOL-adapted) source; the result
  must parse. Returns :ok or {:error, reason}.
  """
  def apply_patch(wt, cand) do
    Enum.reduce_while(cand.files, :ok, fn %{path: rel, ops: ops}, :ok ->
      path = Path.join(wt, rel)

      if File.exists?(path) do
        src = File.read!(path)

        {src, ops} =
          if String.contains?(src, "\r\n") do
            adapted =
              Enum.map(ops, fn {a, r} ->
                {String.replace(a, "\n", "\r\n"), String.replace(r, "\n", "\r\n")}
              end)

            {src, adapted}
          else
            {src, ops}
          end

        result =
          Enum.reduce_while(ops, {:ok, src}, fn {anchor, replacement}, {:ok, acc} ->
            if occurrences(acc, anchor) == 1 do
              {:cont, {:ok, String.replace(acc, anchor, replacement, global: false)}}
            else
              {:halt,
               {:error,
                {:shape_drift, rel, String.slice(anchor, 0, 60), occurrences(acc, anchor)}}}
            end
          end)

        case result do
          {:ok, new_src} ->
            case Code.string_to_quoted(new_src) do
              {:ok, _} ->
                File.write!(path, new_src)
                {:cont, :ok}

              {:error, e} ->
                {:halt, {:error, {:syntax_invalid, rel, inspect(e)}}}
            end

          {:error, _} = e ->
            {:halt, e}
        end
      else
        {:halt, {:error, {:shape_drift, rel, :file_missing}}}
      end
    end)
  end

  defp occurrences(src, anchor) do
    if anchor == "" do
      0
    else
      div(
        String.length(src) - String.length(String.replace(src, anchor, "")),
        String.length(anchor)
      )
    end
  end

  # ---- commit + compile ----------------------------------------------------------

  def commit_candidate(wt, cand_id, paths, mission_id) do
    existing = Enum.filter(paths, fn p -> File.exists?(Path.join(wt, p)) end)

    case System.cmd("git", ["-C", wt, "add", "--"] ++ existing, stderr_to_stdout: true) do
      {_, 0} ->
        case System.cmd(
               "git",
               ["-C", wt, "commit", "-m", "#{mission_id} candidate #{cand_id} (sandboxed, automated)"],
               stderr_to_stdout: true
             ) do
          {_, 0} -> :ok
          {out, _} -> {:commit_failed, String.slice(out, 0, 200)}
        end

      {out, _} ->
        {:commit_failed, String.slice(out, 0, 200)}
    end
  end

  def compile_arm(wt) do
    {_, 0} =
      System.cmd("mix", ["compile"], cd: wt, env: [{"MIX_ENV", "test"}], stderr_to_stdout: true)

    :ok
  end

  # ---- correctness gate (scoped paths only; never the full suite) ---------------

  @doc """
  Runs `mix test <paths> --no-start` in the arm. Returns {status, summary}
  where status is :pass or :fail. Summary is %{passed:, failed:} or
  %{passed: 0, failed: -1} if the output could not be parsed.
  """
  def correctness(wt, paths) do
    {output, exit_code} =
      System.cmd("mix", ["test"] ++ paths ++ ["--no-start"],
        cd: wt,
        env: [{"MIX_ENV", "test"}],
        stderr_to_stdout: true
      )

    summary =
      case Regex.run(~r/(\d+) tests?, (\d+) failures?/, output) do
        [_, p, f] -> %{passed: String.to_integer(p), failed: String.to_integer(f)}
        _ -> %{passed: 0, failed: -1}
      end

    {if(exit_code == 0 and summary.failed == 0, do: :pass, else: :fail), summary}
  end

  # ---- bench ---------------------------------------------------------------------

  @doc """
  Runs the arm's bench script via `mix run --no-start` with env arguments
  (mix run argv semantics are avoided). Mission carries the env-var names.
  Returns the decoded eterm written to `out_path`.
  """
  def bench!(wt, mission, out_path) do
    archive = Path.expand(mission.archive_rel)

    env =
      Enum.map(mission.bench_env, fn {key, var} ->
        value =
          case key do
            :archive -> archive
            :n -> "#{mission.n_per_run}"
            :warm -> "#{mission.warm_per_call}"
            :out -> out_path
          end

        {var, value}
      end) ++ [{"MIX_ENV", "test"}]

    {output, status} =
      System.cmd("mix", ["run", "--no-start", mission.bench_rel],
        cd: wt,
        env: env,
        stderr_to_stdout: true
      )

    cond do
      status != 0 -> raise "bench failed in #{wt}:\n#{String.slice(output, 0, 800)}"
      String.contains?(output, "BENCH_ABORT") -> raise "bench aborted in #{wt}:\n#{output}"
      true -> :erlang.binary_to_term(File.read!(out_path))
    end
  end

  # ---- utils ----------------------------------------------------------------------

  def rotate(list, k), do: Enum.drop(list, k) ++ Enum.take(list, k)

  def sha256_file(path), do: sha256_bytes(File.read!(path))
  def sha256_bytes(bin), do: :crypto.hash(:sha256, bin) |> Base.encode16(case: :lower)

  def git_rev(root, ref) do
    case System.cmd("git", ["-C", root, "rev-parse", ref], stderr_to_stdout: true) do
      {sha, 0} -> String.trim(sha)
      _ -> :unknown
    end
  end
end