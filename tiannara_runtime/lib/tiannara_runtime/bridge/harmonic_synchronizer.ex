defmodule Tiannara.Bridge.HarmonicSynchronizer do
  @moduledoc """
  Phase 5F.12: Harmonic Synchronizer - Oscillation Stabilizer
  
  Applies sinusoidal wave adjustments to Ω and Φ to prevent
  oscillation runaway and maintain smooth convergence.
  
  The wave pattern introduces controlled perturbation that helps
  the system escape local minima during equilibrium seeking.
  
  Formula:
    ω_adj = ω + sin(t/10) × 0.05
    φ_adj = φ - sin(t/10) × 0.05
  
  Note: Adjustments are opposite in sign to maintain conservation.
  """

  @wave_amplitude 0.05
  @wave_period_divisor 10.0

  @doc """
  Apply harmonic synchronization to Ω and Φ.
  
  ## Parameters
  - omega: Current ontology density
  - phi: Current load pressure
  - t: Time tick (monotonically increasing counter)
  
  ## Returns
  {adjusted_omega, adjusted_phi} tuple with wave-modulated values
  """
  def sync(omega, phi, t) when is_number(omega) and is_number(phi) and is_number(t) do
    wave = :math.sin(t / @wave_period_divisor)
    
    omega_adj = omega + wave * @wave_amplitude
    phi_adj = phi - wave * @wave_amplitude
    
    {omega_adj, phi_adj}
  end

  @doc """
  Apply harmonic synchronization with adaptive amplitude.
  
  Reduces wave amplitude when system is near equilibrium to avoid
  unnecessary perturbation.
  
  ## Parameters
  - omega: Current ontology density
  - phi: Current load pressure
  - t: Time tick
  - stability: Current stability metric (0.0-1.0)
  
  ## Returns
  {adjusted_omega, adjusted_phi} with stability-adaptive modulation
  """
  def sync_adaptive(omega, phi, t, stability) do
    # Reduce amplitude when system is stable
    adaptive_amplitude = @wave_amplitude * (1.0 - stability * 0.5)
    
    wave = :math.sin(t / @wave_period_divisor)
    
    omega_adj = omega + wave * adaptive_amplitude
    phi_adj = phi - wave * adaptive_amplitude
    
    {omega_adj, phi_adj}
  end

  @doc """
  Calculate phase difference between current state and target equilibrium.
  
  Useful for diagnosing oscillation patterns and tuning wave parameters.
  
  ## Parameters
  - omega: Current ontology density
  - phi: Current load pressure
  - t: Time tick
  
  ## Returns
  Phase angle in radians representing position in oscillation cycle
  """
  def calculate_phase(omega, phi, t) do
    # Phase is derived from the sine wave at current time
    :math.sin(t / @wave_period_divisor)
  end

  @doc """
  Generate diagnostic report on harmonic synchronization state.
  
  ## Parameters
  - omega: Current ontology density
  - phi: Current load pressure
  - t: Time tick
  
  ## Returns
  Map containing synchronization diagnostics
  """
  def generate_diagnostics(omega, phi, t) do
    wave = :math.sin(t / @wave_period_divisor)
    omega_adjustment = wave * @wave_amplitude
    phi_adjustment = -wave * @wave_amplitude
    
    %{
      current_tick: t,
      wave_value: wave,
      omega_adjustment: omega_adjustment,
      phi_adjustment: phi_adjustment,
      adjusted_omega: omega + omega_adjustment,
      adjusted_phi: phi + phi_adjustment,
      period_position: rem(t, trunc(:math.pi() * 2 * @wave_period_divisor)),
      amplitude: @wave_amplitude
    }
  end

  @doc """
  Check if system is in constructive or destructive interference pattern.
  
  Constructive interference helps convergence; destructive may cause instability.
  
  ## Parameters
  - omega_delta: Rate of change of Ω
  - phi_delta: Rate of change of Φ
  - wave_direction: Direction of current wave adjustment (+1 or -1)
  
  ## Returns
  :constructive | :destructive indicating interference pattern
  """
  def interference_pattern(omega_delta, phi_delta, wave_direction) do
    # If both deltas move in same direction as wave, it's constructive
    omega_aligned = (omega_delta * wave_direction) > 0
    phi_aligned = (phi_delta * wave_direction) < 0  # Phi moves opposite
    
    if omega_aligned and phi_aligned do
      :constructive
    else
      :destructive
    end
  end
end
