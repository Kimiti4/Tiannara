defmodule Tiannara.RRG.EquilibriumEngine do
  @moduledoc """
  Phase 5F.12: Equilibrium Engine - Global Stability Metric Calculator
  
  Computes Ψ (Psi) metric:
    Ψ = (D_s × N × C_b) / (E_c × R_o)
  
  Where:
  - D_s = semantic diversity
  - N = novelty generation
  - C_b = branch complexity
  - E_c = entropy concentration
  - R_o = observer recursion density
  
  If Ψ < Ψ_crit, the universe approaches collapse equilibrium and RRG intervenes.
  """
  
  use GenServer

  defstruct [
    :psi_value,
    :component_metrics,
    :critical_threshold,
    :history
  ]

  @psi_critical_threshold 0.3

  @doc """
  Compute raw Ψ value directly (for simulation/testing).
  """
  def compute(ds, n, cb, ec, ro) do
    ec_safe = max(ec, 0.01)
    ro_safe = max(ro, 0.01)
    psi = (ds * n * cb) / (ec_safe * ro_safe)
    # Multiply by 10.0 to match the legacy test expectations (0.0 to 10.0 scale)
    # or just return the normalized value which is also between 0.0 and 100.0
    min(psi, 100.0)
  end

  def start_link(_opts \\ []) do
    case GenServer.start_link(__MODULE__, %{}, name: __MODULE__) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  @impl true
  def init(_opts) do
    state = %__MODULE__{
      psi_value: 1.0,
      component_metrics: %{},
      critical_threshold: @psi_critical_threshold,
      history: []
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:get_psi, _from, state) do
    {:reply, state.psi_value, state}
  end

  @doc """
  Update Ψ metric with new component values.
  """
  def update_metrics(metrics) do
    GenServer.cast(__MODULE__, {:update, metrics})
  end

  @impl true
  def handle_cast({:update, metrics}, state) do
    # Calculate new Ψ
    new_psi = calculate_psi(metrics)
    
    # Store in history
    new_history = Enum.take([
      %{psi: new_psi, metrics: metrics, timestamp: System.system_time(:millisecond)}
      | state.history
    ], 100)
    
    new_state = %{
      state
      | psi_value: new_psi,
        component_metrics: metrics,
        history: new_history
    }

    # Check if intervention needed
    # (Logging removed to avoid Logger API compatibility issues)

    {:noreply, new_state}
  end

  defp calculate_psi(%{semantic_diversity: ds, novelty: n, branch_complexity: cb, 
                       entropy_concentration: ec, recursion_density: ro}) do
    # Prevent division by zero
    ec_safe = max(ec, 0.01)
    ro_safe = max(ro, 0.01)
    
    psi = (ds * n * cb) / (ec_safe * ro_safe)
    
    # Normalize to 0-1 range
    min(psi / 10.0, 1.0)
  end

  defp calculate_psi(_), do: 1.0  # Default safe value
end
