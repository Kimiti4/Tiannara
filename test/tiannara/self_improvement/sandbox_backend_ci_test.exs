defmodule Tiannara.SelfImprovement.SandboxBackendCITest do
  use ExUnit.Case, async: false

  alias Tiannara.SelfImprovement.Sandbox.{TestSpec, BenchmarkSpec}
  alias Tiannara.SelfImprovement.Sandbox.Backend.CI

  @moduletag :sandbox_ci

  defp mock_ci_client(test_pid, job_results) do
    {:ok, agent} = Agent.start_link(fn -> %{next_id: 1, jobs: %{}} end)

    %{
      prepare_workspace: fn baseline ->
        send(test_pid, {:ci, :prepare, baseline})
        {:ok, %{baseline: baseline}}
      end,

      apply_patch: fn workspace, patch ->
        send(test_pid, {:ci, :apply_patch, patch.id})
        {:ok, Map.put(workspace, :patch, patch.id)}
      end,

      submit_job: fn _workspace, job_type, _spec ->
        job_id =
          Agent.get_and_update(agent, fn s ->
            id = s.next_id
            {id, %{s | next_id: id + 1, jobs: Map.put(s.jobs, id, job_type)}}
          end)

        send(test_pid, {:ci, :submit, job_type, job_id})
        {:ok, job_id}
      end,

      job_status: fn _job_id -> :done end,

      fetch_result: fn job_id ->
        job_type = Agent.get(agent, fn s -> Map.get(s.jobs, job_id) end)
        {output, code} = Map.get(job_results, job_type, {"", 0})
        send(test_pid, {:ci, :fetch, job_type})
        {:ok, output, code}
      end,

      cleanup: fn _workspace ->
        send(test_pid, {:ci, :cleanup})
        :ok
      end
    }
  end

  test "CI backend runs tests through the CI client" do
    client = mock_ci_client(self(), %{test: {"5 tests, 0 failures", 0}})
    {:ok, env} = CI.prepare("/fake/baseline", client: client)

    test_spec = %TestSpec{command: "mix", args: ["test"],
                          pass_pattern: "0 failures", timeout: 5_000}

    {:ok, result} = CI.run_tests(env, test_spec)

    assert result.all_passed
    assert_receive {:ci, :prepare, "/fake/baseline"}
    assert_receive {:ci, :submit, :test, _}
    assert_receive {:ci, :fetch, :test}

    CI.teardown(env)
    assert_receive {:ci, :cleanup}
  end

  test "a failing CI test reports all_passed false" do
    client = mock_ci_client(self(), %{test: {"3 tests, 1 failure", 1}})
    {:ok, env} = CI.prepare("/fake/baseline", client: client)

    test_spec = %TestSpec{command: "mix", args: ["test"], timeout: 5_000}
    {:ok, result} = CI.run_tests(env, test_spec)

    refute result.all_passed
    CI.teardown(env)
  end

  test "CI backend parses benchmark metrics from job output" do
    client = mock_ci_client(self(), %{benchmark: {"123", 0}})
    {:ok, env} = CI.prepare("/fake/baseline", client: client)

    bench_spec = %BenchmarkSpec{command: "bench", args: [], metric: :ops,
                                direction: :higher_better,
                                parse: fn out -> String.to_integer(String.trim(out)) end,
                                timeout: 5_000}

    {:ok, result} = CI.run_benchmark(env, bench_spec)
    assert result.metric == 123
    CI.teardown(env)
  end
end