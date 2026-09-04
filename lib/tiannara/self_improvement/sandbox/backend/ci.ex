defmodule Tiannara.SelfImprovement.Sandbox.Backend.CI do
  @moduledoc """
  CI sandbox backend. Delegates build/test/benchmark to an isolated CI pipeline
  via an injectable client (a map of functions), so it is testable without a
  real CI provider and auditable for the official certification record.

  Client contract (map of functions):
      prepare_workspace.(baseline)          -> {:ok, workspace} | {:error, reason}
      apply_patch.(workspace, patch)        -> {:ok, workspace} | {:error, reason}
      submit_job.(workspace, job_type, spec)-> {:ok, job_id} | {:error, reason}
      job_status.(job_id)                   -> :pending | :running | :done | :failed
      fetch_result.(job_id)                 -> {:ok, output, exit_code} | {:error, reason}
      cleanup.(workspace)                   -> :ok

  Constitutional basis: "Support reproducibility", "Maintain audit trails",
  "Security by design", Replaceability, "Verification First".
  """
  @behaviour Tiannara.SelfImprovement.Sandbox.Backend

  alias Tiannara.SelfImprovement.Sandbox.{BuildSpec, TestSpec, BenchmarkSpec}

  @default_poll_interval 10
  @default_timeout 5_000

  @impl true
  def prepare(baseline_path, opts) do
    client = Keyword.fetch!(opts, :client)
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    poll_interval = Keyword.get(opts, :poll_interval, @default_poll_interval)

    case client.prepare_workspace.(baseline_path) do
      {:ok, workspace} ->
        {:ok, %{workspace: workspace, client: client,
                timeout: timeout, poll_interval: poll_interval}}

      {:error, _} = e ->
        e
    end
  end

  @impl true
  def apply_patch(env, patch) do
    case env.client.apply_patch.(env.workspace, patch) do
      {:ok, workspace} -> {:ok, %{env | workspace: workspace}}
      {:error, _} = e -> e
    end
  end

  @impl true
  def build(_env, nil), do: {:ok, :skipped}
  def build(_env, %BuildSpec{command: nil}), do: {:ok, :skipped}

  def build(env, %BuildSpec{} = spec) do
    case run_ci_job(env, :build, spec) do
      {:ok, _, 0} -> {:ok, :built}
      {:ok, out, code} -> {:error, {:build_failed, code, out}}
      {:error, _} = e -> e
    end
  end

  @impl true
  def run_tests(env, %TestSpec{} = spec) do
    case run_ci_job(env, :test, spec) do
      {:ok, output, code} ->
        passed = code == 0 and matches?(output, spec.pass_pattern)
        {:ok, %{all_passed: passed, exit_code: code, output: output}}

      {:error, reason} ->
        {:ok, %{all_passed: false, exit_code: nil, output: "", error: reason}}
    end
  end

  @impl true
  def run_benchmark(env, %BenchmarkSpec{} = spec) do
    case run_ci_job(env, :benchmark, spec) do
      {:ok, output, code} ->
        {:ok, %{metric: spec.parse.(output), exit_code: code, output: output}}

      {:error, reason} ->
        {:error, {:benchmark_failed, reason}}
    end
  end

  @impl true
  def teardown(env) do
    env.client.cleanup.(env.workspace)
    :ok
  end

  defp run_ci_job(env, job_type, spec) do
    with {:ok, job_id} <- env.client.submit_job.(env.workspace, job_type, spec),
         :ok <- poll_until_done(env.client, job_id, env.timeout, env.poll_interval),
         {:ok, output, code} <- env.client.fetch_result.(job_id) do
      {:ok, output, code}
    end
  end

  defp poll_until_done(client, job_id, timeout, poll_interval) do
    deadline = System.monotonic_time(:millisecond) + timeout
    do_poll(client, job_id, deadline, poll_interval)
  end

  defp do_poll(client, job_id, deadline, poll_interval) do
    if System.monotonic_time(:millisecond) > deadline do
      {:error, :ci_timeout}
    else
      case client.job_status.(job_id) do
        :done -> :ok
        :failed -> {:error, :ci_job_failed}
        s when s in [:pending, :running] ->
          Process.sleep(poll_interval)
          do_poll(client, job_id, deadline, poll_interval)
      end
    end
  end

  defp matches?(_output, nil), do: true
  defp matches?(output, %Regex{} = re), do: Regex.match?(re, output)
  defp matches?(output, pattern) when is_binary(pattern), do: String.contains?(output, pattern)
end