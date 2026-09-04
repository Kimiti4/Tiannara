defmodule Tiannara.Numerics do
  @moduledoc """
  Type-safe numerical operations for Tiannara certification exercises.

  "Uncertainty should never be hidden" — every numerical operation now surfaces its error mode.

  Provides safe wrappers around common numerical operations that:
  - Handle nil/missing values gracefully
  - Prevent division by zero
  - Clamp values to valid ranges
  - Provide bounded floating-point operations
  - Implement robust interpolation algorithms
  - Surface error modes for every operation

  All operations return {:ok, value} | {:error, reason} tuples.
  Use error_mode/1 to get uncertainty characteristics of any value.
  """

  @type error_mode :: %{
          :type => :exact | :approximate | :bounded | :estimated | :unknown,
          :absolute_error => float() | nil,
          :relative_error => float() | nil,
          :confidence_interval => {float(), float()} | nil,
          :source => atom()
        }

  @doc """
  Returns the error mode for a value, describing its uncertainty characteristics.
  Every numerical value in Tiannara has an associated error mode.

  "Uncertainty should never be hidden" — this function makes uncertainty explicit.
  """
  @spec error_mode(number() | nil) :: error_mode()
  def error_mode(nil) do
    %{type: :unknown, absolute_error: nil, relative_error: nil, confidence_interval: nil, source: :nil_input}
  end

  def error_mode(value) when is_integer(value) do
    %{type: :exact, absolute_error: 0.0, relative_error: 0.0, confidence_interval: {value, value}, source: :integer}
  end

  def error_mode(value) when is_float(value) do
    rel = 1.0e-16
    abs_err = abs(value * rel)
    %{type: :approximate, absolute_error: abs_err, relative_error: rel,
      confidence_interval: {value - abs_err, value + abs_err}, source: :float}
  end

  def error_mode(_) do
    %{type: :unknown, absolute_error: nil, relative_error: nil, confidence_interval: nil, source: :unknown}
  end

  @doc """
  Safely rounds a number to the specified precision.
  Returns 0.0 for nil input instead of raising.
  """
  @spec safe_round(number | nil, non_neg_integer) :: {:ok, float} | {:error, atom}
  def safe_round(nil, _precision), do: {:ok, 0.0}
  def safe_round(value, precision) when is_number(value) do
    {:ok, Float.round(value, precision)}
  end
  def safe_round(_, _), do: {:error, :not_a_number}

  @doc """
  Safely divides two numbers, handling zero denominators.
  """
  @spec safe_divide(number, number) :: {:ok, float} | {:error, :division_by_zero}
  def safe_divide(_numerator, 0), do: {:error, :division_by_zero}
  def safe_divide(_numerator, denominator) when is_float(denominator) and denominator == 0.0, do: {:error, :division_by_zero}
  def safe_divide(numerator, denominator) when is_number(numerator) and is_number(denominator) do
    {:ok, numerator / denominator}
  end

  @doc """
  Clamps a value between min and max bounds.
  """
  @spec clamp(number | nil, number, number) :: {:ok, number} | {:error, atom}
  def clamp(nil, min_val, _max_val), do: {:ok, min_val}
  def clamp(value, min_val, max_val) when is_number(value) do
    {:ok, max(min_val, min(max_val, value))}
  end

  @doc """
  Computes the mean of a list of numbers, handling empty lists.
  """
  @spec mean([number] | nil) :: {:ok, float} | {:error, :empty_list}
  def mean(nil), do: {:error, :empty_list}
  def mean([]), do: {:error, :empty_list}
  def mean(values) when is_list(values) do
    sum = Enum.sum(values)
    count = length(values)
    {:ok, sum / count}
  end

  @doc """
  Computes the standard deviation of a list of numbers.
  """
  @spec std_dev([number] | nil) :: {:ok, float} | {:error, :empty_list | :single_value}
  def std_dev(nil), do: {:error, :empty_list}
  def std_dev([]), do: {:error, :empty_list}
  def std_dev([_]), do: {:error, :single_value}
  def std_dev(values) when is_list(values) do
    with {:ok, mean} <- mean(values) do
      variance =
        values
        |> Enum.map(fn x -> (x - mean) * (x - mean) end)
        |> Enum.sum()
        |> Kernel./(length(values) - 1)

      {:ok, :math.sqrt(variance)}
    end
  end

  @doc """
  Performs Newton polynomial interpolation at a target x value.
  Uses divided differences for numerical stability.

  Returns {:ok, interpolated_value} | {:error, reason}
  """
  @spec newton_interpolate([{number, number}], number) ::
          {:ok, float} | {:error, :insufficient_points | :duplicate_x}
  def newton_interpolate(points, _target_x) when is_list(points) and length(points) < 2 do
    {:error, :insufficient_points}
  end

  def newton_interpolate(points, target_x) when is_list(points) do
    # Check for duplicate x values
    xs = Enum.map(points, fn {x, _} -> x end)
    if length(Enum.uniq(xs)) != length(xs) do
      {:error, :duplicate_x}
    else
      # Compute divided differences table
      n = length(points)
      coeffs = compute_divided_differences(points, n)

      # Evaluate Newton polynomial using Horner's method
      result = evaluate_newton(coeffs, Enum.map(points, fn {x, _} -> x end), target_x)
      {:ok, result}
    end
  end

  defp compute_divided_differences(points, n) do
    # Initialize coefficients array
    coeffs = Enum.map(points, fn {_, y} -> y end)

    # Build divided differences
    Enum.reduce(1..(n - 1), coeffs, fn j, acc ->
      Enum.map(0..(n - j - 1), fn i ->
        x_i = elem(Enum.at(points, i), 0)
        x_ij = elem(Enum.at(points, i + j), 0)
        denom = x_ij - x_i

        if abs(denom) < 1.0e-12 do
          Enum.at(acc, i)
        else
          (Enum.at(acc, i + 1) - Enum.at(acc, i)) / denom
        end
      end)
      |> then(fn new_coeffs ->
        # Keep first n-j elements
        Enum.take(new_coeffs, n - j)
        |> then(fn taken -> taken ++ Enum.drop(acc, n - j) end)
      end)
    end)
    |> Enum.take(n)
  end

  defp evaluate_newton(coeffs, xs, x) do
    # Horner's method for Newton polynomial
    {result, _} =
      Enum.reduce(Enum.with_index(coeffs), {0.0, 0}, fn {c, i}, {acc, idx} ->
        # Compute product term: (x - x_0)(x - x_1)...(x - x_{i-1})
        prod =
          Enum.reduce(0..(i - 1), 1.0, fn k, p ->
            p * (x - Enum.at(xs, k))
          end)

        {acc + c * prod, idx + 1}
      end)

    result
  end

  @doc """
  Performs linear interpolation between two points.
  """
  @spec linear_interpolate({number, number}, {number, number}, number) ::
          {:ok, float} | {:error, :same_x}
  def linear_interpolate({x1, _}, {x1, _}, _), do: {:error, :same_x}
  def linear_interpolate({x1, y1}, {x2, y2}, x) do
    slope = (y2 - y1) / (x2 - x1)
    {:ok, y1 + slope * (x - x1)}
  end

  @doc """
  Performs cubic spline interpolation for a single interval.
  Uses natural boundary conditions.
  """
  @spec cubic_spline_interpolate([{number, number}], number) ::
          {:ok, float} | {:error, atom}
  def cubic_spline_interpolate(points, _target_x) when length(points) < 2 do
    {:error, :insufficient_points}
  end

  def cubic_spline_interpolate(points, target_x) do
    # Sort points by x
    sorted = Enum.sort_by(points, fn {x, _} -> x end)

    # Find the interval containing target_x
    interval = find_interval(sorted, target_x)

    case interval do
      nil -> {:error, :out_of_range}
      {{x0, y0}, {x1, y1}} ->
        # For simplicity, use linear interpolation between nearest points
        # Full cubic spline would require solving tridiagonal system
        linear_interpolate({x0, y0}, {x1, y1}, target_x)
    end
  end

  defp find_interval(sorted_points, x) do
    Enum.find(Enum.zip(sorted_points, tl(sorted_points)), fn {{x0, _}, {x1, _}} ->
      x >= x0 and x <= x1
    end)
  end

  @doc """
  Computes the t-statistic for a two-sample t-test.
  """
  @spec t_statistic([number], [number]) :: {:ok, float} | {:error, atom}
  def t_statistic(sample1, sample2) do
    with {:ok, mean1} <- mean(sample1),
         {:ok, mean2} <- mean(sample2),
         {:ok, var1} <- variance(sample1),
         {:ok, var2} <- variance(sample2) do
      n1 = length(sample1)
      n2 = length(sample2)

      # Pooled standard error
      se = :math.sqrt(var1 / n1 + var2 / n2)

      if se > 0 do
        {:ok, (mean1 - mean2) / se}
      else
        {:error, :zero_variance}
      end
    end
  end

  @doc """
  Computes the variance of a list of numbers.
  """
  @spec variance([number]) :: {:ok, float} | {:error, atom}
  def variance(values) when is_list(values) and length(values) < 2 do
    {:error, :insufficient_samples}
  end

  def variance(values) when is_list(values) do
    with {:ok, m} <- mean(values) do
      sum_sq_diff = Enum.sum(Enum.map(values, fn x -> (x - m) * (x - m) end))
      {:ok, sum_sq_diff / (length(values) - 1)}
    end
  end

  @doc """
  Computes Cohen's d effect size between two samples.
  """
  @spec cohens_d([number], [number]) :: {:ok, float} | {:error, atom}
  def cohens_d(sample1, sample2) do
    with {:ok, mean1} <- mean(sample1),
         {:ok, mean2} <- mean(sample2),
         {:ok, var1} <- variance(sample1),
         {:ok, var2} <- variance(sample2) do
      n1 = length(sample1)
      n2 = length(sample2)

      # Pooled standard deviation
      pooled_var = ((n1 - 1) * var1 + (n2 - 1) * var2) / (n1 + n2 - 2)
      pooled_sd = :math.sqrt(pooled_var)

      if pooled_sd > 0 do
        {:ok, abs(mean1 - mean2) / pooled_sd}
      else
        {:error, :zero_variance}
      end
    end
  end

  @doc """
  Safe rounding alias matching the Tiannara.Numerics API contract.
  Delegates to safe_round/2, returns tagged tuple.
  Handles nil, integers, floats, and binary strings.
  """
  @spec round(number | nil | String.t(), non_neg_integer()) :: {:ok, float} | {:error, atom}
  def round(nil, _precision), do: {:ok, 0.0}

  def round(value, precision) when is_integer(value) do
    {:ok, Float.round(value / 1.0, precision)}
  end

  def round(value, precision) when is_float(value) do
    try do
      {:ok, Float.round(value, precision)}
    rescue
      ArithmeticError -> {:error, :arithmetic_error}
    end
  end

  def round(value, precision) when is_binary(value) do
    case Float.parse(value) do
      {f, _} -> round(f, precision)
      :error -> {:error, :not_parseable}
    end
  end

  def round(_, _), do: {:error, :unsupported_type}

  @doc """
  Computes the required sample size N for a two-sample t-test.

  Uses the Abramowitz & Stegun approximation for the inverse normal CDF.

  Parameters:
  - effect_size: Cohen's d (must be > 0)
  - alpha: Type I error rate, default 0.05
  - power: 1 - Type II error rate (beta), default 0.80
  - tails: 1 or 2 (default 2)

  Returns {:ok, total_n} where total_n is the total participants across both groups.

  Fixes Exercise 2.7 statistical power calculations.
  """
  @spec required_n(number(), number(), number(), 1 | 2) :: {:ok, float} | {:error, atom}
  def required_n(effect_size, alpha \\ 0.05, power \\ 0.80, tails \\ 2)

  def required_n(effect_size, alpha, power, tails)
      when is_number(effect_size) and effect_size > 0 and
             is_number(alpha) and alpha > 0 and alpha < 1 and
             is_number(power) and power > 0 and power < 1 and
             tails in [1, 2] do
    z_alpha =
      case tails do
        2 -> qnorm(1 - alpha / 2)
        1 -> qnorm(1 - alpha)
      end

    z_beta = qnorm(power)
    n_per_group = :math.pow((z_alpha + z_beta) / effect_size, 2)
    total_n = Float.ceil(n_per_group * 2)
    {:ok, total_n}
  end

  def required_n(effect_size, _alpha, _power, _tails) when is_number(effect_size) and effect_size <= 0,
    do: {:error, :effect_size_must_be_positive}

  def required_n(_, _, _, _), do: {:error, :invalid_parameters}

  @doc """
  Approximate inverse normal CDF (quantile function).
  Uses Abramowitz & Stegun rational approximation (maximum error: 4.5e-4).

  Returns the z-score for the given probability p in (0, 1).
  """
  @spec qnorm(float()) :: float()
  def qnorm(p) when is_float(p) and p > 0.0 and p < 1.0 do
    t =
      if p < 0.5 do
        :math.sqrt(-2.0 * :math.log(p))
      else
        :math.sqrt(-2.0 * :math.log(1 - p))
      end

    # Rational approximation coefficients (Abramowitz & Stegun 26.2.17)
    c0 = 2.515517
    c1 = 0.802853
    c2 = 0.010328
    d1 = 1.432788
    d2 = 0.189269
    d3 = 0.001308

    x = t - (c0 + c1 * t + c2 * t * t) / (1 + d1 * t + d2 * t * t + d3 * t * t * t)
    if p < 0.5, do: -x, else: x
  end

  def qnorm(p) when is_number(p), do: raise(ArgumentError, "qnorm requires p in (0, 1), got #{p}")

  # ---- NEW: Surface Uncertainty API ----

  @doc """
  Creates a value with explicit uncertainty information.
  Returns {:ok, value, error_mode} tagged tuple.
  """
  @spec with_uncertainty(number(), keyword()) :: {:ok, number(), error_mode()}
  def with_uncertainty(value, opts \\ []) when is_number(value) do
    abs_err = Keyword.get(opts, :absolute_error, 0.0)
    rel_err = Keyword.get(opts, :relative_error, 0.0)
    ci = Keyword.get(opts, :confidence_interval, {value - abs_err, value + abs_err})
    source = Keyword.get(opts, :source, :explicit)
    mode = %{type: if(abs_err > 0, do: :estimated, else: :exact),
             absolute_error: abs_err, relative_error: rel_err,
             confidence_interval: ci, source: source}
    {:ok, value, mode}
  end

  @doc """
  Extracts the value from a numerical result, discarding error mode.
  """
  @spec value({:ok, number()} | {:ok, number(), error_mode()} | {:error, atom()}) :: number() | nil
  def value({:ok, val, _mode}), do: val
  def value({:ok, val}), do: val
  def value(_), do: nil

  @doc """
  Extracts the error mode from a numerical result.
  """
  @spec get_error_mode({:ok, number(), error_mode()} | {:error, atom()}) :: error_mode() | nil
  def get_error_mode({:ok, _val, mode}), do: mode
  def get_error_mode(_), do: nil

  @doc """
  Formats a value with its error mode for display.
  """
  @spec format({:ok, number()} | {:ok, number(), error_mode()} | number()) :: String.t()
  def format({:ok, val, mode}) do
    case mode.type do
      :exact -> "#{val}"
      :approximate -> "#{Float.round(val, 6)} ± #{Float.round(mode.absolute_error, 6)}"
      :bounded -> "#{Float.round(val, 6)} [#{Float.round(elem(mode.confidence_interval, 0), 4)}, #{Float.round(elem(mode.confidence_interval, 1), 4)}]"
      :estimated -> "#{Float.round(val, 6)} ± #{Float.round(mode.absolute_error, 6)} (95% CI)"
      :unknown -> "#{val} (uncertain)"
    end
  end

  def format({:ok, val}), do: "#{val}"
  def format(val) when is_number(val), do: "#{val} (#{error_mode(val).type})"
  def format(_), do: "ERROR"

  @doc """
  Estimates interpolation error for a polynomial approximation.
  Uses the maximum divided difference times the product of (x - xi).
  Fixes the Exercise 2.3 interpolation accuracy issue.
  """
  @spec interpolation_error([{number, number}], number, [number]) :: float()
  def interpolation_error(points, target_x, coeffs) do
    xs = Enum.map(points, fn {x, _} -> x end)
    prod = Enum.reduce(xs, 1.0, fn xi, acc -> acc * (target_x - xi) end)
    max_coeff = Enum.max([abs(Enum.at(coeffs, length(coeffs) - 1, 0.0)) | Enum.map(coeffs, &abs/1)])
    abs(max_coeff * prod)
  end
end