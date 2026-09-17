defmodule TiannaraRuntime.CausalDiscovery.IndependenceEngine do
  @moduledoc """
  Phase 17.3 — IndependenceEngine: constraint-based independence tests for causal discovery.
  Supports marginal (Pearson) and conditional (partial correlation) tests with
  Fisher z-transform p-values.
  """
  alias TiannaraRuntime.CausalDiscovery.IndependenceResult

  @doc """
  Compute marginal independence tests for all unordered pairs of variables.
  Variables are sorted canonically; test order is fixed.
  """
  @spec compute_all_pairs([String.t()], map(), keyword()) :: {:ok, [IndependenceResult.t()]}
  def compute_all_pairs(variables, evidence_set, opts \\ []) do
    sorted = Enum.sort(variables)
    pairs = for a <- sorted, b <- sorted, a < b, do: {a, b}
    results =
      Enum.reduce_while(pairs, {:ok, []}, fn {a, b}, {:ok, acc} ->
        case compute_marginal(a, b, evidence_set, opts) do
          {:ok, r} -> {:cont, {:ok, [r | acc]}}
          {:error, _} = err -> {:halt, err}
        end
      end)
    case results do
      {:ok, list} -> {:ok, Enum.reverse(list)}
      err -> err
    end
  end

  @doc """
  Compute conditional independence test: test if P(A,B|C) = P(A|C) * P(B|C).
  Uses partial correlation with Fisher z-transform for p-value.
  Deterministic: canonical data ordering, fixed seed.
  """
  @spec compute_conditional(String.t(), String.t(), [String.t()], map()) ::
          {:ok, IndependenceResult.t()} | {:error, String.t()}
  def compute_conditional(a, b, conditioning_set, evidence_set) do
    with {:ok, a_vals} <- extract_values(evidence_set, a),
         {:ok, b_vals} <- extract_values(evidence_set, b),
         {:ok, c_vals_list} <- extract_conditioning_values(evidence_set, conditioning_set),
         n <- length(a_vals),
         true <- n > length(conditioning_set) + 2 do
      r = partial_correlation(a_vals, b_vals, c_vals_list)
      z = fisher_z(r)
      dof = n - length(conditioning_set) - 3
      p = p_value_from_z(z, dof)
      stat = r
      conf = 1.0 - p

      {:ok, result} =
        IndependenceResult.new(
          variable_a: a,
          variable_b: b,
          conditioning_set: conditioning_set,
          test_type: :conditional,
          statistic: stat,
          p_value: p,
          confidence: conf,
          dof: dof,
          sample_size: n,
          evidence_root: nil,
          metadata: %{z_score: z}
        )
      {:ok, result}
    else
      false -> {:error, "insufficient sample size for conditional test"}
      {:error, _} = err -> err
    end
  end

  @doc """
  Compute marginal independence test using Pearson correlation.
  Converts to p-value via t-distribution approximation.
  """
  @spec compute_marginal(String.t(), String.t(), map(), keyword()) ::
          {:ok, IndependenceResult.t()} | {:error, String.t()}
  def compute_marginal(a, b, evidence_set, _opts \\ []) do
    with {:ok, a_vals} <- extract_values(evidence_set, a),
         {:ok, b_vals} <- extract_values(evidence_set, b),
         n <- length(a_vals),
         true <- n > 2 do
      r = correlation(a_vals, b_vals)
      z = fisher_z(r)
      dof = n - 3
      p = p_value_from_z(z, dof)
      stat = r
      conf = 1.0 - p

      {:ok, result} =
        IndependenceResult.new(
          variable_a: a,
          variable_b: b,
          conditioning_set: [],
          test_type: :marginal,
          statistic: stat,
          p_value: p,
          confidence: conf,
          dof: dof,
          sample_size: n,
          evidence_root: nil,
          metadata: %{z_score: z}
        )
      {:ok, result}
    else
      false -> {:error, "insufficient sample size (need > 2)"}
      {:error, _} = err -> err
    end
  end

  @doc """
  Test only pairs adjacent in the skeleton (PC algorithm optimization).
  """
  @spec compute_given_skeleton(TiannaraRuntime.CausalDiscovery.Skeleton.t(), map(), keyword()) ::
          {:ok, [IndependenceResult.t()]}
  def compute_given_skeleton(skeleton, evidence_set, opts \\ []) do
    adj = skeleton.adjacency
    pairs =
      adj
      |> Enum.flat_map(fn {node, neighbors} ->
        Enum.map(neighbors, fn n when node < n -> {node, n}; _ -> nil end)
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    results =
      Enum.reduce_while(pairs, {:ok, []}, fn {a, b}, {:ok, acc} ->
        case compute_marginal(a, b, evidence_set, opts) do
          {:ok, r} -> {:cont, {:ok, [r | acc]}}
          {:error, _} = err -> {:halt, err}
        end
      end)
    case results do
      {:ok, list} -> {:ok, Enum.reverse(list)}
      err -> err
    end
  end

  @doc """
  Returns the content-addressed ID of a result.
  """
  @spec result_fingerprint(IndependenceResult.t()) :: String.t()
  def result_fingerprint(%IndependenceResult{result_id: id}), do: id

  @doc """
  Replay results from a CausalRegistry root hash. Currently returns :not_found.
  """
  @spec replay_results(String.t()) :: {:error, :not_found}
  def replay_results(_independence_root), do: {:error, :not_found}

  # ── Statistical helpers ──────────────────────────────────────────

  @doc """
  Compute Pearson correlation coefficient r between two lists of numbers.
  """
  @spec correlation([number()], [number()]) :: float()
  def correlation(x_vals, y_vals) do
    n = length(x_vals)
    sx = Enum.sum(x_vals)
    sy = Enum.sum(y_vals)
    sxy = Enum.zip(x_vals, y_vals) |> Enum.reduce(0.0, fn {x, y}, a -> a + x * y end)
    sxx = Enum.reduce(x_vals, 0.0, fn x, a -> a + x * x end)
    syy = Enum.reduce(y_vals, 0.0, fn y, a -> a + y * y end)
    num = n * sxy - sx * sy
    den = :math.sqrt((n * sxx - sx * sx) * (n * syy - sy * sy))
    if abs(den) < 1.0e-15, do: 0.0, else: num / den
  end

  @doc """
  Compute partial correlation r_{xy|z} controlling for one or more conditioning variables.
  Uses the correlation-of-residuals approach for >1 conditioning variable,
  or the recursive formula for a single conditioning variable.
  """
  @spec partial_correlation([number()], [number()], [[number()]]) :: float()
  def partial_correlation(x_vals, y_vals, []) do
    correlation(x_vals, y_vals)
  end
  def partial_correlation(x_vals, y_vals, [c_vals]) do
    r_xy = correlation(x_vals, y_vals)
    r_xc = correlation(x_vals, c_vals)
    r_yc = correlation(y_vals, c_vals)
    num = r_xy - r_xc * r_yc
    den = :math.sqrt((1.0 - r_xc * r_xc) * (1.0 - r_yc * r_yc))
    if abs(den) < 1.0e-15, do: 0.0, else: num / den
  end
  def partial_correlation(x_vals, y_vals, c_list) do
    x_res = ols_residuals(x_vals, c_list)
    y_res = ols_residuals(y_vals, c_list)
    correlation(x_res, y_res)
  end

  @doc """
  Fisher z-transform: z = atanh(r) = 0.5 * ln((1+r)/(1-r))
  """
  @spec fisher_z(float()) :: float()
  def fisher_z(r) do
    clamped = max(-0.999999, min(0.999999, r))
    0.5 * :math.log((1.0 + clamped) / (1.0 - clamped))
  end

  @doc """
  Compute two-sided p-value from z-score and degrees of freedom.
  Uses the standard normal CDF approximation.
  """
  @spec p_value_from_z(float(), integer()) :: float()
  def p_value_from_z(z, _dof) do
    p_tail = 1.0 - normal_cdf(abs(z))
    min(1.0, 2.0 * p_tail)
  end

  # ── Private helpers ──────────────────────────────────────────────

  defp extract_values(evidence, var) do
    case Map.get(evidence, var) do
      nil -> {:error, "variable #{inspect(var)} not found in evidence_set"}
      vals when is_list(vals) and length(vals) > 0 -> {:ok, Enum.map(vals, &to_float/1)}
      _ -> {:error, "invalid or empty evidence for #{inspect(var)}"}
    end
  end

  defp extract_conditioning_values(evidence, vars) do
    result =
      Enum.reduce_while(vars, {:ok, []}, fn v, {:ok, acc} ->
        case extract_values(evidence, v) do
          {:ok, vals} -> {:cont, {:ok, [vals | acc]}}
          err -> {:halt, err}
        end
      end)
    case result do
      {:ok, list} -> {:ok, Enum.reverse(list)}
      err -> err
    end
  end

  defp to_float(v) when is_float(v), do: v
  defp to_float(v) when is_integer(v), do: v * 1.0
  defp to_float(_), do: 0.0

  defp ols_residuals(y_vals, predictor_lists) do
    n = length(y_vals)
    y_mean = Enum.sum(y_vals) / n
    pred_means = Enum.map(predictor_lists, fn pl -> Enum.sum(pl) / n end)
    coeffs = estimate_ols_coeffs(y_vals, predictor_lists, y_mean, pred_means)
    Enum.zip([y_vals | predictor_lists] |> Enum.zip_with(fn x -> x end))
    |> Enum.map(fn row ->
      y = hd(row)
      preds = tl(row)
      y_hat = Enum.zip(coeffs, [1.0 | preds]) |> Enum.reduce(0.0, fn {c, v}, a -> a + c * v end)
      y - y_hat
    end)
  end

  defp estimate_ols_coeffs(y_vals, predictor_lists, y_mean, pred_means) do
    k = length(predictor_lists)
    n = length(y_vals)
    centered_y = Enum.map(y_vals, &(&1 - y_mean))
    centered_preds = Enum.map(predictor_lists, fn pl ->
      pm = Enum.sum(pl) / n
      Enum.zip(pl, Stream.cycle([pm])) |> Enum.map(fn {v, m} -> v - m end)
    end)
    cov_xy = Enum.map(centered_preds, fn cp ->
      (Enum.zip(centered_y, cp) |> Enum.reduce(0.0, fn {y, p}, a -> a + y * p end)) / (n - 1)
    end)
    cov_xx = for i <- 0..(k-1), j <- 0..(k-1), i >= j, into: %{} do
      ci = Enum.at(centered_preds, i)
      cj = Enum.at(centered_preds, j)
      val = (Enum.zip(ci, cj) |> Enum.reduce(0.0, fn {a, b}, acc -> acc + a * b end)) / (n - 1)
      {{i, j}, val}
    end
    betas =
      if k == 1 do
        [(hd(cov_xy) / max(cov_xx[{0, 0}] || 1.0e-15, 1.0e-15))]
      else
        solve_linear_system(k, cov_xx, cov_xy)
      end
    intercept = y_mean
    Enum.zip(betas, pred_means) |> Enum.reduce(intercept, fn {b, m}, acc -> acc - b * m end)
    |> then(fn ic -> [ic | betas] end)
  end

  defp solve_linear_system(k, cov_xx, cov_xy) do
    Enum.map(0..(k-1), fn i ->
      diag = cov_xx[{i, i}] |> max(1.0e-15)
      Enum.at(cov_xy, i) / diag
    end)
  end

  defp normal_cdf(x) do
    0.5 * :math.erfc(-x / :math.sqrt(2.0))
  end
end
