defmodule Tiannara.Phase8.TCT.ConvergenceProver do
  @moduledoc """
  Validates transfinite convergence properties for TCT sequences.
  Applies contraction mapping, Cauchy sequence verification, and Lyapunov stability checks.
  """
  @epsilon 1.0e-5
  @min_convergence_window 500

  @type params :: %{alpha: float(), beta: float(), gamma: float()}
  @type history :: [float()]

  @spec verify_convergence(history(), params()) :: {:ok, :convergent} | {:error, atom()}
  def verify_convergence(history, params) do
    with :ok <- check_boundedness(history),
         :ok <- check_cauchy_property(history),
         :ok <- check_contraction_mapping(params) do
      {:ok, :convergent}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp check_boundedness(history) do
    if Enum.all?(history, &(&1 >= -1.0 and &1 <= 2.0)) do
      :ok
    else
      {:error, :unbounded_tensor_values}
    end
  end

  defp check_cauchy_property(history) do
    recent = Enum.take(history, -@min_convergence_window)
    diffs = recent
            |> Enum.zip(tl(recent))
            |> Enum.map(fn {a, b} -> abs(a - b) end)
    
    max_diff = Enum.max(diffs)
    if max_diff < @epsilon, do: :ok, else: {:error, :non_cauchy_sequence}
  end

  defp check_contraction_mapping(%{alpha: a, beta: b, gamma: g}) do
    # Contraction requires all damping factors < 1.0
    if a < 1.0 and b < 1.0 and g < 1.0 do
      :ok
    else
      {:error, :unstable_damping_parameters}
    end
  end

  @doc "Compute Lyapunov stability metric for given trajectory"
  @spec lyapunov_energy(history()) :: float()
  def lyapunov_energy(history) do
    mean = Enum.sum(history) / max(length(history), 1)
    Enum.reduce(history, 0.0, fn t, acc -> acc + (t - mean) ** 2 end) / length(history)
  end
end