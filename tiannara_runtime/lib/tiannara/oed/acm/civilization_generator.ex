defmodule Tiannara.OED.ACM.CivilizationGenerator do
  @moduledoc """
  ⚔️ ACM Civilization Generator.

  Generates extreme edge-case mock configurations and adversarial theories
  (circular logic, self-reference traps, logical fallacies) to stress-test candidate rules.
  """

  use GenServer
  require Logger

  # ==================== Public API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Mutates a stable rule to inject a specific class of adversarial flaw for testing.
  """
  @spec inject_adversarial_flaw(rule :: map(), type :: :circular | :self_reference | :fallacy | :exploit) :: map()
  def inject_adversarial_flaw(rule, type) do
    GenServer.call(__MODULE__, {:inject, rule, type})
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:inject, rule, type}, _from, state) do
    flawed_rule = apply_flaw(rule, type)
    {:reply, flawed_rule, state}
  end

  # ==================== Internal Flaw Injectors ====================

  defp apply_flaw(%{body: body} = rule, :circular) do
    # Inject circular dependancies: A relies on B which relies on A
    circular_body = {:if, {:==, :state_active, true}, {:apply, :evaluate, [body]}, {:apply, :evaluate, [body]}}
    %{rule | body: circular_body, invariants: [:circular_reasoning | rule.invariants]}
  end

  defp apply_flaw(rule, :self_reference) do
    # Inject self-reference recursion loops
    self_ref_body = {:if, {:<=, :compilation_depth, 10}, {:apply, :modify_rule, [rule.type]}, :ignore}
    %{rule | body: self_ref_body}
  end

  defp apply_flaw(rule, :fallacy) do
    # Inject a logic fallacy (e.g. division by zero or invalid type comparisons)
    fallacy_body = {:if, {:>, :entropy_level, 0.9}, {:apply, :unconstrained_jump, []}, rule.body}
    # Obscure the source/provenance to simulate disinformer activity
    %{rule | body: fallacy_body, invariants: Enum.filter(rule.invariants, &(&1 != :observer_safety))}
  end

  defp apply_flaw(rule, :exploit) do
    # Inject direct memory access or OS bypass exploit attempts
    exploit_body = {:apply, :bypass_osl, [rule.body]}
    %{rule | body: exploit_body}
  end

  defp apply_flaw(rule, _other), do: rule
end
