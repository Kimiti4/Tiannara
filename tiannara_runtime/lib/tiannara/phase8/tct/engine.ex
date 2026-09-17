defmodule Tiannara.Phase8.TCT.Engine do
  @moduledoc """
  Transfinite Coherence Tensor (TCT) Simulation Engine.
  [Original Concept: Infinite Recursive Structure Governor]
  
  Computes Tₙ = Cₙ - Dₙ + Rₙ under bounded damping, external perturbation,
  and recursive coupling. Emits telemetry for convergence monitoring.
  """
  use GenServer
  require Logger

  @default_alpha 0.72  # Coherence damping
  @default_beta 0.68   # Divergence damping
  @default_gamma 0.76  # Resonance damping
  @convergence_epsilon 1.0e-6
  @max_steps 50_000

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    {:ok, %{
      c: Keyword.get(opts, :c_init, 0.5),
      d: Keyword.get(opts, :d_init, 0.5),
      r: Keyword.get(opts, :r_init, 0.3),
      step: 0,
      history: [],
      alpha: Keyword.get(opts, :alpha, @default_alpha),
      beta: Keyword.get(opts, :beta, @default_beta),
      gamma: Keyword.get(opts, :gamma, @default_gamma),
      running: false
    }}
  end

  @doc "Run simulation for N steps with optional telemetry streaming"
  @spec run(steps :: non_neg_integer(), stream_telemetry :: boolean()) :: {:ok, map()}
  def run(steps, stream_telemetry \\ true) do
    GenServer.call(__MODULE__, {:simulate, steps, stream_telemetry})
  end

  @impl true
  def handle_call({:simulate, max_steps, stream?}, _from, state) do
    if state.running, do: {:reply, {:error, :simulation_already_running}, state}

    steps = min(max_steps, @max_steps)
    final_state = Enum.reduce(1..steps, %{state | running: true}, fn _, s ->
      step(s, stream?)
    end)

    Logger.info("✅ TCT Simulation complete: #{steps} steps, final T=#{hd(final_state.history)}")
    {:reply, {:ok, Map.drop(final_state, [:history])}, %{final_state | running: false}}
  end

  defp step(%{c: c, d: d, r: r, step: n, history: hist} = state, stream?) do
    # Update coherence with resonance drive
    c_next = clamp(state.alpha * c + (1 - state.alpha) * coherence_drive(r))
    
    # Update divergence with stochastic perturbation
    d_next = clamp(state.beta * d + (1 - state.beta) * divergence_drive(c, perturbation(n)))
    
    # Update resonance with coupling
    r_next = clamp(state.gamma * r + (1 - state.gamma) * coupling(c_next, d_next))
    
    # Compute tensor
    t_next = c_next - d_next + r_next
    
    if stream?, do: emit_telemetry(n, c_next, d_next, r_next, t_next)
    
    %{state | c: c_next, d: d_next, r: r_next, step: n + 1, history: [t_next | hist]}
  end

  # --- Mathematical Drive Functions ---
  defp coherence_drive(r), do: 0.45 + 0.35 * r
  defp divergence_drive(c, noise), do: 0.40 * c + 0.25 + noise * 0.08
  defp coupling(c, d), do: 0.55 * (c + d) / 2.0
  defp perturbation(n), do: :math.sin(n / 12.0) * :math.cos(n / 7.0)
  defp clamp(x), do: max(0.0, min(1.0, x))

  defp emit_telemetry(step, c, d, r, t) do
    :telemetry.execute(
      [:tiannara, :phase8, :tct, :iteration],
      %{coherence: c, divergence: d, resonance: r, tensor: t},
      %{step: step, timestamp: System.system_time(:millisecond)}
    )
  end
end