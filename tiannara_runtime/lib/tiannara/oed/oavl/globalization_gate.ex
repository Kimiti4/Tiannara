defmodule Tiannara.OED.OAVL.GlobalizationGate do
  @moduledoc """
  📐 OAVL Globalization Gate.

  Enforces structural evolutionary gating by mapping out-of-bounds indicators
  and robustness scores to standard confidence levels:
  - `:rejected`
  - `:quarantined`
  - `:sandboxed`
  - `:local_only`
  - `:regionalized`
  - `:globally_safe`
  """

  use GenServer
  require Logger

  # ==================== Public API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Assigns a target globalization confidence level to the configuration rule.
  """
  @spec assess(rule :: map(), metrics :: map()) :: {:ok, atom()} | {:error, String.t()}
  def assess(rule, metrics) do
    GenServer.call(__MODULE__, {:assess, rule, metrics})
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:assess, rule, metrics}, _from, state) do
    level = determine_level(rule, metrics)
    Logger.info("📐 [Globalization Gate] Rule #{rule.type} assigned level: #{level}")
    {:reply, {:ok, level}, state}
  end

  # ==================== Internal Determination Logic ====================

  defp determine_level(rule, metrics) do
    robustness = Map.get(metrics, :robustness, 1.0)
    drift = Map.get(metrics, :drift, 0.0)
    cost = Map.get(metrics, :total_cost, 0.0)

    cond do
      # 1. Total rejection trigger: extremely low robustness or critical failures
      robustness < 0.3 ->
        :rejected

      # 2. Quarantine trigger: moderate robustness but semantic drift is high
      drift > 0.40 or Map.get(metrics, :failures, 0) > 0 ->
        :quarantined

      # 3. Sandbox trigger: high complexity overhead requiring isolation
      cost > 100.0 ->
        :sandboxed

      # 4. Local-only trigger: intermediate parameters
      robustness < 0.6 ->
        :local_only

      # 5. Regionalized trigger: high robustness but moderate complexity
      robustness < 0.80 ->
        :regionalized

      # 6. Globally Safe: flawless validation profile
      true ->
        :globally_safe
    end
  end
end
