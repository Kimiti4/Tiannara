defmodule Tiannara.Meta.CausalOntologyEngine do
  @moduledoc """
  Manages non-linear temporal reinforcement loops and decay profiles for resurrected laws.
  
  Implements the Law Half-Life Decay mechanism from 5E.md:
  - Tracks activation strength of resurrected physics laws
  - Applies exponential decay: α(t) = e^(-λt) where λ=0.05
  - Reinforces laws that improve macro-fitness (positive feedback loop)
  - Forcefully extinguishes unused ghost laws to prevent eternal recurrence deadlocks
  
  ## Key Concepts
  
  **Law Half-Life Decay**: Every resurrected law has a finite activation window.
  If it fails to demonstrate fitness improvement within its execution window,
  Elixir burns its activation probability to zero.
  
  **Temporal Reinforcement**: Laws that successfully stabilize regions receive
  positive fitness feedback, slowing their decay rate and extending their lifespan.
  
  **Epoch Clock**: Global temporal counter tracking simulation cycles for
  consistent decay calculations across all archived laws.
  """

  use GenServer
  require Logger

  alias Tiannara.NATS.MetaEvolutionStreamManager

  @decay_rate_lambda 0.05  # λ in activation_strength(t) = e^(-λt)
  @min_activation_threshold 0.01
  @max_reinforcement_cap 2.0
  @decay_check_interval_ms 60_000  # Check decay every 60 seconds

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("🧬 Tiannara.Meta.CausalOntologyEngine initialized (law half-life decay manager)")
    
    # Create ETS table for causal reinforcement matrix
    :ets.new(:causal_reinforcement_matrix, [:set, :public, :named_table])
    
    # Schedule periodic decay application
    schedule_decay_check()
    
    {:ok, %{epoch_clock: 0}}
  end

  @doc """
  Reinforces a resurrected law based on its performance yield.
  
  Positive fitness feedback rewards structural stability, slowing decay.
  Negative feedback accelerates extinction.
  
  ## Parameters
    - law_id: Unique identifier for the physics law
    - performance_yield: Fitness delta from law activation (-1.0 to +1.0)
  
  ## Example
  
      CausalOntologyEngine.reinforce_law("CAL_inverse_square_v3", 0.15)
  """
  def reinforce_law(law_id, performance_yield) do
    GenServer.cast(__MODULE__, {:reinforce_law, law_id, performance_yield})
  end

  @doc """
  Registers a newly resurrected law with initial activation strength.
  
  ## Parameters
    - law_id: Unique identifier for the physics law
    - initial_strength: Starting activation strength (default: 1.0)
  
  ## Example
  
      CausalOntologyEngine.register_resurrection("CIS_dampener_v7")
  """
  def register_resurrection(law_id, initial_strength \\ 1.0) do
    GenServer.cast(__MODULE__, {:register_resurrection, law_id, initial_strength})
  end

  @doc """
  Retrieves current activation strength for a law.
  
  Returns nil if law is not in active reinforcement matrix.
  
  ## Example
  
      CausalOntologyEngine.get_activation_strength("CAL_coalition_v2")
      # => 0.87
  """
  def get_activation_strength(law_id) do
    case :ets.lookup(:causal_reinforcement_matrix, law_id) do
      [{^law_id, strength, _last_used}] -> strength
      [] -> nil
    end
  end

  @doc """
  Lists all currently active resurrected laws with their decay profiles.
  
  ## Returns
  
      [
        {"CAL_inverse_square_v3", 0.92, 145},
        {"CIS_dampener_v7", 0.67, 138}
      ]
  """
  def list_active_laws do
    :ets.tab2list(:causal_reinforcement_matrix)
    |> Enum.map(fn {law_id, strength, last_used} ->
      {law_id, strength, last_used}
    end)
  end

  @impl true
  def handle_cast({:reinforce_law, law_id, performance_yield}, state) do
    current_data = :ets.lookup(:causal_reinforcement_matrix, law_id)
    
    {current_strength, last_used} = case current_data do
      [{^law_id, strength, t}] -> {strength, t}
      [] -> {1.0, state.epoch_clock}  # New law registration
    end
    
    # Positive fitness feedback rewards structural stability
    # Performance yield ranges from -1.0 (harmful) to +1.0 (beneficial)
    reinforcement_factor = 1.0 + performance_yield
    new_strength = (current_strength * reinforcement_factor) 
                   |> min(@max_reinforcement_cap)
                   |> max(0.0)
    
    :ets.insert(:causal_reinforcement_matrix, {law_id, new_strength, state.epoch_clock})
    
    Logger.debug("🔄 Law #{law_id} reinforced: #{Float.round(current_strength, 3)} → #{Float.round(new_strength, 3)} (yield: #{performance_yield})")
    
    {:noreply, state}
  end

  @impl true
  def handle_cast({:register_resurrection, law_id, initial_strength}, state) do
    :ets.insert(:causal_reinforcement_matrix, {law_id, initial_strength, state.epoch_clock})
    
    Logger.info("✨ Law #{law_id} resurrected with strength #{initial_strength}")
    
    # Publish resurrection event to NATS
    MetaEvolutionStreamManager.publish_law_resurrection(%{
      law_id: law_id,
      activation_strength: initial_strength,
      epoch: state.epoch_clock
    })
    
    {:noreply, state}
  end

  @impl true
  def handle_info(:apply_temporal_decay, state) do
    # Iterate through archive to degrade unused ghostly laws
    extinct_laws = :ets.foldl(fn {law_id, strength, last_used}, acc ->
      elapsed = state.epoch_clock - last_used
      decayed_strength = strength * :math.exp(-@decay_rate_lambda * elapsed)
      
      if decayed_strength < @min_activation_threshold do
        # Law has fully decayed - total extinction
        :ets.delete(:causal_reinforcement_matrix, law_id)
        
        Logger.info("💀 Law #{law_id} fully extinct after #{elapsed} epochs (final strength: #{Float.round(decayed_strength, 4)})")
        
        # Broadcast total extinction down NATS
        MetaEvolutionStreamManager.publish_law_extinction(%{
          law_id: law_id,
          final_strength: decayed_strength,
          total_epochs: elapsed,
          reason: :half_life_decay
        })
        
        [law_id | acc]
      else
        # Update with decayed strength
        :ets.insert(:causal_reinforcement_matrix, {law_id, decayed_strength, last_used})
        acc
      end
    end, [], :causal_reinforcement_matrix)
    
    if length(extinct_laws) > 0 do
      Logger.info("⚰️  #{length(extinct_laws)} laws reached terminal decay this epoch")
    end
    
    # Schedule next decay check
    schedule_decay_check()
    
    {:noreply, %{state | epoch_clock: state.epoch_clock + 1}}
  end

  defp schedule_decay_check do
    Process.send_after(self(), :apply_temporal_decay, @decay_check_interval_ms)
  end
end
