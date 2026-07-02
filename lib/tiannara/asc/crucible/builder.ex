defmodule Tiannara.ASC.Crucible.Builder do
  @moduledoc """
  Crucible Builder — transforms Interface Genomes into executable artifacts.

  Responsibilities:
  - Generate source code from Interface Genome
  - Compile projects in sandboxed environments
  - Measure build success/failure with error taxonomy
  - Record comprehensive telemetry for law discovery
  - Ensure build determinism (same input → same output)

  ## Success Criteria

  - SC-B1: Build success rate >80%
  - SC-B2: Build determinism 95%+
  - SC-B3: 100% failure classification
  - SC-B4: 100% telemetry coverage

  ## Example

      iex> {:ok, result} = Tiannara.ASC.Crucible.Builder.build(genome, project_id)
      iex> result.success?
      true
      iex> result.build_time_ms
      1523

  """

  alias Tiannara.ASC.Interface.Genome

  @derive Jason.Encoder
  defstruct [
    # Identity
    build_id: nil,                # Unique build identifier
    project_id: nil,              # Project being built
    genome_id: nil,               # Source genome ID

    # Outcome
    success?: false,              # Did build succeed?
    build_time_ms: 0,             # Total build time in milliseconds
    artifact_path: nil,           # Path to generated artifact

    # Error Classification (SC-B3)
    error_type: nil,              # :syntax | :dependency | :type | :configuration | :resource | nil
    error_message: nil,           # Human-readable error description
    error_details: nil,           # Detailed error information

    # Metrics (SC-B4)
    artifact_size_bytes: 0,       # Size of generated artifact
    dependency_count: 0,          # Number of dependencies resolved
    file_count: 0,                # Number of files generated
    compilation_warnings: 0,      # Number of compiler warnings

    # Determinism Tracking (SC-B2)
    artifact_hash: nil,           # Hash of generated artifact for determinism check
    build_attempt: 1,             # Which attempt this is (for retry logic)

    # Metadata
    started_at: nil,              # When build started
    completed_at: nil,            # When build completed
    environment: nil              # Build environment info
  ]

  @typedoc "Build result record"
  @type t :: %__MODULE__{
          build_id: String.t() | nil,
          project_id: String.t() | nil,
          genome_id: String.t() | nil,
          success?: boolean(),
          build_time_ms: non_neg_integer(),
          artifact_path: String.t() | nil,
          error_type: atom() | nil,
          error_message: String.t() | nil,
          error_details: any(),
          artifact_size_bytes: non_neg_integer(),
          dependency_count: non_neg_integer(),
          file_count: non_neg_integer(),
          compilation_warnings: non_neg_integer(),
          artifact_hash: String.t() | nil,
          build_attempt: non_neg_integer(),
          started_at: any(),
          completed_at: any(),
          environment: map() | nil
        }

  @doc """
  Build an executable artifact from an Interface Genome.

  Executes the full build pipeline:
  1. Generate source code from genome
  2. Resolve dependencies
  3. Compile project
  4. Measure outcomes
  5. Record telemetry

  ## Returns

  - `{:ok, build_result}`

  """
  def build(%Genome{} = genome, project_id, opts \\ []) do
    max_attempts = Keyword.get(opts, :max_attempts, 3)
    build_result = do_build(genome, project_id, max_attempts)
  
    # Record telemetry (SC-B4)
    record_telemetry(build_result)
  
    # Register in Knowledge Archive
    register_build(build_result)

    # Record unified observation
    observation = Tiannara.ASC.Crucible.Observation.from_builder_result(
      build_result,
      project_id,
      genome.genome_id,
      genome.generation
    )
    Tiannara.ASC.Crucible.Observatory.record_observation(observation)

    {:ok, build_result}
  end

  @doc """
  Check build determinism by building same genome twice and comparing artifacts.

  ## Returns

  - `{:ok, deterministic?, hash_match?}`

  """
  def check_determinism(%Genome{} = genome, project_id) do
    # First build
    {:ok, result1} = build(genome, "#{project_id}_run1")

    # Second build
    {:ok, result2} = build(genome, "#{project_id}_run2")

    # Compare hashes
    hash_match = result1.artifact_hash == result2.artifact_hash

    {:ok, hash_match, result1.artifact_hash == result2.artifact_hash}
  end

  @doc """
  Classify build errors into taxonomy categories (SC-B3).

  Categories:
  - :syntax — Syntax errors in generated code
  - :dependency — Missing or incompatible dependencies
  - :type — Type checking failures
  - :configuration — Build configuration errors
  - :resource — Resource exhaustion (memory, disk, etc.)
  - :unknown — Unclassified errors

  ## Returns

  - Error type atom

  """
  def classify_error(error_output) do
    cond do
      # Syntax errors
      String.contains?(error_output, ["syntax error", "unexpected token", "parse error"]) ->
        :syntax

      # Dependency errors
      String.contains?(error_output, ["dependency", "not found", "could not find", "hex.pm"]) ->
        :dependency

      # Type errors
      String.contains?(error_output, ["type mismatch", "no function clause", "undefined function"]) ->
        :type

      # Configuration errors
      String.contains?(error_output, ["configuration", "mix.exs", "invalid option"]) ->
        :configuration

      # Resource errors
      String.contains?(error_output, ["out of memory", "disk space", "too many open files"]) ->
        :resource

      # Default
      true ->
        :unknown
    end
  end

  @doc """
  Calculate build success rate across multiple builds (SC-B1).

  ## Returns

  - Success rate as float (0.0-1.0)

  """
  def success_rate(build_results) when length(build_results) == 0 do
    0.0
  end

  def success_rate(build_results) do
    successful = Enum.count(build_results, & &1.success?)
    successful / length(build_results)
  end

  # Private Implementation

  defp do_build(%Genome{} = genome, project_id, max_attempts, attempt \\ 1) do
    start_time = System.monotonic_time(:millisecond)
    started_at = DateTime.utc_now()

    build_result = try do
      # Step 1: Generate source code from genome
      {:ok, generation_result} = generate_source_code(genome, project_id)

      # Step 2: Compile project
      compile_result = compile_project(generation_result.project_path)

      # Step 3: Measure outcomes
      end_time = System.monotonic_time(:millisecond)
      build_time_ms = end_time - start_time
      completed_at = DateTime.utc_now()

      # Step 4: Calculate artifact hash for determinism (SC-B2)
      artifact_hash = calculate_artifact_hash(generation_result.project_path)

      # Step 5: Build result
      if compile_result.success do
        # Successful build
        artifact_size = calculate_artifact_size(generation_result.project_path)

        %__MODULE__{
          build_id: generate_id(),
          project_id: project_id,
          genome_id: genome.genome_id,
          success?: true,
          build_time_ms: build_time_ms,
          artifact_path: generation_result.project_path,
          error_type: nil,
          error_message: nil,
          error_details: nil,
          artifact_size_bytes: artifact_size,
          dependency_count: count_dependencies(generation_result.project_path),
          file_count: count_files(generation_result.project_path),
          compilation_warnings: length(compile_result.warnings),
          artifact_hash: artifact_hash,
          build_attempt: attempt,
          started_at: started_at,
          completed_at: completed_at,
          environment: get_environment_info()
        }
      else
        # Failed build - classify error (SC-B3)
        error_type = classify_error(compile_result.raw_output)

        %__MODULE__{
          build_id: generate_id(),
          project_id: project_id,
          genome_id: genome.genome_id,
          success?: false,
          build_time_ms: build_time_ms,
          artifact_path: generation_result.project_path,
          error_type: error_type,
          error_message: extract_error_message(compile_result.raw_output),
          error_details: compile_result.errors,
          artifact_size_bytes: 0,
          dependency_count: 0,
          file_count: count_files(generation_result.project_path),
          compilation_warnings: 0,
          artifact_hash: nil,
          build_attempt: attempt,
          started_at: started_at,
          completed_at: completed_at,
          environment: get_environment_info()
        }
      end

    rescue
      e ->
        # Exception during build
        end_time = System.monotonic_time(:millisecond)
        build_time_ms = end_time - start_time
        completed_at = DateTime.utc_now()

        error_type = classify_error(Exception.message(e))

        %__MODULE__{
          build_id: generate_id(),
          project_id: project_id,
          genome_id: genome.genome_id,
          success?: false,
          build_time_ms: build_time_ms,
          artifact_path: nil,
          error_type: error_type,
          error_message: Exception.message(e),
          error_details: %{exception: e, stacktrace: __STACKTRACE__},
          artifact_size_bytes: 0,
          dependency_count: 0,
          file_count: 0,
          compilation_warnings: 0,
          artifact_hash: nil,
          build_attempt: attempt,
          started_at: started_at,
          completed_at: completed_at,
          environment: get_environment_info()
        }
    end

    # Retry logic if build failed and attempts remain
    if not build_result.success? and attempt < max_attempts do
      do_build(genome, project_id, max_attempts, attempt + 1)
    else
      build_result
    end
  end

  defp generate_source_code(%Genome{} = genome, project_id) do
    # TODO: Implement genome-to-source-code generation
    # For now, use placeholder that creates minimal Mix project
    # This will be replaced with actual genome-driven code generation

    sandbox_path = Path.join(["data", "asc_crucible", project_id, "sandbox"])
    File.mkdir_p!(sandbox_path)

    # Create minimal mix.exs
    mix_exs_content = """
    defmodule #{Macro.camelize(project_id)}.MixProject do
      use Mix.Project

      def project do
        [
          app: :#{String.replace(project_id, "-", "_")},
          version: "0.1.0",
          elixir: "~> 1.14",
          start_permanent: Mix.env() == :prod,
          deps: []
        ]
      end
    end
    """

    File.write!(Path.join(sandbox_path, "mix.exs"), mix_exs_content)
    File.mkdir_p!(Path.join(sandbox_path, "lib"))

    # Create placeholder module from genome contracts
    Enum.each(genome.contracts, fn contract ->
      module_name = Macro.camelize(contract.id || "placeholder")
      content = """
      defmodule #{module_name} do
        @moduledoc "Generated from Interface Genome contract: #{contract.id}"

        def execute(params) do
          {:ok, params}
        end
      end
      """

      File.write!(Path.join(sandbox_path, "lib", "#{Macro.underscore(contract.id || "placeholder")}.ex"), content)
    end)

    {:ok, %{project_path: sandbox_path}}
  end

  defp compile_project(project_path) do
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

  defp calculate_artifact_hash(project_path) do
    # Hash all source files for determinism check
    files = Path.wildcard(Path.join(project_path, "**/*.ex"))
    content = Enum.map(files, &File.read!/1) |> Enum.join()
    :crypto.hash(:sha256, content) |> Base.encode16(case: :lower)
  end

  defp calculate_artifact_size(project_path) do
    # Calculate total size of generated files
    files = Path.wildcard(Path.join(project_path, "**/*"))
    Enum.reduce(files, 0, fn file, acc ->
      case File.stat(file) do
        {:ok, stat} -> acc + stat.size
        _ -> acc
      end
    end)
  end

  defp count_dependencies(project_path) do
    # Count dependencies in mix.exs
    mix_exs_path = Path.join(project_path, "mix.exs")
    if File.exists?(mix_exs_path) do
      content = File.read!(mix_exs_path)
      # Simple heuristic: count lines with "deps:"
      String.split(content, "\n")
      |> Enum.count(&String.contains?(&1, "{:"))
    else
      0
    end
  end

  defp count_files(project_path) do
    # Count generated source files
    files = Path.wildcard(Path.join(project_path, "**/*.ex"))
    length(files)
  end

  defp extract_error_message(raw_output) do
    # Extract first error line from compiler output
    raw_output
    |> String.split("\n")
    |> Enum.find("", &String.contains?(&1, ["error", "warning"]))
    |> String.trim()
  end

  defp parse_compile_errors(output) do
    # Parse compiler errors from output
    output
    |> String.split("\n")
    |> Enum.filter(&String.contains?(&1, "error"))
    |> Enum.map(&String.trim/1)
  end

  defp parse_compile_warnings(output) do
    # Parse compiler warnings from output
    output
    |> String.split("\n")
    |> Enum.filter(&String.contains?(&1, "warning"))
    |> Enum.map(&String.trim/1)
  end

  defp get_environment_info do
    %{
      elixir_version: System.version(),
      erlang_version: :erlang.system_info(:otp_release),
      os: :os.type(),
      timestamp: DateTime.utc_now()
    }
  end

  defp generate_id do
    "build_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
  end

  defp record_telemetry(%__MODULE__{} = result) do
    # Record build metrics to Observatory (SC-B4)
    require Logger

    Logger.info(
      "[Crucible.Builder] Build #{result.build_id}: " <>
      "success=#{result.success?}, time=#{result.build_time_ms}ms, " <>
      "error_type=#{inspect(result.error_type)}, files=#{result.file_count}"
    )

    # TODO: Integrate with ProjectObservatory.record/2
    :ok
  end

  defp register_build(%__MODULE__{} = result) do
    # Register build result in Knowledge Archive
    require Logger

    Logger.debug(
      "[Crucible.Builder.KnowledgeArchive] Registered build #{result.build_id} " <>
      "(genome: #{result.genome_id}, success: #{result.success?})"
    )

    # TODO: Integrate with KnowledgeArchive.register/4
    :ok
  end
end
