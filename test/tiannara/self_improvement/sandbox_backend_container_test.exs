defmodule Tiannara.SelfImprovement.SandboxBackendContainerTest do
  use ExUnit.Case, async: false

  alias Tiannara.SelfImprovement.Sandbox.{CodePatch, TestSpec, BenchmarkSpec}
  alias Tiannara.SelfImprovement.Sandbox.Backend.Container

  @moduletag :sandbox_container

  setup do
    base = Path.join(System.tmp_dir!(), "csb_base_#{System.unique_integer([:positive])}")
    File.mkdir_p!(base)
    File.write!(Path.join(base, "app.txt"), "hello")
    on_exit(fn -> File.rm_rf!(base) end)
    {:ok, base: base}
  end

  defp recording_runner(test_pid, response) do
    fn engine, args ->
      send(test_pid, {:container_cmd, engine, args})
      response
    end
  end

  test "prepare copies the baseline into an isolated workdir", %{base: base} do
    {:ok, env} = Container.prepare(base, runner: recording_runner(self(), {"", 0}))
    assert File.exists?(Path.join(env.workdir, "app.txt"))
    Container.teardown(env)
  end

  test "run_tests executes in-container with network disabled + resource limits", %{base: base} do
    runner = recording_runner(self(), {"5 tests, 0 failures", 0})

    {:ok, env} =
      Container.prepare(base, runner: runner, image: "img:test",
        memory_limit: "256m", cpus: "0.5")

    test_spec = %TestSpec{command: "mix", args: ["test"],
                          pass_pattern: "0 failures", timeout: 5_000}

    {:ok, result} = Container.run_tests(env, test_spec)

    assert result.all_passed

    assert_receive {:container_cmd, "docker", args}
    assert "run" in args
    assert "--network" in args
    assert "none" in args
    assert "--memory" in args
    assert "256m" in args
    assert "--cpus" in args
    assert "0.5" in args
    assert "img:test" in args
    assert "-v" in args

    Container.teardown(env)
  end

  test "a failing container test reports all_passed false", %{base: base} do
    runner = recording_runner(self(), {"3 tests, 1 failure", 1})
    {:ok, env} = Container.prepare(base, runner: runner)

    test_spec = %TestSpec{command: "mix", args: ["test"], timeout: 5_000}
    {:ok, result} = Container.run_tests(env, test_spec)

    refute result.all_passed
    Container.teardown(env)
  end

  test "run_benchmark parses the metric from container output", %{base: base} do
    runner = recording_runner(self(), {"42", 0})
    {:ok, env} = Container.prepare(base, runner: runner)

    bench_spec = %BenchmarkSpec{command: "bench", args: [], metric: :ops,
                                direction: :higher_better,
                                parse: fn out -> String.to_integer(String.trim(out)) end,
                                timeout: 5_000}

    {:ok, result} = Container.run_benchmark(env, bench_spec)
    assert result.metric == 42
    Container.teardown(env)
  end

  test "apply_patch modifies the isolated workdir, never the baseline", %{base: base} do
    {:ok, env} = Container.prepare(base, runner: recording_runner(self(), {"", 0}))

    patch = %CodePatch{id: :cp, files: %{"app.txt" => "patched"}}
    {:ok, env} = Container.apply_patch(env, patch)

    assert File.read!(Path.join(env.workdir, "app.txt")) == "patched"
    assert File.read!(Path.join(base, "app.txt")) == "hello"
    Container.teardown(env)
  end
end