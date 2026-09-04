defmodule Tiannara.SelfImprovement.Sandbox.Backend.Local do
  @moduledoc """
  Local-filesystem sandbox backend (the lightest REAL backend).

  It copies the baseline into a throwaway workdir, applies the patch there, and
  runs real commands via `System.cmd` with timeouts. The baseline is never
  mutated and teardown removes the workdir.

  Use this for dev / single-host CI. For stronger isolation (filesystem,
  network, resource limits) use the Container backend behind the same contract.

  Constitutional basis: "Security by design", "Preserve previous stable states",
  "Support reproducibility", "Detect degraded performance" (timeouts).
  """
  @behaviour Tiannara.SelfImprovement.Sandbox.Backend

  alias Tiannara.SelfImprovement.Sandbox.{CodePatch, BuildSpec, TestSpec, BenchmarkSpec}

  @impl true
  def prepare(baseline_path, _opts) do
    workdir =
      Path.join(System.tmp_dir!(), "tiannara_sandbox_#{System.unique_integer([:positive])}")

    try do
      File.mkdir_p!(workdir)

      {:ok, entries} = File.ls(baseline_path)

      Enum.each(entries, fn entry ->
        File.cp_r!(Path.join(baseline_path, entry), Path.join(workdir, entry))
      end)

      {:ok, %{workdir: workdir, baseline: baseline_path}}
    rescue
      e -> {:error, {:prepare_failed, Exception.message(e)}}
    end
  end

  @impl true
  def apply_patch(env, %CodePatch{files: files}) when is_map(files) and map_size(files) > 0 do
    try do
      Enum.each(files, fn {rel_path, content} ->
        path = Path.join(env.workdir, rel_path)
        File.mkdir_p!(Path.dirname(path))
        File.write!(path, content)
      end)

      {:ok, env}
    rescue
      e -> {:error, {:patch_failed, Exception.message(e)}}
    end
  end

  def apply_patch(env, %CodePatch{diff: diff}) when is_binary(diff) do
    difffile = Path.join(env.workdir, ".sandbox_patch.diff")
    File.write!(difffile, diff)

    result =
      case System.cmd("patch", ["-p1", "-i", difffile],
             cd: env.workdir, stderr_to_stdout: true) do
        {_, 0} -> :ok
        {out, code} -> {:error, {:patch_failed, code, out}}
      end

    File.rm(difffile)

    case result do
      :ok -> {:ok, env}
      err -> err
    end
  end

  def apply_patch(_env, %CodePatch{}), do: {:error, :empty_patch}

  @impl true
  def build(_env, nil), do: {:ok, :skipped}
  def build(_env, %BuildSpec{command: nil}), do: {:ok, :skipped}

  def build(env, %BuildSpec{command: cmd, args: args, timeout: timeout}) do
    case cmd_with_timeout(cmd, args, [cd: env.workdir, stderr_to_stdout: true], timeout) do
      {:error, _} = e -> e
      {_, 0} -> {:ok, :built}
      {out, code} -> {:error, {:build_failed, code, out}}
    end
  end

  @impl true
  def run_tests(env, %TestSpec{} = spec) do
    opts = [cd: env.workdir, stderr_to_stdout: true]

    case cmd_with_timeout(spec.command, spec.args, opts, spec.timeout) do
      {:error, reason} ->
        {:ok, %{all_passed: false, exit_code: nil, output: "", error: reason}}

      {output, code} ->
        passed = code == 0 and matches?(output, spec.pass_pattern)
        {:ok, %{all_passed: passed, exit_code: code, output: output}}
    end
  end

  @impl true
  def run_benchmark(env, %BenchmarkSpec{} = spec) do
    opts = [cd: env.workdir, stderr_to_stdout: true]

    case cmd_with_timeout(spec.command, spec.args, opts, spec.timeout) do
      {:error, reason} ->
        {:error, {:benchmark_failed, reason}}

      {output, code} ->
        {:ok, %{metric: spec.parse.(output), exit_code: code, output: output}}
    end
  end

  @impl true
  def teardown(%{workdir: workdir}) do
    File.rm_rf!(workdir)
    :ok
  end

  # --- helpers -------------------------------------------------------------

  defp cmd_with_timeout(cmd, args, opts, timeout) do
    {cmd, args} = shell_compat(cmd, args)
    task = Task.async(fn -> System.cmd(cmd, args, opts) end)

    case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
      {:ok, result} -> result
      nil -> {:error, :timeout}
    end
  end

  # On Windows there is no POSIX `sh`; translate trivial sh -c scripts to
  # native equivalents so the real sandbox remains runnable on all hosts.
  defp shell_compat("sh", ["-c", script]) do
    case :os.type() do
      {:win32, _} -> translate_sh_script(script)
      _ -> {"sh", ["-c", script]}
    end
  end

  defp shell_compat(cmd, args), do: {cmd, args}

  defp translate_sh_script("true"), do: {"cmd.exe", ["/d", "/c", "rem"]}

  defp translate_sh_script("cat " <> rest) do
    # NB: `cmd /c type` intermittently emits NOTHING (exit 0) when stdout is a
    # pipe (Windows cmd builtin race), which breaks benchmark parsing; use
    # powershell Get-Content which is reliable under pipe capture.
    {"powershell", ["-NoProfile", "-NonInteractive", "-Command", "Get-Content -Raw -LiteralPath '#{rest}'"]}
  end

  defp translate_sh_script("grep -q " <> rest) do
    case String.split(rest, ~r/\s+/, parts: 2) do
      [pattern, file] ->
        script =
          "$m = Select-String -Quiet -SimpleMatch -Pattern '#{pattern}' -Path '#{file}'; " <>
            "if ($m) { exit 0 } else { exit 1 }"

        {"powershell", ["-NoProfile", "-NonInteractive", "-Command", script]}

      _ ->
        {"cmd.exe", ["/d", "/c", "rem"]}
    end
  end

  defp translate_sh_script(script), do: {"cmd.exe", ["/d", "/s", "/c", script]}

  defp matches?(_output, nil), do: true
  defp matches?(output, %Regex{} = re), do: Regex.match?(re, output)
  defp matches?(output, pattern) when is_binary(pattern), do: String.contains?(output, pattern)
end