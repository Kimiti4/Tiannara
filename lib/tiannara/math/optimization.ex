defmodule Tiannara.Math.Optimization do
  @moduledoc """
  Bounded numerical optimization primitives.

  These routines perform real computation but do not certify global optimality.
  Results are numerical candidates with explicit convergence diagnostics.
  """

  @max_iterations 100_000
  @default_tolerance 1.0e-8
  @min_learning_rate 1.0e-15

  @spec gradient_descent(function(), function(), [number()], keyword()) ::
          {:ok, map()} | {:error, term()}
  def gradient_descent(objective_fn, grad_fn, initial_params, opts \\ [])
      when is_function(objective_fn, 1) and is_function(grad_fn, 1) and is_list(initial_params) do
    with :ok <- validate_vector(initial_params),
         {:ok, learning_rate} <- positive_option(opts, :learning_rate, 0.01),
         {:ok, tolerance} <- positive_option(opts, :tolerance, @default_tolerance),
         {:ok, max_iterations} <- integer_option(opts, :max_iterations, 10_000),
         :ok <- validate_limit(max_iterations) do
      iterate(objective_fn, grad_fn, floats(initial_params), learning_rate, tolerance, max_iterations, 0)
    end
  rescue
    ArithmeticError -> {:error, :non_finite_objective_or_gradient}
    FunctionClauseError -> {:error, :invalid_objective_or_gradient}
  end

  @doc "Nash equilibrium remains unavailable; gradient descent is not a game solver."
  def nash_equilibrium(_payoff_matrix, _entropy), do: {:error, :nash_equilibrium_unavailable}

  defp iterate(objective, gradient, params, lr, tolerance, max_iterations, iteration) do
    objective_value = objective.(params)
    grad = gradient.(params)

    with :ok <- validate_scalar(objective_value), :ok <- validate_vector(grad) do
      grad = floats(grad)
      norm = euclidean_norm(grad)

      cond do
        norm <= tolerance ->
          {:ok, result(params, objective_value, iteration, true, :gradient_tolerance, norm)}

        iteration >= max_iterations ->
          {:ok, result(params, objective_value, iteration, false, :max_iterations, norm)}

        lr < @min_learning_rate ->
          {:ok, result(params, objective_value, iteration, false, :learning_rate_underflow, norm)}

        true ->
          next = Enum.zip_with(params, grad, fn p, g -> p - lr * g end)

          if Enum.all?(next, &finite_number?/1) do
            next_objective = objective.(next)

            cond do
              not finite_number?(next_objective) ->
                {:error, :non_finite_objective_or_gradient}

              next_objective <= objective_value ->
                iterate(objective, gradient, next, lr, tolerance, max_iterations, iteration + 1)

              true ->
                iterate(objective, gradient, params, lr / 2.0, tolerance, max_iterations, iteration + 1)
            end
          else
            {:error, :non_finite_parameters}
          end
        end
      end
    end

  defp result(params, objective, iterations, converged, termination, gradient_norm) do
    %{params: params, objective: objective / 1.0, iterations: iterations,
      converged: converged, termination: termination, gradient_norm: gradient_norm,
      optimality: :local_stationary_candidate, certification_eligible: false}
  end

  defp validate_vector(values) do
    if values != [] and Enum.all?(values, &finite_number?/1) do
      :ok
    else
      {:error, :invalid_vector}
    end
  end

  defp validate_scalar(value) do
    if finite_number?(value) do
      :ok
    else
      {:error, :non_finite_objective_or_gradient}
    end
  end

  defp positive_option(opts, key, default) do
    value = Keyword.get(opts, key, default)

    if is_number(value) and finite_number?(value) and value > 0 do
      {:ok, value / 1.0}
    else
      {:error, {:invalid_option, key}}
    end
  end

  defp integer_option(opts, key, default) do
    value = Keyword.get(opts, key, default)

    if is_integer(value) do
      {:ok, value}
    else
      {:error, {:invalid_option, key}}
    end
  end

  defp validate_limit(value) when value > 0 and value <= @max_iterations, do: :ok
  defp validate_limit(_), do: {:error, :iteration_limit_exceeded}
  defp floats(values), do: Enum.map(values, &(&1 / 1.0))
  defp euclidean_norm(values), do: :math.sqrt(Enum.reduce(values, 0.0, fn x, acc -> acc + x * x end))
  defp finite_number?(x), do: is_number(x) and x == x and x > -1.7976931348623157e308 and x < 1.7976931348623157e308
end
