defmodule Tiannara.OED.ACM.CausalAdversary do
  @moduledoc """
  ⚔️ ACM Causal Adversary.

  Simulates chronological paradoxes, causal loop injections, and timeline splits
  to verify rule resiliency across multi-history timelines.
  """

  require Logger

  @spec inject_paradox(rule :: map()) :: {:ok, map()} | {:error, String.t()}
  def inject_paradox(rule) do
    Logger.debug("⚔️ [Causal Adversary] Injecting timeline fork stress on #{rule.type}")

    try do
      # Simulate a retroactive loop mutation where the action is evaluated
      # in the past (by reducing the simulated recursion depth guard)
      mutated_body = inject_retroactive_loop(rule.body)
      {:ok, %{rule | body: mutated_body}}
    rescue
      e -> {:error, "Causal adversary injection failed: #{inspect(e)}"}
    end
  end

  # ==================== Internal Loop Injectors ====================

  defp inject_retroactive_loop({:if, {:<=, :compilation_depth, max_d}, then_branch, else_branch}) do
    # Drastically reduce max depth to force premature termination conflicts
    {:if, {:<=, :compilation_depth, max(1, max_d - 5)}, then_branch, else_branch}
  end

  defp inject_retroactive_loop({:if, cond, then_branch, else_branch}) do
    {:if, cond, inject_retroactive_loop(then_branch), inject_retroactive_loop(else_branch)}
  end

  defp inject_retroactive_loop(body) do
    # Wrap standard actions inside a retroactive condition check
    {:if, {:>, :time_dilation, 2.0}, body, :ignore}
  end
end
