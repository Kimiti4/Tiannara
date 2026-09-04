defmodule Tiannara.Math.Optimization do
  @doc "Unavailable: no truthful gradient descent implementation exists."
  def gradient_descent(_objective_fn, _grad_fn, _initial_params, _opts \\ []) do
    {:error, :gradient_descent_unavailable}
  end

  @doc "Unavailable: no truthful Nash equilibrium solver exists."
  def nash_equilibrium(_payoff_matrix, _entropy) do
    {:error, :nash_equilibrium_unavailable}
  end
end
