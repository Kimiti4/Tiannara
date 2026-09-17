defmodule Tiannara.RRG.NoveltyInjector do
  @moduledoc """
  Phase 5F.12: Novelty Injector - Anti-Heat-Death Engine
  
  Introduces asymmetry, mutation, irrationality, and creative divergence
  to prevent semantic monoculture and maintain universal novelty generation.
  
  Perturbs:
  - Genetics
  - Cultures
  - Probability distributions
  - Historical branching
  - Scientific discovery timing
  
  Tiny perturbations create massive long-term divergence.
  """
  
  use GenServer
  require Logger

  defstruct [
    :injection_history,
    :total_novelty_injected,
    :active_domains
  ]

  @injection_domains [:culture, :genetics, :discovery, :probability, :history]
  @max_injection_magnitude 0.15  # Maximum perturbation strength

  def start_link(_opts \\ []) do
    case GenServer.start_link(__MODULE__, %{}, name: __MODULE__) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  @impl true
  def init(_opts) do
    state = %__MODULE__{
      injection_history: [],
      total_novelty_injected: 0.0,
      active_domains: []
    }

    Logger.info("💡 [RRG] Novelty Injector initialized")
    {:ok, state}
  end

  @impl true
  def handle_cast({:inject, target, magnitude}, state) do
    # Validate target domain
    if target not in @injection_domains do
      Logger.warning("🚫 [RRG] Invalid novelty injection target: #{inspect(target)}")
      {:noreply, state}
    else
      # Clamp magnitude to safe range
      clamped_magnitude = min(magnitude, @max_injection_magnitude)
      
      # Apply novelty injection
      injection_result = apply_novelty_injection(target, clamped_magnitude)
      
      # Update state
      new_state = %{
        state
        | injection_history: Enum.take([injection_result | state.injection_history], 1000),
          total_novelty_injected: state.total_novelty_injected + clamped_magnitude,
          active_domains: Enum.uniq([target | state.active_domains])
      }

      Logger.debug(
        "💡 [RRG] Novelty injected into #{inspect(target)}: magnitude=#{Float.round(clamped_magnitude, 4)}"
      )

      {:noreply, new_state}
    end
  end

  @doc """
  Get novelty injection statistics.
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      total_injections: length(state.injection_history),
      total_novelty_injected: state.total_novelty_injected,
      active_domains: state.active_domains,
      recent_injections: Enum.take(state.injection_history, 10)
    }

    {:reply, {:ok, stats}, state}
  end

  # --- Injection Mechanisms ---

  defp apply_novelty_injection(:culture, magnitude) do
    # Injects cultural divergence to prevent monoculture
    # Modifies meme propagation rates, value system drift
    %{
      domain: :culture,
      magnitude: magnitude,
      effect: :cultural_divergence,
      observer_interpretation: :language_drift,
      timestamp: System.system_time(:millisecond)
    }
  end

  defp apply_novelty_injection(:genetics, magnitude) do
    # Introduces genetic mutations and variation
    # Increases biodiversity and evolutionary potential
    %{
      domain: :genetics,
      magnitude: magnitude,
      effect: :genetic_variation,
      observer_interpretation: :mutation_rate_increase,
      timestamp: System.system_time(:millisecond)
    }
  end

  defp apply_novelty_injection(:discovery, magnitude) do
    # Perturbs scientific discovery timing to prevent synchronized optimization
    # Creates staggered breakthrough patterns
    %{
      domain: :discovery,
      magnitude: magnitude,
      effect: :discovery_timing_perturbation,
      observer_interpretation: :research_setbacks,
      timestamp: System.system_time(:millisecond)
    }
  end

  defp apply_novelty_injection(:probability, magnitude) do
    # Modifies probability distributions at quantum level
    # Creates microscopic uncertainty that scales to macroscopic divergence
    %{
      domain: :probability,
      magnitude: magnitude,
      effect: :quantum_uncertainty_increase,
      observer_interpretation: :vacuum_fluctuations,
      timestamp: System.system_time(:millisecond)
    }
  end

  defp apply_novelty_injection(:history, magnitude) do
    # Introduces historical branching divergence
    # Prevents timeline convergence toward single outcome
    %{
      domain: :history,
      magnitude: magnitude,
      effect: :historical_divergence,
      observer_interpretation: :chaotic_events,
      timestamp: System.system_time(:millisecond)
    }
  end
end