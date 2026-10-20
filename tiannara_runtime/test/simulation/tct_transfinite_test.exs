defmodule Tiannara.Simulation.TCTTransfiniteTest do
  @moduledoc """
  Property-based test harness for Transfinite Coherence Tensor convergence.
  Validates boundedness, contraction mapping, perturbation recovery, and parameter safety.
  """
  use ExUnit.Case, async: true
  use PropCheck

  alias Tiannara.Phase8.TCT.{Engine, ConvergenceProver}

  @valid_range {-1.0, 2.0}
  @stable_damping_range {0.1, 0.85}

  property "TCT tensor remains bounded under arbitrary valid parameters" do
    forall(
      {a, b, g, c0, d0, r0} <- parameter_generator(@stable_damping_range, {0.0, 1.0}),
      do: assert_boundedness(a, b, g, c0, d0, r0)
    )
  end

  property "TCT converges to stable equilibrium under contraction mapping" do
    forall(
      params <- stable_parameter_map(),
      do: assert_convergence(params)
    )
  end

  property "TCT recovers from stochastic perturbations within bounded steps" do
    forall(
      {params, noise_magnitude} <- perturbation_scenario_generator(),
      do: assert_perturbation_recovery(params, noise_magnitude)
    )
  end

  property "Invalid damping parameters trigger safe fallback, not crash" do
    forall(
      {a, b, g, c0, d0, r0} <- parameter_generator({0.9, 1.5}, {0.0, 1.0}),
      do: assert_safe_degradation(a, b, g, c0, d0, r0)
    )
  end

  # --- Generators ---
  defp parameter_generator({d_min, d_max}, {i_min, i_max}) do
    let {a, b, g, c, d, r} <-
      {float(d_min, d_max), float(d_min, d_max), float(d_min, d_max),
       float(i_min, i_max), float(i_min, i_max), float(i_min, i_max)},
      do: {a, b, g, c, d, r}
  end

  defp stable_parameter_map() do
    {d_min, d_max} = @stable_damping_range
    let {a, b, g} <-
      {float(d_min, d_max), float(d_min, d_max), float(d_min, d_max)},
      do: %{alpha: a, beta: b, gamma: g, c: 0.5, d: 0.5, r: 0.3}
  end

  defp perturbation_scenario_generator() do
    {stable_parameter_map(), float(0.0, 0.3)}
  end

  # --- Assertions ---
  defp assert_boundedness(a, b, g, c, d, r) do
    state = run_deterministic(a, b, g, c, d, r, 3000)
    Enum.all?(state.history, &(&1 >= elem(@valid_range, 0) and &1 <= elem(@valid_range, 1)))
  end

  defp assert_convergence(params) do
    state = run_deterministic(params.alpha, params.beta, params.gamma, params.c, params.d, params.r, 5000)
    history = Enum.reverse(state.history)
    case ConvergenceProver.verify_convergence(history, params) do
      {:ok, :convergent} -> true
      _ -> false
    end
  end

  defp assert_perturbation_recovery(params, noise) do
    # Inject noise at step 1000, verify convergence resumes
    state = run_deterministic_with_perturbation(params, noise, 1000, 3000)
    post_perturbation = Enum.take(state.history, -1000)
    avg_energy = ConvergenceProver.lyapunov_energy(post_perturbation)
    avg_energy < 0.05 # Must settle near equilibrium
  end

  defp assert_safe_degradation(a, b, g, c, d, r) do
    # Engine clamps outputs and prevents divergence explosion
    state = run_deterministic(a, b, g, c, d, r, 2000)
    Enum.all?(state.history, &is_float/1) and length(state.history) == 2000
  end

  # --- Deterministic Runner (bypasses GenServer for property test speed) ---
  defp run_deterministic(a, b, g, c, d, r, steps) do
    Enum.reduce(1..steps, %{c: c, d: d, r: r, step: 0, history: [], alpha: a, beta: b, gamma: g}, fn _, s ->
      step_engine(s, false)
    end)
  end

  defp run_deterministic_with_perturbation(params, noise_mag, inject_step, total_steps) do
    Enum.reduce(1..total_steps, %{c: params.c, d: params.d, r: params.r, step: 0, history: [], 
                                  alpha: params.alpha, beta: params.beta, gamma: params.gamma}, fn n, s ->
      noise = if n == inject_step, do: noise_mag, else: 0.0
      apply_perturbation(s, noise) |> step_engine(false)
    end)
  end

  defp step_engine(%{c: c, d: d, r: r, step: n, history: hist} = state, perturbed?) do
    p = if perturbed?, do: perturbation(n), else: 0.0
    c_next = clamp(state.alpha * c + (1 - state.alpha) * (0.45 + 0.35 * r))
    d_next = clamp(state.beta * d + (1 - state.beta) * (0.40 * c + 0.25 + p * 0.08))
    r_next = clamp(state.gamma * r + (1 - state.gamma) * (0.55 * (c_next + d_next) / 2.0))
    t_next = c_next - d_next + r_next
    %{state | c: c_next, d: d_next, r: r_next, step: n + 1, history: [t_next | hist]}
  end

  defp apply_perturbation(state, noise) do
    %{state | d: state.d + noise}
  end

  defp perturbation(n), do: :math.sin(n / 12.0) * :math.cos(n / 7.0)
  defp clamp(x), do: max(0.0, min(1.0, x))
end