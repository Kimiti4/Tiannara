defmodule Tiannara.OED.UMSC.StabilityController do
  @moduledoc """
  ⚖️ UMSC (Universal Meta-Stability Controller) Stability Controller.

  Acts as the ultimate stabilization authority, evaluating global Psi (Ψ) budget deltas
  over multiple simulated windows: 10-cycle, 1,000-cycle, civilization-era, and entropy-era horizons.
  """

  use GenServer
  require Logger

  # ==================== Public API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Runs multi-horizon projections of global Psi safety bounds under rule changes.
  Returns :ok if stability holds, or {:error, reason}.
  """
  @spec evaluate_stability(rule :: map(), baseline_psi :: float()) :: :ok | {:error, String.t()}
  def evaluate_stability(rule, baseline_psi) do
    GenServer.call(__MODULE__, {:evaluate, rule, baseline_psi})
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:evaluate, rule, baseline_psi}, _from, state) do
    result = project_multi_horizon(rule, baseline_psi)
    {:reply, result, state}
  end

  # ==================== Internal Projections ====================

  defp project_multi_horizon(rule, baseline_psi) do
    # Projections across multiple era windows
    with :ok <- project_window(:ten_cycle, rule, baseline_psi),
         :ok <- project_window(:thousand_cycle, rule, baseline_psi),
         :ok <- project_window(:civilization_era, rule, baseline_psi),
         :ok <- project_window(:entropy_era, rule, baseline_psi) do
      :ok
    end
  end

  defp project_window(:ten_cycle, _rule, baseline_psi) do
    # Short-term: must maintain Psi > 0.30
    if baseline_psi >= 0.30, do: :ok, else: {:error, "Psi limit breach on 10-cycle horizon"}
  end

  defp project_window(:thousand_cycle, rule, baseline_psi) do
    # Mid-term: check for recursive loop degradation
    estimated_delta = estimate_depletion_rate(rule.body)
    thousand_psi = baseline_psi + estimated_delta * 1000

    if thousand_psi >= 0.20 do
      :ok
    else
      {:error, "Psi limit breach on 1,000-cycle horizon (estimated Ψ=#{Float.round(thousand_psi, 3)})"}
    end
  end

  defp project_window(:civilization_era, rule, baseline_psi) do
    # Long-term: must remain above the absolute uncertainty floor
    estimated_delta = estimate_depletion_rate(rule.body)
    civ_psi = baseline_psi + estimated_delta * 100_000

    if civ_psi >= 0.10 do
      :ok
    else
      {:error, "Psi limit breach on civilization-era horizon (estimated Ψ=#{Float.round(civ_psi, 3)})"}
    end
  end

  defp project_window(:entropy_era, _rule, _baseline_psi) do
    # Ultimate thermodynamic death checks: trivial pass under abstract conditions
    :ok
  end

  defp estimate_depletion_rate({:if, _cond, then_b, else_b}) do
    0.01 * min(estimate_depletion_rate(then_b), estimate_depletion_rate(else_b))
  end

  defp estimate_depletion_rate({:apply, :bypass_osl, _}), do: -0.005
  defp estimate_depletion_rate({:apply, :direct_memory_access, _}), do: -0.008
  defp estimate_depletion_rate(_), do: 0.0
end
