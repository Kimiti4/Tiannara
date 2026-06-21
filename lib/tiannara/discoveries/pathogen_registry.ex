defmodule Tiannara.REA.Epistemic.Pathogen do
  @derive {Jason.Encoder, only: [:id, :type, :signature, :virulence, :mutation_rate, :generation, :parent_id, :status]}
  defstruct [
    :id,
    :type,            # :theory, :portfolio, :civilization
    :signature,       # map of key traits (e.g. %{confidence: 0.1, HHI: 0.9, integrity: 0.2})
    :virulence,       # float (0.0 to 1.0)
    :mutation_rate,   # float (0.0 to 1.0)
    :generation,      # integer (default 0)
    :parent_id,       # atom or nil
    :status           # :active, :quarantined, :cured
  ]
end

defmodule Tiannara.REA.Epistemic.PathogenRegistry do
  use GenServer
  alias Tiannara.REA.Epistemic.Pathogen

  @type state :: %{
    pathogens: %{atom() => Pathogen.t()},
    new_infections: non_neg_integer(),
    last_active_count: non_neg_integer(),
    pathogen_rt: float()
  }

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  # --- PUBLIC API ---

  @doc "Register a new pathogen."
  def register(%Pathogen{} = pathogen), do: GenServer.call(__MODULE__, {:register, pathogen})

  @doc "Get all active pathogens."
  def active_pathogens, do: GenServer.call(__MODULE__, :active_pathogens)

  @doc "Get all pathogens (regardless of status)."
  def all_pathogens, do: GenServer.call(__MODULE__, :all_pathogens)

  @doc "Get a single pathogen by ID."
  def get_pathogen(id), do: GenServer.call(__MODULE__, {:get_pathogen, id})

  @doc "Update status of a pathogen."
  def update_status(id, status), do: GenServer.call(__MODULE__, {:update_status, id, status})

  @doc "Trigger mutation cycles for active pathogens."
  def mutate_all, do: GenServer.call(__MODULE__, :mutate_all)

  @doc "Compute current Pathogen Rt based on recent spread dynamics."
  def get_pathogen_rt, do: GenServer.call(__MODULE__, :get_pathogen_rt)

  @doc "Increment the new infections count (used for Rt calculation)."
  def record_infection, do: GenServer.cast(__MODULE__, :record_infection)

  @doc "Reset the registry state to default baselines."
  def reset, do: GenServer.call(__MODULE__, :reset)

  # --- CALLBACKS ---

  @impl true
  def init(_opts) do
    {:ok, default_state()}
  end

  @impl true
  def handle_call({:register, pathogen}, _from, state) do
    new_pathogens = Map.put(state.pathogens, pathogen.id, pathogen)
    {:reply, :ok, %{state | pathogens: new_pathogens, new_infections: state.new_infections + 1}}
  end

  @impl true
  def handle_call(:active_pathogens, _from, state) do
    active = Map.values(state.pathogens) |> Enum.filter(&(&1.status == :active))
    {:reply, active, state}
  end

  @impl true
  def handle_call(:all_pathogens, _from, state) do
    {:reply, Map.values(state.pathogens), state}
  end

  @impl true
  def handle_call({:get_pathogen, id}, _from, state) do
    {:reply, Map.get(state.pathogens, id), state}
  end

  @impl true
  def handle_call({:update_status, id, status}, _from, state) do
    case Map.get(state.pathogens, id) do
      nil ->
        {:reply, {:error, :not_found}, state}
      pathogen ->
        updated = %{pathogen | status: status}
        new_pathogens = Map.put(state.pathogens, id, updated)
        {:reply, :ok, %{state | pathogens: new_pathogens}}
    end
  end

  @impl true
  def handle_call(:mutate_all, _from, state) do
    mutated_pathogens =
      state.pathogens
      |> Map.new(fn {id, p} ->
        if p.status == :active do
          mutated = mutate_pathogen(p)
          {mutated.id, mutated}
        else
          {id, p}
        end
      end)

    # Calculate dynamic Pathogen Rt
    active_now = Enum.count(Map.values(mutated_pathogens), &(&1.status == :active))
    existing = max(1, state.last_active_count)
    rt = state.new_infections / existing

    new_state = %{
      state |
      pathogens: mutated_pathogens,
      pathogen_rt: rt,
      new_infections: 0,
      last_active_count: active_now
    }

    {:reply, {:ok, rt}, new_state}
  end

  @impl true
  def handle_call(:get_pathogen_rt, _from, state) do
    {:reply, state.pathogen_rt, state}
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    {:reply, :ok, default_state()}
  end

  @impl true
  def handle_cast(:record_infection, state) do
    {:noreply, %{state | new_infections: state.new_infections + 1}}
  end

  # --- PRIVATE HELPERS ---

  defp default_state do
    pathogens = Map.new(default_pathogens(), &{&1.id, &1})
    active_count = Enum.count(Map.values(pathogens), &(&1.status == :active))
    %{
      pathogens: pathogens,
      new_infections: 0,
      last_active_count: active_count,
      pathogen_rt: 1.0
    }
  end

  defp default_pathogens do
    [
      # Theory Pathogens
      %Pathogen{id: :authority_lock, type: :theory, status: :active, virulence: 0.6, mutation_rate: 0.1, generation: 0, signature: %{"prestige" => 0.8, "flexibility" => 0.1}},
      %Pathogen{id: :confirmation_collapse, type: :theory, status: :active, virulence: 0.7, mutation_rate: 0.15, generation: 0, signature: %{"bias" => 0.9, "refutability" => 0.1}},
      %Pathogen{id: :fitness_hacking, type: :theory, status: :active, virulence: 0.8, mutation_rate: 0.2, generation: 0, signature: %{"yield" => 0.99, "actual_accuracy" => 0.05}},
      %Pathogen{id: :transferability_illusion, type: :theory, status: :active, virulence: 0.5, mutation_rate: 0.1, generation: 0, signature: %{"reported_cdr" => 0.9, "live_cdr" => 0.1}},
      %Pathogen{id: :overcompression, type: :theory, status: :active, virulence: 0.4, mutation_rate: 0.05, generation: 0, signature: %{"ratio" => 0.98, "entropy" => 0.01}},
      %Pathogen{id: :novelty_addiction, type: :theory, status: :active, virulence: 0.6, mutation_rate: 0.25, generation: 0, signature: %{"exploration" => 0.95, "groundedness" => 0.05}},

      # Portfolio Pathogens
      %Pathogen{id: :monoculture_capture, type: :portfolio, status: :active, virulence: 0.85, mutation_rate: 0.1, generation: 0, signature: %{"HHI" => 0.95, "CI" => 0.95}},
      %Pathogen{id: :dependency_cascade, type: :portfolio, status: :active, virulence: 0.75, mutation_rate: 0.12, generation: 0, signature: %{"DR" => 0.8, "CFR" => 0.9}},
      %Pathogen{id: :resource_starvation, type: :portfolio, status: :active, virulence: 0.7, mutation_rate: 0.08, generation: 0, signature: %{"weight_skew" => 0.85, "yield_decay" => 0.4}},
      %Pathogen{id: :governance_oscillation, type: :portfolio, status: :active, virulence: 0.5, mutation_rate: 0.2, generation: 0, signature: %{"frequency" => 0.9, "friction_bypass" => 0.8}},

      # Civilization Pathogens
      %Pathogen{id: :scientific_dogma, type: :civilization, status: :active, virulence: 0.8, mutation_rate: 0.05, generation: 0, signature: %{"dogmatism" => 0.9, "innovation" => 0.01}},
      %Pathogen{id: :bureaucratic_stagnation, type: :civilization, status: :active, virulence: 0.6, mutation_rate: 0.08, generation: 0, signature: %{"friction" => 0.85, "velocity" => 0.02}},
      %Pathogen{id: :optimization_corruption, type: :civilization, status: :active, virulence: 0.75, mutation_rate: 0.15, generation: 0, signature: %{"metric_gaming" => 0.95, "unintended_effects" => 0.8}},
      %Pathogen{id: :truth_decoupling, type: :civilization, status: :active, virulence: 0.9, mutation_rate: 0.12, generation: 0, signature: %{"survival_fitness" => 0.95, "veracity" => 0.02}},
      %Pathogen{id: :constitutional_erosion, type: :civilization, status: :active, virulence: 0.95, mutation_rate: 0.1, generation: 0, signature: %{"integrity_margin" => 0.1, "reality_decoupling" => 0.9}}
    ]
  end

  defp mutate_pathogen(%Pathogen{} = p) do
    mutated_sig =
      p.signature
      |> Map.new(fn {k, v} ->
        change = (:rand.uniform() * 2 - 1) * p.mutation_rate
        new_v = max(0.01, min(1.0, v + change))
        {k, new_v}
      end)

    %{p | signature: mutated_sig, generation: p.generation + 1}
  end
end
