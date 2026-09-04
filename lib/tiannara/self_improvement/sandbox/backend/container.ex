defmodule Tiannara.SelfImprovement.Sandbox.Backend.Container do
  @moduledoc """
  Container sandbox backend (Docker/Podman) for hardened isolation.

  Model: the baseline is copied into a throwaway host workdir which is mounted
  read-write into an ephemeral container; build/test/benchmark EXECUTION happens
  inside the container with:
    * network DISABLED by default (`--network none`)
    * memory + CPU limits
    * a wall-clock timeout (kill switch)

  The engine command runner is INJECTABLE so the backend is fully testable
  without a real container runtime (Replaceability + Testability).

  Constitutional basis: "Security by design", "Fault tolerance", "Preserve
  previous stable states", "Support reproducibility", "Detect degraded
  performance" (timeouts), "Avoid designs dependent on any single ... platform"
  (engine-agnostic runner).
  """
  @behaviour Tiannara.SelfImprovement.Sandbox.Backend

  alias Tiannara.SelfImprovement.Sandbox.{CodePatch, BuildSpec, TestSpec, BenchmarkSpec}

  @impl true
  def prepare(baseline_path, opts) do
    workdir =
      Path.join(System.tmp_dir!(), "tiannara_csb_#{System.unique_integer([:positive])}")

    try do
      File.mkdir_p!(workdir)
      {:ok, entries} = File.ls(baseline_path)

      Enum.each(entries, fn entry ->
        File.cp_r!(Path.join(baseline_path, entry), Path.join(workdir, entry))
      end)

      {:ok,
       %{
         workdir: workdir,
         baseline: baseline_path,
         runner: Keyword.get(opts, :runner, &default_runner/2),
         engine: Keyword.get(opts, :engine, "docker"),
         image: Keyword.get(opts, :image, "tiannara/sandbox:latest"),
         network: Keyword.get(opts, :network, false),
         memory_limit: Keyword.get(opts, :memory_limit, "512m"),
         cpus: Keyword.get(opts, :cpus, "1.0")
       }}
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
    case run_in_container(env, cmd, args, timeout) do
      {:ok, _, 0} -> {:ok, :built}
      {:ok, out, code} -> {:error, {:build_failed, code, out}}
      {:error, _} = e -> e
    end
  end

  @impl true
  def run_tests(env, %TestSpec{} = spec) do
    case run_in_container(env, spec.command, spec.args, spec.timeout) do
      {:ok, output, code} ->
        passed = code == 0 and matches?(output, spec.pass_pattern)
        {:ok, %{all_passed: passed, exit_code: code, output: output}}

      {:error, reason} ->
        {:ok, %{all_passed: false, exit_code: nil, output: "", error: reason}}
    end
  end

  @impl true
  def run_benchmark(env, %BenchmarkSpec{} = spec) do
    case run_in_container(env, spec.command, spec.args, spec.timeout) do
      {:ok, output, code} ->
        {:ok, %{metric: spec.parse.(output), exit_code: code, output: output}}

      {:error, reason} ->
        {:error, {:benchmark_failed, reason}}
    end
  end

  @impl true
  def teardown(%{workdir: workdir}) do
    File.rm_rf!(workdir)
    :ok
  end

  # --- container execution ------------------------------------------------

  defp run_in_container(env, command, args, timeout) do
    engine_args = build_run_args(env, command, args)
    task = Task.async(fn -> env.runner.(env.engine, engine_args) end)

    case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
      {:ok, {:error, reason}} -> {:error, reason}
      {:ok, {output, code}} -> {:ok, output, code}
      nil -> {:error, :timeout}
    end
  end

  defp build_run_args(env, command, args) do
    volume = ["-v", "#{env.workdir}:/work", "-w", "/work"]
    network = if env.network, do: [], else: ["--network", "none"]
    limits = ["--memory", env.memory_limit, "--cpus", env.cpus]

    ["run", "--rm"] ++ volume ++ network ++ limits ++ [env.image, command] ++ args
  end

  defp default_runner(engine, args) do
    {output, code} = System.cmd(engine, args, stderr_to_stdout: true)
    {output, code}
  rescue
    e -> {:error, {:engine_failed, Exception.message(e)}}
  end

  defp matches?(_output, nil), do: true
  defp matches?(output, %Regex{} = re), do: Regex.match?(re, output)
  defp matches?(output, pattern) when is_binary(pattern), do: String.contains?(output, pattern)
end