defmodule Tiannara.OPC.Validation.SingularityDetector do
  @moduledoc """
  Phase 5F.6 — Singularity Detector

  Scans observer physics AST for mathematical singularities that could cause
  runtime explosions (division by zero, infinite recursion, asymptotic blowup).

  ## Detection Targets

  - Division operations with potentially zero denominators
  - Logarithms of values that could reach zero or negative
  - Square roots of potentially negative values
  - Exponential functions with unbounded growth
  - Recursive tensor operations without termination conditions

  ## Usage

      ast = {:op, :/, [{:const, 1.0}, {:var, :x}]}
      case SingularityDetector.scan(ast) do
        :ok -> IO.puts("No singularities detected")
        {:error, :potential_div_zero} -> IO.puts("Division by zero risk")
      end
  """

  require Logger

  @doc """
  Scans AST for potential singularities.

  ## Returns
  - `:ok` — No singularities detected
  - `{:error, reason}` — Singularity risk identified

  ## Example

      # Safe division (denominator has epsilon regularization)
      safe_ast = {:op, :/, [
        {:const, 1.0},
        {:op, :sqrt, [{:op, :+, [{:op, :pow, [{:var, :x}, 2]}, {:const, 0.001}]}]}
      ]}
      :ok = SingularityDetector.scan(safe_ast)

      # Unsafe division (raw denominator could be zero)
      unsafe_ast = {:op, :/, [{:const, 1.0}, {:var, :x}]}
      {:error, :potential_div_zero} = SingularityDetector.scan(unsafe_ast)
  """
  def scan(ast) do
    Logger.debug("🔍 [SingularityDetector] Scanning AST for singularities...")

    singularities = find_singularities(ast, [])

    if Enum.empty?(singularities) do
      Logger.debug("✅ [SingularityDetector] No singularities detected")
      :ok
    else
      first_singularity = hd(singularities)
      Logger.warning("⚠️ [SingularityDetector] Singularity detected: #{inspect(first_singularity)}")
      {:error, first_singularity}
    end
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp find_singularities({:op, :/, [_numerator, denominator]}, acc) do
    # Check if denominator could reach zero
    if could_be_zero?(denominator) do
      [:potential_div_zero | acc]
    else
      acc
    end
  end

  defp find_singularities({:op, :log, [argument]}, acc) do
    # Logarithm requires argument > 0
    if could_be_non_positive?(argument) do
      [:log_domain_violation | acc]
    else
      acc
    end
  end

  defp find_singularities({:op, :sqrt, [argument]}, acc) do
    # Square root requires argument >= 0
    if could_be_negative?(argument) do
      [:sqrt_domain_violation | acc]
    else
      acc
    end
  end

  defp find_singularities({:op, :exp, [argument]}, acc) do
    # Exponential can overflow if argument too large
    if could_overflow?(argument) do
      [:exponential_overflow | acc]
    else
      acc
    end
  end

  # Recursively check nested operations
  defp find_singularities({:op, _op_name, args}, acc) when is_list(args) do
    Enum.reduce(args, acc, fn arg, accumulator ->
      find_singularities(arg, accumulator)
    end)
  end

  defp find_singularities(list, acc) when is_list(list) do
    Enum.reduce(list, acc, fn item, accumulator ->
      find_singularities(item, accumulator)
    end)
  end

  # Leaf nodes don't have singularities
  defp find_singularities(_leaf, acc), do: acc

  # ── Domain Analysis Helpers ───────────────────────────────────────────────

  defp could_be_zero?({:const, value}), do: value == 0
  defp could_be_zero?({:var, _name}), do: true  # Variables could be anything
  defp could_be_zero?({:op, :+, args}), do: Enum.any?(args, &could_be_zero?/1)
  defp could_be_zero?({:op, :*, args}), do: Enum.any?(args, &could_be_zero?/1)
  defp could_be_zero?({:op, :sqrt, [_arg]}), do: false  # sqrt always >= 0
  defp could_be_zero?(_other), do: false

  defp could_be_non_positive?({:const, value}), do: value <= 0
  defp could_be_non_positive?({:var, _name}), do: true
  defp could_be_non_positive?({:op, :abs, [_arg]}), do: false  # abs always >= 0
  defp could_be_non_positive?(_other), do: false

  defp could_be_negative?({:const, value}), do: value < 0
  defp could_be_negative?({:var, _name}), do: true
  defp could_be_negative?({:op, :pow, [_base, exp]}) when is_number(exp) and rem(exp, 2) == 0, do: false
  defp could_be_negative?(_other), do: false

  defp could_overflow?({:const, value}), do: value > 1000
  defp could_overflow?({:var, _name}), do: true
  defp could_overflow?(_other), do: false
end
