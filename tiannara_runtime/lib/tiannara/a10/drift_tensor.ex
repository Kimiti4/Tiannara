defmodule Tiannara.A10.DriftTensor do
  @moduledoc """
  Maintains the 5D Drift Covariance Tensor.
  Calculates Magnitude, Acceleration, and Recovery Elasticity.
  """
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{
      samples: [],
      magnitude: 0.0,
      prev_magnitude: 0.0,
      velocity: 0.0,
      acceleration: 0.0,
      elasticity: 0.0,
      covariance: nil
    }}
  end

  def handle_cast({:record_sample, d_vector}, state) do
    # d_vector is [d_s, d_t, d_e, d_o, d_c]
    
    # Store up to N samples for covariance
    samples = [d_vector | state.samples] |> Enum.take(50)
    
    magnitude = calc_magnitude(d_vector)
    velocity = magnitude - state.magnitude
    acceleration = velocity - state.velocity
    elasticity = -velocity # E_r = - d||D|| / dt
    
    covariance = calc_covariance(samples)

    new_state = %{
      samples: samples,
      magnitude: magnitude,
      prev_magnitude: state.magnitude,
      velocity: velocity,
      acceleration: acceleration,
      elasticity: elasticity,
      covariance: covariance
    }

    # Cast to Analyzer
    GenServer.cast(Tiannara.A10.AttractorAnalyzer, {:analyze, new_state})

    {:noreply, new_state}
  end

  def handle_call(:get_tensor, _from, state) do
    {:reply, state, state}
  end

  defp calc_magnitude(d_vector) do
    sum_sq = Enum.reduce(d_vector, 0.0, fn val, acc -> acc + (val * val) end)
    :math.sqrt(sum_sq)
  end

  defp calc_covariance(samples) when length(samples) < 2, do: nil
  defp calc_covariance(samples) do
    n = length(samples)
    dims = length(hd(samples))

    # Calculate means
    means = Enum.reduce(0..(dims-1), [], fn i, acc ->
      sum = Enum.reduce(samples, 0.0, fn sample, s_acc -> s_acc + Enum.at(sample, i) end)
      acc ++ [sum / n]
    end)

    # Covariance Matrix: a list of lists (dims x dims)
    for i <- 0..(dims-1) do
      for j <- 0..(dims-1) do
        sum_cov = Enum.reduce(samples, 0.0, fn sample, acc ->
          dev_i = Enum.at(sample, i) - Enum.at(means, i)
          dev_j = Enum.at(sample, j) - Enum.at(means, j)
          acc + (dev_i * dev_j)
        end)
        sum_cov / (n - 1)
      end
    end
  end
end
