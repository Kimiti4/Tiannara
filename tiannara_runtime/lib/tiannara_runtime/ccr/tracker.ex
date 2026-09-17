defmodule TiannaraRuntime.CCR.Tracker do
  @moduledoc """
  Stateful GenServer that tracks reality compilation traces and guides future compilation.
  """

  use GenServer
  require Logger
  alias TiannaraRuntime.CCR.Reflection

  # ==================== GenServer API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("🌌 [CCR] Tracker initialized")
    {:ok, %{traces: [], reflections: [], guidance_rules: []}}
  end

  # ==================== Public API ====================

  @doc """
  Record a compilation trace, perform reflection, and update guidance.
  """
  def record_trace(trace) when is_map(trace) do
    GenServer.call(__MODULE__, {:record_trace, trace})
  end

  @doc """
  Get history of reflections.
  """
  def get_reflections do
    GenServer.call(__MODULE__, :get_reflections)
  end

  @doc """
  Get accumulated guidance rules for future compilations.
  """
  def get_guidance do
    GenServer.call(__MODULE__, :get_guidance)
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def handle_call({:record_trace, trace}, _from, state) do
    reflection = Reflection.reflect(trace)
    new_guidance = derive_guidance(reflection, state.guidance_rules)
    
    new_state = %{
      state |
      traces: [trace | state.traces],
      reflections: [reflection | state.reflections],
      guidance_rules: new_guidance
    }

    Logger.info("💡 [CCR] Traced compilation and derived #{length(new_guidance)} guidance rules")
    {:reply, {:ok, reflection}, new_state}
  end

  @impl true
  def handle_call(:get_reflections, _from, state) do
    {:reply, {:ok, state.reflections}, state}
  end

  @impl true
  def handle_call(:get_guidance, _from, state) do
    {:reply, {:ok, state.guidance_rules}, state}
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    {:reply, :ok, %{traces: [], reflections: [], guidance_rules: []}}
  end

  # ==================== Guidance Derivation ====================

  defp derive_guidance(reflection, existing_rules) do
    rules = existing_rules

    # If any collapse vectors contain Kolmogorov complexity anomalies, enforce a ceiling dampener
    rules =
      if Enum.any?(reflection.unstable_patterns, &(&1.hazard == :excessive_kolmogorov_complexity)) do
        [%{rule_type: :enforce_kolmogorov_ceiling, target: :complexity, limit: 0.8} | rules]
      else
        rules
      end

    # If semantic reversibility is low, mandate a conservation shield
    rules =
      if Enum.any?(reflection.unstable_patterns, &(&1.hazard == :semantic_entropy_leak)) do
        [%{rule_type: :mandate_conservation_shield, target: :semantic_reversibility, min_floor: 0.95} | rules]
      else
        rules
      end

    # If hyperconnected resonance is detected in evolution classification, issue a manifold division rule
    rules =
      if reflection.topology_insights.drift_classification == :hyper_connected_resonance_hazard do
        [%{rule_type: :restrict_manifold_density, target: :topology_density, max_density: 0.5} | rules]
      else
        rules
      end

    rules |> Enum.uniq()
  end
end
