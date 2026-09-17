defmodule Tiannara.Meta.Memory.LawArchive do
  @moduledoc """
  Thermodynamic Evolutionary Memory - Stores extinct physics laws with entropy context.
  
  Instead of deleting old CAL/CIS/selection rules, this archive preserves them as
  latent functions bound to thermodynamic conditions. Laws can be resurrected when
  the system re-enters matching entropy regimes.
  
  ## Storage Schema
  Each archived law contains:
    - law_id: Unique identifier (e.g., "CAL_inverse_square_v3")
    - cal_expr: Coalition Arbitration Layer expression/function
    - cis_expr: Cognitive Immune System expression/function
    - entropy_band: {min, max} entropy range where law was valid
    - fitness_context: Average fitness during law's active period
    - extinction_pressure: Collapse metric at time of law deactivation
    - activation_signature: Computed fingerprint for similarity matching
    - timestamp: When law was archived
    - resurrection_count: How many times law has been reactivated
  
  ## Resurrection Mechanism
  Laws are reactivated when:
    current_entropy ∈ entropy_band
    AND similarity(current_species_state, activation_signature) > threshold
  
  ## Law Half-Life Decay
  activation_strength(t) = e^(-λt)
  Only frequently re-resurrected laws persist long-term.
  """

  use GenServer
  require Logger

  alias Tiannara.Genetics.WorldGenome

  @decay_constant 0.05  # λ for half-life decay
  @resurrection_threshold 0.85  # Minimum similarity for resurrection
  @max_resurrections 10  # Cap on how often a law can be revived

  @type entropy_band :: {float(), float()}
  @type law_expression :: String.t() | function()
  @type activation_signature :: %{atom() => float()}

  @type t :: %__MODULE__{
    law_id: String.t(),
    cal_expr: law_expression(),
    cis_expr: law_expression(),
    entropy_band: entropy_band(),
    fitness_context: float(),
    extinction_pressure: float(),
    activation_signature: activation_signature(),
    timestamp: DateTime.t(),
    resurrection_count: non_neg_integer(),
    last_resurrection: DateTime.t() | nil,
    activation_strength: float()
  }

  defstruct [
    :law_id,
    :cal_expr,
    :cis_expr,
    :entropy_band,
    :fitness_context,
    :extinction_pressure,
    :activation_signature,
    :timestamp,
    :resurrection_count,
    :last_resurrection,
    :activation_strength
  ]

  # ==================== GenServer API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Initialize ETS table for fast lookup by entropy band
    :ets.new(:law_archive, [:named_table, :set, :public])
    :ets.new(:law_index_by_entropy, [:named_table, :bag, :public])

    Logger.info("🧬 LawArchive initialized with thermodynamic memory")
    {:ok, %{total_archived: 0, total_resurrections: 0}}
  end

  # ==================== Public API ====================

  @doc """
  Store an extinct law in the thermodynamic archive.
  
  Computes activation signature based on law's behavioral fingerprint.
  """
  def store_extinct_law(law_id, cal_expr, cis_expr, entropy_range, fitness_snapshot, collapse_metric) do
    GenServer.cast(__MODULE__, {:store_law, law_id, cal_expr, cis_expr, entropy_range, fitness_snapshot, collapse_metric})
  end

  @doc """
  Attempt to resurrect laws matching current system state.
  
  Returns list of resurrected laws with activation strengths.
  """
  def attempt_resurrection(system_state) do
    GenServer.call(__MODULE__, {:resurrect, system_state})
  end

  @doc """
  Query archive for laws active in a specific entropy band.
  """
  def query_by_entropy(min_entropy, max_entropy) do
    GenServer.call(__MODULE__, {:query_entropy, min_entropy, max_entropy})
  end

  @doc """
  Get full lineage of a specific law (all mutations over time).
  """
  def get_law_lineage(law_id) do
    GenServer.call(__MODULE__, {:get_lineage, law_id})
  end

  @doc """
  Apply half-life decay to all archived laws.
  Called periodically (e.g., every selection cycle).
  """
  def apply_decay do
    GenServer.cast(__MODULE__, :apply_decay)
  end

  @doc """
  Get archive statistics.
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def handle_cast({:store_law, law_id, cal_expr, cis_expr, entropy_range, fitness_snapshot, collapse_metric}, state) do
    activation_sig = compute_activation_signature(cal_expr, cis_expr, entropy_range)
    
    law = %__MODULE__{
      law_id: law_id,
      cal_expr: cal_expr,
      cis_expr: cis_expr,
      entropy_band: entropy_range,
      fitness_context: fitness_snapshot,
      extinction_pressure: collapse_metric,
      activation_signature: activation_sig,
      timestamp: DateTime.utc_now(),
      resurrection_count: 0,
      last_resurrection: nil,
      activation_strength: 1.0
    }

    # Store in ETS
    :ets.insert(:law_archive, {law_id, law})
    
    # Index by entropy band for fast range queries
    :ets.insert(:law_index_by_entropy, {entropy_range, law_id})

    Logger.info("📦 Archived law #{law_id} (entropy: #{inspect(entropy_range)})")
    {:noreply, %{state | total_archived: state.total_archived + 1}}
  end

  @impl true
  def handle_cast(:apply_decay, state) do
    # Apply exponential decay to all laws
    :ets.foldl(fn {_id, law}, acc ->
      if law.resurrection_count > 0 do
        time_since_resurrection = 
          if law.last_resurrection do
            DateTime.diff(DateTime.utc_now(), law.last_resurrection, :second)
          else
            0
          end
        
        new_strength = law.activation_strength * :math.exp(-@decay_constant * time_since_resurrection / 3600.0)
        
        updated_law = %{law | activation_strength: max(new_strength, 0.01)}
        :ets.insert(:law_archive, {law.law_id, updated_law})
      end
      
      acc
    end, :ok, :law_archive)

    {:noreply, state}
  end

  @impl true
  def handle_call({:resurrect, system_state}, _from, state) do
    current_entropy = Map.get(system_state, :entropy, 0.5)
    current_species = Map.get(system_state, :species_signature, %{})
    
    # Find laws matching entropy band
    candidate_laws = :ets.foldl(fn {_band, law_id}, acc ->
      case :ets.lookup(:law_archive, law_id) do
        [{^law_id, law}] -> [law | acc]
        _ -> acc
      end
    end, [], :law_index_by_entropy)
    
    # Filter by entropy match and signature similarity
    resurrected = Enum.filter(candidate_laws, fn law ->
      entropy_match?(current_entropy, law.entropy_band) and
      signature_match?(current_species, law.activation_signature) and
      law.resurrection_count < @max_resurrections and
      law.activation_strength > 0.1
    end)
    
    # Activate matching laws
    activated = Enum.map(resurrected, fn law ->
      updated = %{
        law |
        resurrection_count: law.resurrection_count + 1,
        last_resurrection: DateTime.utc_now(),
        activation_strength: 1.0  # Reset strength on resurrection
      }
      
      :ets.insert(:law_archive, {law.law_id, updated})
      
      # Publish resurrection event via NATS
      publish_resurrection_event(updated, system_state)
      
      updated
    end)
    
    Logger.info("⚡ Resurrected #{length(activated)} laws (entropy: #{current_entropy})")
    
    {:reply, {:ok, activated}, %{state | total_resurrections: state.total_resurrections + length(activated)}}
  end

  @impl true
  def handle_call({:query_entropy, min_ent, max_ent}, _from, state) do
    laws = :ets.foldl(fn {_band, law_id}, acc ->
      case :ets.lookup(:law_archive, law_id) do
        [{^law_id, law}] ->
          if law.entropy_band |> elem(0) <= max_ent and law.entropy_band |> elem(1) >= min_ent do
            [law | acc]
          else
            acc
          end
        _ -> acc
      end
    end, [], :law_index_by_entropy)
    
    {:reply, {:ok, laws}, state}
  end

  @impl true
  def handle_call({:get_lineage, law_id}, _from, state) do
    lineage = case :ets.lookup(:law_archive, law_id) do
      [{^law_id, law}] -> [law]
      _ -> []
    end
    
    # TODO: Extend to track mutation chain across versions
    {:reply, {:ok, lineage}, state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    total_laws = :ets.info(:law_archive, :size)
    active_laws = :ets.foldl(fn {_id, law}, count ->
      if law.activation_strength > 0.1, do: count + 1, else: count
    end, 0, :law_archive)
    
    stats = %{
      total_archived: state.total_archived,
      total_resurrections: state.total_resurrections,
      currently_active: active_laws,
      total_in_archive: total_laws
    }
    
    {:reply, {:ok, stats}, state}
  end

  # ==================== Private Helpers ====================

  defp compute_activation_signature(cal_expr, cis_expr, entropy_band) do
    # Generate behavioral fingerprint from law expressions
    # In production, this would hash the AST or compute feature vector
    %{
      cal_complexity: byte_size(inspect(cal_expr)),
      cis_complexity: byte_size(inspect(cis_expr)),
      entropy_center: (elem(entropy_band, 0) + elem(entropy_band, 1)) / 2.0,
      entropy_width: elem(entropy_band, 1) - elem(entropy_band, 0)
    }
  end

  defp entropy_match?(current_entropy, {min_ent, max_ent}) do
    current_entropy >= min_ent and current_entropy <= max_ent
  end

  defp signature_match?(current_species, activation_sig) do
    # Compute cosine similarity between species state and activation signature
    # Simplified: check if key metrics are within 15% tolerance
    Enum.all?(activation_sig, fn {key, target_val} ->
      current_val = Map.get(current_species, key, 0.0)
      abs(current_val - target_val) / (target_val + 0.001) < 0.15
    end)
  end

  defp publish_resurrection_event(law, system_state) do
    # Publish to NATS: tiannara.meta.law.resurrection
    payload = %{
      event_type: "law_resurrection",
      law_id: law.law_id,
      reason: "entropy_return_band_match",
      target_species: Map.get(system_state, :dominant_species, "unknown"),
      confidence: law.activation_strength,
      entropy_at_resurrection: Map.get(system_state, :entropy, 0.0),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
    
    # Use existing NATS publisher
    if Code.ensure_loaded?(TiannaraRuntime.NATS.WorldStreamManager) do
      TiannaraRuntime.NATS.WorldStreamManager.publish("tiannara.meta.law.resurrection", payload)
    end
    
    Logger.debug("🔮 Published resurrection event for #{law.law_id}")
  end
end
