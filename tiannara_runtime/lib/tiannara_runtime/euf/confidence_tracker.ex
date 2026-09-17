defmodule TiannaraRuntime.EUF.ConfidenceTracker do
  @moduledoc """
  Epistemic Uncertainty Field (EUF) Confidence Tracker.

  Measures epistemic confidence $U$ of compiled physics or concept structures:
  $$U = 1 - \\frac{\\sigma_{consensus}}{\\sigma_{max}}$$

  A low confidence score indicates high observer divergence or fragile theories.
  The tracker alerts when $U$ drops below the threshold (0.40) to prevent
  internally coherent nonsense from being stabilized.
  """

  use GenServer
  require Logger

  @critical_confidence_floor 0.40
  @max_standard_deviation 0.50

  # ==================== Public API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Record observer beliefs regarding an ontology concept or rule.
  """
  def record_belief(concept_id, observer_id, confidence) when is_binary(concept_id) and is_number(confidence) do
    GenServer.cast(__MODULE__, {:record, concept_id, observer_id, confidence})
  end

  @doc """
  Retrieve the epistemic confidence score U for a given concept or rule.
  """
  def get_epistemic_confidence(concept_id) do
    GenServer.call(__MODULE__, {:get_confidence, concept_id})
  end

  @doc """
  Assess if a theory or concept is epistemically robust enough to proceed with compile.
  """
  def robust?(concept_id) do
    case get_epistemic_confidence(concept_id) do
      {:ok, u} -> u >= @critical_confidence_floor
      _ -> false
    end
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    Logger.info("🛡️ [EUF Confidence Tracker] Initialized")
    {:ok, initial_state()}
  end

  @impl true
  def handle_cast({:record, concept_id, observer_id, confidence}, state) do
    beliefs = Map.get(state.beliefs, concept_id, %{})
    updated_beliefs = Map.put(beliefs, observer_id, confidence)

    {:noreply, %{state | beliefs: Map.put(state.beliefs, concept_id, updated_beliefs)}}
  end

  @impl true
  def handle_cast(:reset, _state) do
    {:noreply, initial_state()}
  end

  @impl true
  def handle_call({:get_confidence, concept_id}, _from, state) do
    case Map.get(state.beliefs, concept_id) do
      nil ->
        {:reply, {:ok, 1.0}, state}

      beliefs when is_map(beliefs) ->
        values = Map.values(beliefs)
        u = calculate_u(values)

        if u < @critical_confidence_floor do
          Logger.warning("🚫 [EUF] Fragile theory detected for #{concept_id}: U = #{Float.round(u, 4)} (floor: #{@critical_confidence_floor})")
        end

        {:reply, {:ok, u}, state}
    end
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    {:reply, :ok, initial_state()}
  end

  # ==================== Helper Functions ====================

  defp initial_state do
    %{
      beliefs: %{}
    }
  end

  defp calculate_u(values) do
    if length(values) < 2 do
      1.0
    else
      mean = Enum.sum(values) / length(values)
      variance = Enum.sum(Enum.map(values, fn v -> :math.pow(v - mean, 2) end)) / length(values)
      std_dev = :math.sqrt(variance)

      # Clamp to ensure standard deviation doesn't exceed the boundary
      clamped_std_dev = min(std_dev, @max_standard_deviation)

      Float.round(1.0 - clamped_std_dev / @max_standard_deviation, 4)
    end
  end
end
