defmodule Tiannara.CIS.EntropyBalancerFix do
  @moduledoc """
  Entropy Balancer Bridge (EBF)

  Acts as the stabilizing interface between:
  - GRCC ecological entropy field
  - CIS immune regulation layer
  - MSCL constraint pressure system
  - OLEF load equilibrium diffusion field

  Purpose:
  Prevent entropy oscillation collapse and enforce stable adaptive range.
  """

  use GenServer
  require Logger

  @target_entropy 0.68
  @min_entropy 0.60
  @max_entropy 0.75

  @damping_factor 0.35
  @correction_gain 1.2

  # ----------------------------
  # Public API
  # ----------------------------

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def update_entropy(value) when is_number(value) do
    GenServer.cast(__MODULE__, {:entropy_update, value})
  end

  def get_state do
    GenServer.call(__MODULE__, :state)
  end

  # ----------------------------
  # GenServer lifecycle
  # ----------------------------

  def init(_) do
    state = %{
      current_entropy: @target_entropy,
      entropy_history: [],
      oscillation_index: 0.0,
      correction_signal: 0.0,
      stability_score: 1.0
    }

    {:ok, state}
  end

  # ----------------------------
  # Core Update Loop
  # ----------------------------

  def handle_cast({:entropy_update, entropy}, state) do
    history = [entropy | Enum.take(state.entropy_history, 49)]

    oscillation = compute_oscillation(history)
    deviation = entropy - @target_entropy

    correction = compute_correction(deviation, oscillation)

    new_state =
      state
      |> Map.put(:current_entropy, entropy)
      |> Map.put(:entropy_history, history)
      |> Map.put(:oscillation_index, oscillation)
      |> Map.put(:correction_signal, correction)
      |> Map.put(:stability_score, compute_stability(entropy, oscillation))

    dispatch_corrections(correction, entropy)

    {:noreply, new_state}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  # ----------------------------
  # Core Mathematics Layer
  # ----------------------------

  defp compute_oscillation(history) when length(history) < 2, do: 0.0

  defp compute_oscillation(history) do
    diffs =
      history
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [a, b] -> abs(a - b) end)

    Enum.sum(diffs) / max(length(diffs), 1)
  end

  defp compute_correction(deviation, oscillation) do
    base =
      -deviation
      |> Kernel.*(@correction_gain)

    damping = 1.0 / (1.0 + oscillation * @damping_factor)

    base * damping
  end

  defp compute_stability(entropy, oscillation) do
    entropy_score =
      1.0 - abs(entropy - @target_entropy)

    oscillation_penalty =
      1.0 / (1.0 + oscillation)

    Float.round(entropy_score * oscillation_penalty, 4)
  end

  # ----------------------------
  # System Integration Layer
  # ----------------------------

  defp dispatch_corrections(correction, entropy) do
    cond do
      entropy < @min_entropy ->
        send_mscl(:increase_diversity_pressure, correction)

      entropy > @max_entropy ->
        send_mscl(:increase_constraint_pressure, correction)

      true ->
        send_olef(:normalize_field, correction)
    end
  end

  # MSCL (Constraint Layer Bridge)
  defp send_mscl(action, value) do
    GenServer.cast(
      Tiannara.MSCL.Supervisor,
      {:entropy_pressure_signal, action, value}
    )
  rescue
    _ -> Logger.warning("MSCL not available for entropy correction")
  end

  # OLEF (Diffusion Layer Bridge)
  defp send_olef(action, value) do
    GenServer.cast(
      Tiannara.OLEF.FieldSupervisor,
      {:entropy_diffusion_signal, action, value}
    )
  rescue
    _ -> Logger.warning("OLEF not available for entropy correction")
  end
end
