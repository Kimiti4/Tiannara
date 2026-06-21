defmodule Tiannara.ASC.Implementation.Compiler do
  @moduledoc """
  Compiler Layer — orchestrates project generation, compilation, and test execution.

  Responsibilities:
  - Generate project from ImplementationPlan using language adapter
  - Compile generated project in sandboxed environment
  - Run tests and capture results
  - Store diagnostics for observatory metrics

  All operations occur in isolated sandbox directories to prevent
  generated code from modifying ASC itself.
  """

  alias Tiannara.ASC.Implementation.Plan
  alias Tiannara.ASC.Implementation.Adapter.Elixir, as: ElixirAdapter
  alias Tiannara.ASC.Observatory.ProjectObservatory

  @doc """
  Compilation result structure.
  """
  defstruct [
    success: false,
    compile_errors: [],
    warnings: [],
    test_results: [],
    test_pass_count: 0,
    test_fail_count: 0,
    duration_ms: 0,
    project_path: nil
  ]

  @type t :: %__MODULE__{
    success: boolean(),
    compile_errors: [String.t()],
    warnings: [String.t()],
    test_results: [map()],
    test_pass_count: non_neg_integer(),
    test_fail_count: non_neg_integer(),
    duration_ms: non_neg_integer(),
    project_path: String.t() | nil
  }

  @doc """
  Full compilation pipeline: generate → compile → test → record metrics.
  """
  def compile_and_test(%Plan{} = plan, project_id, language \\ :elixir) do
    start_time = System.monotonic_time(:millisecond)

    # Step 1: Generate project
    {:ok, generation_result} = generate_project(plan, project_id, language)

    # Step 2: Compile project
    compile_result = compile_project(generation_result.project_path)

    # Step 3: Run tests (only if compilation succeeded)
    test_result = if compile_result.success do
      run_tests(generation_result.project_path)
    else
      %{pass_count: 0, fail_count: 0, results: []}
    end

    end_time = System.monotonic_time(:millisecond)
    duration_ms = end_time - start_time

    # Step 4: Build result
    result = %__MODULE__{
      success: compile_result.success and test_result.fail_count == 0,
      compile_errors: compile_result.errors,
      warnings: compile_result.warnings,
      test_results: test_result.results,
      test_pass_count: test_result.pass_count,
      test_fail_count: test_result.fail_count,
      duration_ms: duration_ms,
      project_path: generation_result.project_path
    }

    # Step 5: Persist diagnostics
    persist_diagnostics(result, project_id)

    # Step 6: Record observatory metrics
    record_metrics(result, project_id)

    {:ok, result}
  end

  @doc """
  Generate project from implementation plan using specified language adapter.
  """
  def generate_project(%Plan{} = plan, project_id, :elixir) do
    result = ElixirAdapter.generate_project(plan, project_id)
    {:ok, result}
  end

  def generate_project(_plan, _project_id, language) do
    {:error, "Unsupported language: #{inspect(language)}"}
  end

  @doc """
  Compile Elixir project in sandbox directory.
  """
  def compile_project(project_path) do
    # Use appropriate shell for OS
    {shell, args} = case :os.type() do
      {:win32, _} -> {"cmd", ["/c", "cd #{project_path} && mix compile"]}
      _ -> {"sh", ["-c", "cd #{project_path} && mix compile"]}
    end

    {output, exit_code} = System.cmd(shell, args, stderr_to_stdout: true)
    
    errors = parse_compile_errors(output)
    warnings = parse_compile_warnings(output)

    %{
      success: exit_code == 0,
      errors: errors,
      warnings: warnings,
      raw_output: output
    }
  end

  @doc """
  Run tests in sandbox directory.
  """
  def run_tests(project_path) do
    # Use appropriate shell for OS
    {shell, args} = case :os.type() do
      {:win32, _} -> {"cmd", ["/c", "cd #{project_path} && mix test"]}
      _ -> {"sh", ["-c", "cd #{project_path} && mix test"]}
    end

    {output, exit_code} = System.cmd(shell, args, stderr_to_stdout: true)
    
    {pass_count, fail_count} = parse_test_results(output)

    %{
      pass_count: pass_count,
      fail_count: fail_count,
      success: exit_code == 0,
      results: [%{output: output, exit_code: exit_code}],
      raw_output: output
    }
  end

  @doc """
  Parse compilation errors from mix output.
  """
  def parse_compile_errors(output) do
    output
    |> String.split("\n")
    |> Enum.filter(fn line ->
      String.contains?(line, "** (") or
      String.contains?(line, "error:") or
      String.contains?(line, "undefined function")
    end)
    |> Enum.take(10)  # Limit to first 10 errors
  end

  @doc """
  Parse compilation warnings from mix output.
  """
  def parse_compile_warnings(output) do
    output
    |> String.split("\n")
    |> Enum.filter(fn line ->
      String.contains?(line, "warning:")
    end)
    |> Enum.take(20)  # Limit to first 20 warnings
  end

  @doc """
  Parse test results from mix test output.
  """
  def parse_test_results(output) do
    # Extract pattern like "X failures, Y skipped, Z total"
    failures = extract_number(output, ~r/(\d+)\s+failur/)
    skipped = extract_number(output, ~r/(\d+)\s+skipped/)
    total = extract_number(output, ~r/(\d+)\s+(tests?|doctests?)/)

    pass_count = max(0, total - failures - skipped)
    fail_count = failures

    {pass_count, fail_count}
  end

  defp extract_number(text, regex) do
    case Regex.run(regex, text) do
      [_, num] -> String.to_integer(num)
      _ -> 0
    end
  end

  @doc """
  Persist compilation diagnostics to disk.
  """
  def persist_diagnostics(%__MODULE__{} = result, project_id) do
    dir = Path.join(["data", "asc_projects", project_id])
    File.mkdir_p!(dir)

    diagnostics = %{
      success: result.success,
      compile_errors: result.compile_errors,
      warnings: result.warnings,
      test_pass_count: result.test_pass_count,
      test_fail_count: result.test_fail_count,
      duration_ms: result.duration_ms,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    file_path = Path.join(dir, "diagnostics.json")
    json = Jason.encode!(diagnostics, pretty: true)
    File.write!(file_path, json)

    file_path
  end

  @doc """
  Record compilation metrics in Project Observatory.
  """
  def record_metrics(%__MODULE__{} = result, project_id) do
    compile_success_rate = if result.success, do: 1.0, else: 0.0
    test_pass_rate = if result.test_pass_count + result.test_fail_count > 0 do
      Float.round(result.test_pass_count / (result.test_pass_count + result.test_fail_count), 4)
    else
      0.0
    end

    ProjectObservatory.record(project_id, %{
      compile_success_rate: compile_success_rate,
      compile_iterations: 1,  # First attempt
      compile_error_count: length(result.compile_errors),
      test_pass_rate: test_pass_rate,
      generation_duration_ms: result.duration_ms
    })
  end
end
