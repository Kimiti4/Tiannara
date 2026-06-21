defmodule TiannaraOS.ToolRuntime do
  @moduledoc """
  Core runtime executor for ToolGenomes. Matches backend configurations,
  enforces security validation against CivilizationKernel, and contains crashes.
  """

  require Logger
  alias TiannaraOS.ToolGenome
  alias TiannaraOS.EvidenceNode
  alias TiannaraOS.CivilizationKernel

  @doc """
  Executes a ToolGenome spec against a repository twin directory path.
  Enforces L0 kernel security rules and encapsulates crashes.
  """
  @spec execute_tool(ToolGenome.t(), String.t(), map()) :: {:ok, map()} | {:error, any()}
  def execute_tool(%ToolGenome{} = genome, twin_path, inputs) do
    # 1. Kernel security validation hook
    case CivilizationKernel.validate_security_profile(genome.security_profile) do
      {:error, reason} ->
        Logger.error("🛡️ [Tool Runtime] Security validation failed for #{genome.id}: #{inspect(reason)}")
        {:error, {:security_violation, reason}}

      :ok ->
        # 2. Crash safety boundary
        try do
          case genome.execution_backend do
            :interpreter ->
              interpret(genome, twin_path, inputs)

            :fastapi ->
              TiannaraOS.ToolProviders.FastAPI.dispatch_execution(genome, twin_path, inputs)

            unknown ->
              {:error, {:unknown_backend, unknown}}
          end
        rescue
          e ->
            Logger.error("🚨 [Tool Runtime] Trapped runtime crash: #{inspect(e)}")
            {:error, {:runtime_crash, e}}
        catch
          kind, reason ->
            Logger.error("🚨 [Tool Runtime] Trapped exit/throw: #{inspect({kind, reason})}")
            {:error, {:runtime_crash, reason}}
        end
    end
  end

  @doc """
  Runs the end-to-end capability grounding loop:
  1. Executes the tool spec on the target Repository Twin.
  2. Generates an EvidenceNode containing execution metadata (source: :tool_execution).
  3. Updates Tool Genome fitness in the State.
  """
  @spec run_grounding_loop(ToolGenome.t(), String.t(), map(), atom()) :: {:ok, EvidenceNode.t(), TiannaraOS.State.t()} | {:error, any(), EvidenceNode.t()}
  def run_grounding_loop(%ToolGenome{} = genome, twin_path, inputs, world_id) do
    case execute_tool(genome, twin_path, inputs) do
      {:ok, %{vulnerabilities: vulns}} ->
        # Output success evidence node
        evidence_value = if length(vulns) > 0, do: 1.0, else: 0.0
        evidence_id = String.to_atom("ev_tool_#{genome.id}_#{System.unique_integer([:positive])}")

        evidence_node = %EvidenceNode{
          id: evidence_id,
          type: :evidence,
          name: "Vulnerability analysis by tool #{genome.id}",
          value: evidence_value,
          validity: :valid,
          metadata: %{
            source: :tool_execution,
            genome_id: genome.id,
            execution_backend: genome.execution_backend,
            target_world: world_id,
            vulnerabilities: vulns,
            provenance: ["tool_execution_success"],
            confidence_history: [%{value: evidence_value, updated_at: DateTime.utc_now()}],
            last_updated_at: DateTime.utc_now()
          }
        }

        # Boost fitness
        updated_fitness = min(1.0, (genome.fitness || 0.5) + 0.1)
        {:ok, state} = CivilizationKernel.update_state(fn current_state ->
          updated_genome = %{genome | fitness: updated_fitness}
          updated_tools = Map.put(current_state.tools, genome.id, updated_genome)
          %{current_state | tools: updated_tools}
        end)

        {:ok, evidence_node, state}

      {:error, reason} ->
        # Trapped crash or validation failure. Generate failure evidence node.
        evidence_id = String.to_atom("ev_tool_fail_#{genome.id}_#{System.unique_integer([:positive])}")

        failure_evidence = %EvidenceNode{
          id: evidence_id,
          type: :evidence,
          name: "Failed execution of tool #{genome.id}",
          value: 0.0,
          validity: :invalid,
          metadata: %{
            source: :tool_execution,
            genome_id: genome.id,
            execution_backend: genome.execution_backend,
            target_world: world_id,
            execution_error: reason,
            provenance: ["tool_execution_crash_failure"],
            confidence_history: [%{value: 0.0, updated_at: DateTime.utc_now()}],
            last_updated_at: DateTime.utc_now()
          }
        }

        # Penalize fitness by 50%
        penalized_fitness = max(0.0, (genome.fitness || 0.5) * 0.5)
        {:ok, _state} = CivilizationKernel.update_state(fn current_state ->
          updated_genome = %{genome | fitness: penalized_fitness}
          updated_tools = Map.put(current_state.tools, genome.id, updated_genome)
          %{current_state | tools: updated_tools}
        end)

        {:error, reason, failure_evidence}
    end
  end

  # --- PRIVATE INTERPRETER IMPLEMENTATION ---

  defp interpret(genome, twin_path, _inputs) do
    mix_exs_path = Path.join(twin_path, "mix.exs")
    unless File.exists?(mix_exs_path) do
      raise "mix.exs not found at #{twin_path}"
    end

    content = File.read!(mix_exs_path)
    rules = Map.get(genome.execution_spec, :rules, [])

    vulnerabilities =
      Enum.reduce(rules, [], fn rule, acc ->
        pkg = rule.package
        vuln_before = rule.vulnerable_before

        # Search for dependency: e.g. {:plug, "1.13.0"}
        pattern = ~r/{\s*:#{pkg}\s*,\s*["']([^"']+)["']/
        case Regex.run(pattern, content) do
          [_, version] ->
            if version_less_than?(version, vuln_before) do
              [%{package: pkg, version: version, status: "vulnerable", advisory: "CVE-2022-XXXX"} | acc]
            else
              acc
            end

          nil ->
            acc
        end
      end)

    {:ok, %{vulnerabilities: vulnerabilities}}
  end

  defp version_less_than?(v1, v2) do
    clean_v1 = String.replace(v1, ~r/[~>=<\s]/, "")
    clean_v2 = String.replace(v2, ~r/[~>=<\s]/, "")

    case {Version.parse(clean_v1), Version.parse(clean_v2)} do
      {{:ok, ver1}, {{:ok, ver2}}} ->
        Version.compare(ver1, ver2) == :lt

      _ ->
        clean_v1 < clean_v2
    end
  end
end
