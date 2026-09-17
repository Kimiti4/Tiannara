defmodule TiannaraRuntime.OS.Governance.Certification.ProductionGateFramework do
  @moduledoc """
  Production Gate Framework — 13 Sequential Verification Gates

  Each gate must pass before the next is enabled.
  Enforces progressive validation from numerical correctness through constitutional validation.

  Gates are ordered by dependency: foundational gates (numerical, runtime) must pass
  before higher-level gates (SOPL evolution, constitutional validation) are enabled.
  """

  alias TiannaraRuntime.OS.Governance.Certification.ProductionGates.{
    Gate01NumericalCorrectness,
    Gate02RuntimeStability,
    Gate03SIMDValidation,
    Gate04GPUValidation,
    Gate05UniverseServerValidation,
    Gate06SOPLValidation,
    Gate07FitnessFunctionValidation,
    Gate08MultiLawBoundaryValidation,
    Gate09EvolutionRobustness,
    Gate10Observability,
    Gate11SecurityFaultTolerance,
    Gate12ScientificValidation,
    Gate13ConstitutionalValidation
  }

  @type gate_result :: %{
    gate_number: integer(),
    gate_name: String.t(),
    status: :pass | :fail | :pending | :skipped,
    acceptance_criteria_met: boolean(),
    metrics: map(),
    timestamp: integer(),
    duration_ms: integer()
  }

  @type gate_sequence_result :: %{
    gates_passed: integer(),
    gates_failed: integer(),
    gates_pending: integer(),
    overall_status: :all_passed | :partial | :failed,
    last_passed_gate: integer(),
    next_enabled_gate: integer(),
    gate_results: [gate_result()],
    timestamp: integer()
  }

  @doc """
  Runs all 13 production gates in sequential order.
  Each gate must pass before the next is enabled.
  """
  @spec run_all_gates(map()) :: {:ok, gate_sequence_result()} | {:error, String.t()}
  def run_all_gates(config \\ %{}) do
    start_ms = System.monotonic_time(:millisecond)

    gate_modules = [
      Gate01NumericalCorrectness,
      Gate02RuntimeStability,
      Gate03SIMDValidation,
      Gate04GPUValidation,
      Gate05UniverseServerValidation,
      Gate06SOPLValidation,
      Gate07FitnessFunctionValidation,
      Gate08MultiLawBoundaryValidation,
      Gate09EvolutionRobustness,
      Gate10Observability,
      Gate11SecurityFaultTolerance,
      Gate12ScientificValidation,
      Gate13ConstitutionalValidation
    ]

    {results, last_passed} = run_gates_sequential(gate_modules, config, [], 0)

    passed = Enum.count(results, fn r -> r.status == :pass end)
    failed = Enum.count(results, fn r -> r.status == :fail end)
    pending = Enum.count(results, fn r -> r.status == :pending end)

    overall_status = cond do
      failed > 0 -> :failed
      pending > 0 -> :partial
      true -> :all_passed
    end

    next_enabled = if last_passed < 13, do: last_passed + 1, else: 13

    {:ok, %{
      gates_passed: passed,
      gates_failed: failed,
      gates_pending: pending,
      overall_status: overall_status,
      last_passed_gate: last_passed,
      next_enabled_gate: next_enabled,
      gate_results: results,
      duration_ms: System.monotonic_time(:millisecond) - start_ms,
      timestamp: :erlang.unique_integer([:positive])
    }}
  end

  @doc """
  Runs gates up to a specific gate number.
  """
  @spec run_up_to_gate(integer(), map()) :: {:ok, gate_sequence_result()} | {:error, String.t()}
  def run_up_to_gate(max_gate, config \\ %{}) when max_gate in 1..13 do
    gate_modules = Enum.take(all_gate_modules(), max_gate)
    run_all_gates_with_modules(gate_modules, config)
  end

  @doc """
  Returns the module for a specific gate number.
  """
  @spec gate_module(integer()) :: module() | nil
  def gate_module(1), do: Gate01NumericalCorrectness
  def gate_module(2), do: Gate02RuntimeStability
  def gate_module(3), do: Gate03SIMDValidation
  def gate_module(4), do: Gate04GPUValidation
  def gate_module(5), do: Gate05UniverseServerValidation
  def gate_module(6), do: Gate06SOPLValidation
  def gate_module(7), do: Gate07FitnessFunctionValidation
  def gate_module(8), do: Gate08MultiLawBoundaryValidation
  def gate_module(9), do: Gate09EvolutionRobustness
  def gate_module(10), do: Gate10Observability
  def gate_module(11), do: Gate11SecurityFaultTolerance
  def gate_module(12), do: Gate12ScientificValidation
  def gate_module(13), do: Gate13ConstitutionalValidation
  def gate_module(_), do: nil

  @doc """
  Returns all 13 gate modules in order.
  """
  @spec all_gate_modules() :: [module()]
  def all_gate_modules() do
    [
      Gate01NumericalCorrectness,
      Gate02RuntimeStability,
      Gate03SIMDValidation,
      Gate04GPUValidation,
      Gate05UniverseServerValidation,
      Gate06SOPLValidation,
      Gate07FitnessFunctionValidation,
      Gate08MultiLawBoundaryValidation,
      Gate09EvolutionRobustness,
      Gate10Observability,
      Gate11SecurityFaultTolerance,
      Gate12ScientificValidation,
      Gate13ConstitutionalValidation
    ]
  end

  @doc """
  Returns the gate name for a gate number.
  """
  @spec gate_name(integer()) :: String.t()
  def gate_name(1), do: "Numerical Correctness"
  def gate_name(2), do: "Runtime Stability"
  def gate_name(3), do: "SIMD Validation"
  def gate_name(4), do: "GPU Validation"
  def gate_name(5), do: "UniverseServer Validation"
  def gate_name(6), do: "SOPL Validation"
  def gate_name(7), do: "Fitness Function Validation"
  def gate_name(8), do: "Multi-Law Boundary Validation"
  def gate_name(9), do: "Evolution Robustness"
  def gate_name(10), do: "Observability"
  def gate_name(11), do: "Security and Fault Tolerance"
  def gate_name(12), do: "Scientific Validation"
  def gate_name(13), do: "Constitutional Validation"

  # ── Sequential Gate Execution ──────────────────────────────

  defp run_gates_sequential([], _config, results, last_passed) do
    {Enum.reverse(results), last_passed}
  end

  defp run_gates_sequential([mod | rest], config, results, last_passed) do
    gate_number = gate_number_for_module(mod)
    IO.puts("[Gate #{gate_number}] #{gate_name(gate_number)}...")

    start_ms = System.monotonic_time(:millisecond)
    result = mod.run_gate(config)
    duration = System.monotonic_time(:millisecond) - start_ms

    enriched = Map.merge(result, %{
      gate_number: gate_number,
      duration_ms: duration
    })

    case enriched.status do
      :pass ->
        IO.puts("[Gate #{gate_number}] PASS")
        run_gates_sequential(rest, config, [enriched | results], gate_number)
      :fail ->
        IO.puts("[Gate #{gate_number}] FAIL — subsequent gates disabled")
        # Mark remaining gates as pending (not enabled)
        remaining = mark_remaining_pending(rest, gate_number + 1)
        run_gates_sequential([], config, remaining ++ [enriched | results], last_passed)
    end
  end

  defp mark_remaining_pending([], _next_gate), do: []

  defp mark_remaining_pending([mod | rest], next_gate) do
    gate_number = gate_number_for_module(mod)
    pending = %{
      gate_number: gate_number,
      gate_name: gate_name(gate_number),
      status: :pending,
      acceptance_criteria_met: false,
      metrics: %{reason: "Gate #{next_gate - 1} failed, this gate not enabled"},
      timestamp: :erlang.unique_integer([:positive]),
      duration_ms: 0
    }
    [pending | mark_remaining_pending(rest, next_gate)]
  end

  defp gate_number_for_module(mod) do
    Enum.find_index(all_gate_modules(), fn m -> m == mod end) + 1
  end

  defp run_all_gates_with_modules(gate_modules, config) do
    start_ms = System.monotonic_time(:millisecond)
    {results, last_passed} = run_gates_sequential(gate_modules, config, [], 0)

    passed = Enum.count(results, fn r -> r.status == :pass end)
    failed = Enum.count(results, fn r -> r.status == :fail end)
    pending = Enum.count(results, fn r -> r.status == :pending end)

    overall_status = cond do
      failed > 0 -> :failed
      pending > 0 -> :partial
      true -> :all_passed
    end

    next_enabled = if last_passed < length(gate_modules), do: last_passed + 1, else: length(gate_modules)

    {:ok, %{
      gates_passed: passed,
      gates_failed: failed,
      gates_pending: pending,
      overall_status: overall_status,
      last_passed_gate: last_passed,
      next_enabled_gate: next_enabled,
      gate_results: results,
      duration_ms: System.monotonic_time(:millisecond) - start_ms,
      timestamp: :erlang.unique_integer([:positive])
    }}
  end
end
