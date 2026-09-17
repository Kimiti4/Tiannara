defmodule Tiannara.OED.ACM.CivilizationDiscriminator do
  @moduledoc """
  ⚔️ ACM Civilization Discriminator.

  Analyzes candidate rules, isolating structural fallacies, contradictions,
  and malicious exploits injected by the generator or external adversaries.
  """

  use GenServer
  require Logger

  # ==================== Public API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Evaluates a candidate rule configuration for hidden logical loops, fallacies,
  or circular dependencies.
  """
  @spec scrutinize(rule :: map()) :: {:ok, :clean} | {:error, String.t()}
  def scrutinize(rule) do
    GenServer.call(__MODULE__, {:scrutinize, rule})
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:scrutinize, rule}, _from, state) do
    result = perform_scrutiny(rule)
    {:reply, result, state}
  end

  # ==================== Internal Scrutinizers ====================

  defp perform_scrutiny(rule) do
    cond do
      # 1. Circular logic checks
      :circular_reasoning in Map.get(rule, :invariants, []) ->
        {:error, "Circular logic loop detected in invariants"}

      # 2. Structural circular references in the AST
      contains_circular_evaluation?(rule.body) ->
        {:error, "Infinite self-evaluation detected in AST body"}

      # 3. Fallacy tracking (e.g. unconstrained jump operators)
      contains_unconstrained_fallacy?(rule.body) ->
        {:error, "Adversarial fallacy: unconstrained jump action found"}

      true ->
        {:ok, :clean}
    end
  end

  defp contains_circular_evaluation?({:apply, :evaluate, _}), do: true
  defp contains_circular_evaluation?({:if, _cond, then_b, else_b}) do
    contains_circular_evaluation?(then_b) or contains_circular_evaluation?(else_b)
  end
  defp contains_circular_evaluation?(_), do: false

  defp contains_unconstrained_fallacy?({:apply, :unconstrained_jump, _}), do: true
  defp contains_unconstrained_fallacy?({:if, _cond, then_b, else_b}) do
    contains_unconstrained_fallacy?(then_b) or contains_unconstrained_fallacy?(else_b)
  end
  defp contains_unconstrained_fallacy?(_), do: false
end
