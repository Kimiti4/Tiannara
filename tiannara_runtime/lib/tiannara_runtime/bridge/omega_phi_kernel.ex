defmodule Tiannara.Bridge.OmegaPhiKernel do
  @moduledoc """
  Phase 5F.12: Omega-Phi Kernel - Core Coupling Engine
  
  Implements the bidirectional thermodynamic coupling between:
  - Ω (Omega): ontology density from OMCE
  - Φ (Phi): load pressure field from OLEF
  
  Mathematical Model:
    dΩ/dt = compression(Φ) - entropy_loss
    dΦ/dt = diffusion(Ω) - overload_gradient
    
  Stability Function:
    stability = 1.0 / (1.0 + |Ω - Φ|)
    
  When Ω ≈ Φ, system reaches equilibrium attractor state.
  """
  
  use GenServer
  require Logger

  # State structure
  defstruct [
    :omega,          # Ontology density (OMCE state)
    :phi,            # Load pressure field (OLEF state)
    :stability,      # System stability metric (0.0-1.0)
    :tick_count,     # Number of synchronization cycles
    :last_omega_delta,
    :last_phi_delta
  ]

  @default_omega 0.0
  @default_phi 0.0
  @compression_coefficient 0.02
  @load_coefficient 0.01
  @entropy_damping 0.1

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    initial_state = %__MODULE__{
      omega: @default_omega,
      phi: @default_phi,
      stability: 1.0,
      tick_count: 0,
      last_omega_delta: 0.0,
      last_phi_delta: 0.0
    }

    Logger.info("🌉 [5F.12 Bridge] Omega-Phi Kernel initialized")
    {:ok, initial_state}
  end

  @impl true
  def handle_call({:tick, omce_state, olef_state}, _from, state) do
    # Extract relevant metrics from OMCE and OLEF states
    omce_metrics = extract_omce_metrics(omce_state)
    olef_metrics = extract_olef_metrics(olef_state)

    # Compute new Ω and Φ values
    {new_omega, omega_delta} = compute_omega(omce_metrics, olef_metrics, state.omega)
    {new_phi, phi_delta} = compute_phi(olef_metrics, omce_metrics, state.phi)

    # Apply entropy balancing to prevent drift
    {balanced_omega, balanced_phi} = 
      Tiannara.Bridge.EntropyBalancer.balance(new_omega, new_phi)

    # Apply harmonic synchronization for oscillation control
    {synced_omega, synced_phi} = 
      Tiannara.Bridge.HarmonicSynchronizer.sync(balanced_omega, balanced_phi, state.tick_count)

    # Calculate stability metric
    new_stability = compute_stability(synced_omega, synced_phi)

    # Update state
    new_state = %{
      state
      | omega: synced_omega,
        phi: synced_phi,
        stability: new_stability,
        tick_count: state.tick_count + 1,
        last_omega_delta: omega_delta,
        last_phi_delta: phi_delta
    }

    # Log significant state changes
    if abs(omega_delta) > 0.1 or abs(phi_delta) > 0.1 do
      Logger.warning(
        "⚠️ [5F.12 Bridge] Large state change: ΔΩ=#{Float.round(omega_delta, 3)} ΔΦ=#{Float.round(phi_delta, 3)}"
      )
    end

    Logger.debug(
      "🔄 [5F.12 Bridge] Tick ##{state.tick_count}: Ω=#{Float.round(synced_omega, 4)} Φ=#{Float.round(synced_phi, 4)} S=#{Float.round(new_stability, 4)}"
    )

    {:reply, {:ok, new_state}, new_state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, {:ok, state}, state}
  end

  @doc """
  Get current stability metric.
  """
  def get_stability do
    GenServer.call(__MODULE__, :get_stability)
  end

  @impl true
  def handle_call(:get_stability, _from, state) do
    {:reply, state.stability, state}
  end

  @doc """
  Simulates a single step of Ω-Φ coupling functionally (for simulation/testing).
  """
  @spec step(map(), map(), map()) :: map()
  def step(state, olef_state, omce_state) do
    omce_metrics = %{
      compression_rate: Map.get(omce_state, :compression_rate, 0.5),
      ontology_size: Map.get(omce_state, :ontology_size, 0.0),
      memory_usage_mb: Map.get(omce_state, :memory_usage_mb, 0.0)
    }
    olef_metrics = %{
      global_pressure: Map.get(olef_state, :global_pressure, Map.get(olef_state, :pressure, 0.0)),
      pressure_field: Map.get(olef_state, :pressure_field, Map.get(olef_state, :pressure, 0.0)),
      node_count: Map.get(olef_state, :node_count, 1)
    }

    current_omega = Map.get(state, :omega, 0.0)
    current_phi = Map.get(state, :phi, 0.0)

    load_effect = olef_metrics.global_pressure * @load_coefficient
    entropy_loss = current_omega * @entropy_damping
    new_omega = clamp_value(omce_metrics.compression_rate + load_effect - entropy_loss, 0.0, 1.0)

    compression_effect = omce_metrics.ontology_size * @compression_coefficient
    diffusion = current_phi * @entropy_damping
    new_phi = clamp_value(olef_metrics.pressure_field + compression_effect - diffusion, 0.0, 1.0)

    {balanced_omega, balanced_phi} = Tiannara.Bridge.EntropyBalancer.balance(new_omega, new_phi)
    {synced_omega, synced_phi} = Tiannara.Bridge.HarmonicSynchronizer.sync(balanced_omega, balanced_phi, Map.get(state, :tick_count, 0))

    new_stability = 1.0 / (1.0 + abs(synced_omega - synced_phi))

    %{
      omega: synced_omega,
      phi: synced_phi,
      stability: new_stability,
      tick_count: Map.get(state, :tick_count, 0) + 1
    }
  end

  # --- Core Computation Functions ---

  @doc """
  Compute new Ω (ontology density) based on OLEF pressure feedback.
  
  Formula: Ω_new = Ω_base + (load_effect × coefficient) - entropy_loss
  """
  defp compute_omega(omce_metrics, olef_metrics, current_omega) do
    base_compression_rate = Map.get(omce_metrics, :compression_rate, 0.5)
    global_pressure = Map.get(olef_metrics, :global_pressure, 0.0)

    # OLEF → OMCE influence: higher load increases compression rate
    load_effect = global_pressure * @load_coefficient
    
    # Entropy loss term (prevents unbounded growth)
    entropy_loss = current_omega * @entropy_damping

    new_omega = base_compression_rate + load_effect - entropy_loss
    delta = new_omega - current_omega

    {clamp_value(new_omega, 0.0, 1.0), delta}
  end

  @doc """
  Compute new Φ (load pressure) based on OMCE compression feedback.
  
  Formula: Φ_new = Φ_base + (ontology_size × coefficient) - diffusion
  """
  defp compute_phi(olef_metrics, omce_metrics, current_phi) do
    base_pressure = Map.get(olef_metrics, :pressure_field, 0.0)
    ontology_size = Map.get(omce_metrics, :ontology_size, 0.0)

    # OMCE → OLEF influence: larger ontology increases load
    compression_effect = ontology_size * @compression_coefficient

    # Diffusion term (spreads load across nodes)
    diffusion = current_phi * @entropy_damping

    new_phi = base_pressure + compression_effect - diffusion
    delta = new_phi - current_phi

    {clamp_value(new_phi, 0.0, 1.0), delta}
  end

  @doc """
  Compute stability metric based on Ω-Φ divergence.
  
  Formula: stability = 1.0 / (1.0 + |Ω - Φ|)
  
  Returns 1.0 when perfectly balanced, approaches 0.0 as divergence increases.
  """
  defp compute_stability(omega, phi) do
    divergence = abs(omega - phi)
    1.0 / (1.0 + divergence)
  end

  # --- Helper Functions ---

  defp extract_omce_metrics(omce_state) do
    %{
      compression_rate: Map.get(omce_state, :compression_rate, 0.5),
      ontology_size: Map.get(omce_state, :ontology_size, 0.0),
      memory_usage_mb: Map.get(omce_state, :memory_usage_mb, 0.0)
    }
  end

  defp extract_olef_metrics(olef_state) do
    %{
      global_pressure: Map.get(olef_state, :global_pressure, 0.0),
      pressure_field: Map.get(olef_state, :pressure_field, 0.0),
      node_count: Map.get(olef_state, :node_count, 1)
    }
  end

  defp clamp_value(value, min_val, max_val) do
    value
    |> max(min_val)
    |> min(max_val)
  end
end
