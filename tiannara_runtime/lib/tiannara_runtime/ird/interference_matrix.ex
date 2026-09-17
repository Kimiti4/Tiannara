defmodule TiannaraRuntime.IRD.InterferenceMatrix do
  @moduledoc """
  Phase 5F.12 — IRD Interference Matrix

  Computes interference between competing stabilizer proposals and flags
  situations where multiple interventions risk cascading destabilization.
  """

  use GenServer
  require Logger

  @critical_threshold 0.82

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{matrix: %{}, max_value: 0.0}}
  end

  @doc "Returns the critical interference threshold."
  def critical_threshold, do: @critical_threshold

  @doc "Computes the interference matrix for a list of stabilizer proposals."
  def compute(proposals) when is_list(proposals) do
    pairs = for a <- proposals, b <- proposals, a.observer_id != b.observer_id do
      {{a.observer_id, b.observer_id}, compute_pair_interference(a, b)}
    end

    matrix = Map.new(pairs)
    max_value = Enum.reduce(matrix, 0.0, fn {_pair, value}, acc -> max(acc, value) end)
    %{matrix: matrix, max_value: max_value}
  end

  defp compute_pair_interference(a, b) do
    overlap = phase_overlap(a.phase || 0.0, b.phase || 0.0)
    intensity_score = (a.intensity || 0.25) * (b.intensity || 0.25)
    priority_score = 1.0 - abs((a.priority || 0.5) - (b.priority || 0.5))

    clamp(overlap * intensity_score * priority_score, 0.0, 1.0)
  end

  defp phase_overlap(phase_a, phase_b) do
    distance = abs(phase_a - phase_b)
    1.0 - min(distance / 1.0, 1.0)
  end

  defp clamp(value, min_val, max_val) do
    value
    |> max(min_val)
    |> min(max_val)
  end
end
