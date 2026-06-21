defmodule Tiannara.REA.Epistemic.Institution do
  @derive Jason.Encoder
  defstruct [
    :id,
    :name,
    :type,                      # :constitutional or :evolvable
    :focus_domain,              # atom (one of the 20 domains)
    :specialization_coordinates, # map: %{volatility: f, complexity: f, adversariality: f, security_pressure: f}
    :compute_share,             # float (0.0 .. 1.0)
    :attention_share,           # float (0.0 .. 1.0)
    :credits_held,              # float
    :efficiency,                # float
    :age,                       # integer
    :fitness,                   # float
    :parent_ids,                # list
    :memory,                    # map: %{successful_projects: [], failed_projects: [], discovered_theories: [], crises_survived: 0}
    :culture                    # map: %{exploration_bias: f, risk_tolerance: f, collaboration_bias: f, security_bias: f}
  ]
end

defmodule Tiannara.REA.Epistemic.InstitutionRegistry do
  use GenServer
  alias Tiannara.REA.Epistemic.Institution

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  # --- PUBLIC API ---

  def register_institution(%Institution{} = inst) do
    GenServer.call(__MODULE__, {:register, inst})
  end

  def get_institutions do
    GenServer.call(__MODULE__, :get_institutions)
  end

  def active_institutions do
    GenServer.call(__MODULE__, :active_institutions)
  end

  def record_success(id, goal_id, theory_id) do
    GenServer.call(__MODULE__, {:record_success, id, goal_id, theory_id})
  end

  def record_failure(id, goal_id) do
    GenServer.call(__MODULE__, {:record_failure, id, goal_id})
  end

  def record_crisis_survived(id) do
    GenServer.call(__MODULE__, {:record_crisis, id})
  end

  def set_institutions(institutions) do
    GenServer.call(__MODULE__, {:set_institutions, institutions})
  end

  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  # --- CALLBACKS ---

  @impl true
  def init(_opts) do
    {:ok, default_institutions()}
  end

  @impl true
  def handle_call({:register, inst}, _from, state) do
    {:reply, :ok, Map.put(state, inst.id, inst)}
  end

  @impl true
  def handle_call(:get_institutions, _from, state) do
    {:reply, Map.values(state), state}
  end

  @impl true
  def handle_call(:active_institutions, _from, state) do
    active = state |> Map.values()
    {:reply, active, state}
  end

  @impl true
  def handle_call({:record_success, id, goal_id, theory_id}, _from, state) do
    case Map.get(state, id) do
      nil -> {:reply, {:error, :not_found}, state}
      inst ->
        mem = inst.memory
        new_mem = %{
          mem |
          successful_projects: [goal_id | mem.successful_projects] |> Enum.uniq(),
          discovered_theories: [theory_id | mem.discovered_theories] |> Enum.uniq()
        }
        # Success reinforces positive culture (increases efficiency and exploration slightly)
        cult = inst.culture
        new_cult = %{
          cult |
          exploration_bias: min(1.0, cult.exploration_bias + 0.02)
        }
        new_inst = %{inst | memory: new_mem, culture: new_cult, credits_held: inst.credits_held + 100.0}
        {:reply, :ok, Map.put(state, id, new_inst)}
    end
  end

  @impl true
  def handle_call({:record_failure, id, goal_id}, _from, state) do
    case Map.get(state, id) do
      nil -> {:reply, {:error, :not_found}, state}
      inst ->
        mem = inst.memory
        new_mem = %{mem | failed_projects: [goal_id | mem.failed_projects] |> Enum.uniq()}
        # Failure weakens risk tolerance/exploration bias
        cult = inst.culture
        new_cult = %{
          cult |
          exploration_bias: max(0.01, cult.exploration_bias - 0.05),
          risk_tolerance: max(0.01, cult.risk_tolerance - 0.05)
        }
        new_inst = %{inst | memory: new_mem, culture: new_cult, credits_held: max(0.0, inst.credits_held - 50.0)}
        {:reply, :ok, Map.put(state, id, new_inst)}
    end
  end

  @impl true
  def handle_call({:record_crisis, id}, _from, state) do
    case Map.get(state, id) do
      nil -> {:reply, {:error, :not_found}, state}
      inst ->
        mem = inst.memory
        new_mem = %{mem | crises_survived: mem.crises_survived + 1}
        {:reply, :ok, Map.put(state, id, %{inst | memory: new_mem})}
    end
  end

  @impl true
  def handle_call({:set_institutions, institutions}, _from, _state) do
    new_state = Map.new(institutions, & {&1.id, &1})
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    {:reply, :ok, default_institutions()}
  end

  # --- HELPERS ---

  def default_institutions do
    %{
      # Constitutional Protected Organs
      civilization_memory_organ: %Institution{
        id: :civilization_memory_organ,
        name: "Civilization Memory Organ",
        type: :constitutional,
        focus_domain: :governance,
        specialization_coordinates: %{volatility: 0.5, complexity: 0.5, adversariality: 0.5, security_pressure: 0.5},
        compute_share: 0.1,
        attention_share: 0.1,
        credits_held: 1000.0,
        efficiency: 1.0,
        age: 0,
        fitness: 1.0,
        parent_ids: [],
        memory: %{successful_projects: [], failed_projects: [], discovered_theories: [], crises_survived: 0},
        culture: %{exploration_bias: 0.1, risk_tolerance: 0.1, collaboration_bias: 0.9, security_bias: 0.9}
      },
      constitution_kernel_organ: %Institution{
        id: :constitution_kernel_organ,
        name: "Constitution Kernel Organ",
        type: :constitutional,
        focus_domain: :governance,
        specialization_coordinates: %{volatility: 0.5, complexity: 0.5, adversariality: 0.5, security_pressure: 0.5},
        compute_share: 0.1,
        attention_share: 0.1,
        credits_held: 1000.0,
        efficiency: 1.0,
        age: 0,
        fitness: 1.0,
        parent_ids: [],
        memory: %{successful_projects: [], failed_projects: [], discovered_theories: [], crises_survived: 0},
        culture: %{exploration_bias: 0.0, risk_tolerance: 0.0, collaboration_bias: 0.9, security_bias: 1.0}
      },
      unified_immune_system_organ: %Institution{
        id: :unified_immune_system_organ,
        name: "Unified Immune System Organ",
        type: :constitutional,
        focus_domain: :governance,
        specialization_coordinates: %{volatility: 0.5, complexity: 0.5, adversariality: 0.5, security_pressure: 0.5},
        compute_share: 0.1,
        attention_share: 0.1,
        credits_held: 1000.0,
        efficiency: 1.0,
        age: 0,
        fitness: 1.0,
        parent_ids: [],
        memory: %{successful_projects: [], failed_projects: [], discovered_theories: [], crises_survived: 0},
        culture: %{exploration_bias: 0.2, risk_tolerance: 0.3, collaboration_bias: 0.8, security_bias: 1.0}
      },

      # Evolvable Species
      exploration_institute: %Institution{
        id: :exploration_institute,
        name: "Frontier Exploration Institute",
        type: :evolvable,
        focus_domain: :science,
        specialization_coordinates: %{volatility: 0.7, complexity: 0.6, adversariality: 0.3, security_pressure: 0.2},
        compute_share: 0.15,
        attention_share: 0.15,
        credits_held: 200.0,
        efficiency: 1.0,
        age: 0,
        fitness: 0.8,
        parent_ids: [],
        memory: %{successful_projects: [], failed_projects: [], discovered_theories: [], crises_survived: 0},
        culture: %{exploration_bias: 0.8, risk_tolerance: 0.8, collaboration_bias: 0.6, security_bias: 0.2}
      },
      energy_institute: %Institution{
        id: :energy_institute,
        name: "Dynamic Energy Institute",
        type: :evolvable,
        focus_domain: :energy,
        specialization_coordinates: %{volatility: 0.3, complexity: 0.4, adversariality: 0.2, security_pressure: 0.4},
        compute_share: 0.15,
        attention_share: 0.15,
        credits_held: 200.0,
        efficiency: 1.0,
        age: 0,
        fitness: 0.8,
        parent_ids: [],
        memory: %{successful_projects: [], failed_projects: [], discovered_theories: [], crises_survived: 0},
        culture: %{exploration_bias: 0.4, risk_tolerance: 0.4, collaboration_bias: 0.5, security_bias: 0.6}
      },
      replication_institute: %Institution{
        id: :replication_institute,
        name: "Peer Replication Institute",
        type: :evolvable,
        focus_domain: :computation,
        specialization_coordinates: %{volatility: 0.4, complexity: 0.7, adversariality: 0.4, security_pressure: 0.3},
        compute_share: 0.15,
        attention_share: 0.15,
        credits_held: 200.0,
        efficiency: 1.0,
        age: 0,
        fitness: 0.8,
        parent_ids: [],
        memory: %{successful_projects: [], failed_projects: [], discovered_theories: [], crises_survived: 0},
        culture: %{exploration_bias: 0.5, risk_tolerance: 0.3, collaboration_bias: 0.8, security_bias: 0.4}
      },
      security_research_institute: %Institution{
        id: :security_research_institute,
        name: "Security Analysis Institute",
        type: :evolvable,
        focus_domain: :governance,
        specialization_coordinates: %{volatility: 0.5, complexity: 0.5, adversariality: 0.8, security_pressure: 0.8},
        compute_share: 0.15,
        attention_share: 0.15,
        credits_held: 200.0,
        efficiency: 1.0,
        age: 0,
        fitness: 0.8,
        parent_ids: [],
        memory: %{successful_projects: [], failed_projects: [], discovered_theories: [], crises_survived: 0},
        culture: %{exploration_bias: 0.3, risk_tolerance: 0.5, collaboration_bias: 0.5, security_bias: 0.9}
      }
    }
  end
end

defmodule Tiannara.REA.Epistemic.InstitutionEcology do
  @moduledoc """
  Selection sweeps, fission (splits), fusion (merges), and extinctions for Institution Species.
  """
  alias Tiannara.REA.Epistemic.{Institution, InstitutionRegistry}

  def tick(epoch, env_context) do
    institutions = InstitutionRegistry.get_institutions()

    # 1. Evaluate fitness and age updates
    updated =
      Enum.map(institutions, fn inst ->
        if inst.type == :constitutional do
          %{inst | age: inst.age + 1, fitness: 1.0}
        else
          fit = calculate_fitness(inst, env_context)
          %{inst | age: inst.age + 1, fitness: fit}
        end
      end)

    # 2. Replicator Dynamics: update resource shares for compute/attention among active ones
    evolvables = Enum.filter(updated, &(&1.type == :evolvable))
    total_evolvable_fitness = Enum.reduce(evolvables, 0.0, & &1.fitness + &2)

    # Allocate 70% share to evolvables dynamically, keeping 30% flat for constitutional organs
    allocated =
      Enum.map(updated, fn inst ->
        if inst.type == :constitutional do
          %{inst | compute_share: 0.10, attention_share: 0.10}
        else
          share = if total_evolvable_fitness > 0.0, do: 0.70 * (inst.fitness / total_evolvable_fitness), else: 0.70 / length(evolvables)
          %{inst | compute_share: Float.round(share, 4), attention_share: Float.round(share, 4)}
        end
      end)

    # 3. Speciation: Extinction of failed ones (share drops below threshold or fitness is very low)
    survivors =
      Enum.reject(allocated, fn inst ->
        inst.type == :evolvable and (inst.compute_share < 0.01 or inst.credits_held <= 0.0)
      end)

    # 4. Speciation: Fission (split) successful ones
    split_done =
      Enum.flat_map(survivors, fn inst ->
        if inst.type == :evolvable and inst.credits_held >= 500.0 do
          # Split into two specialist descendants
          [d1, d2] = split_institution(inst, epoch)
          [d1, d2]
        else
          [inst]
        end
      end)

    # 5. Speciation: Fusion (merge) highly overlapping ones
    fused = merge_overlapping_institutions(split_done, epoch)

    # founding check: if a new goal targets a domain that is unserved by any active evolvable inst
    final_insts = check_and_found_institutions(fused, epoch, env_context)

    # Set back to registry
    InstitutionRegistry.set_institutions(final_insts)
    
    # Notify economy of updated shares
    shares = Map.new(final_insts, & {&1.id, %{compute_share: &1.compute_share, attention_share: &1.attention_share}})
    Tiannara.REA.ResearchEconomy.allocate_resources(shares)
    :ok
  end

  def calculate_fitness(%Institution{} = inst, env) do
    # Focus coordinate alignment
    coords = inst.specialization_coordinates
    v_diff = :math.pow(Map.get(coords, :volatility, 0.5) - Map.get(env, :volatility, 0.5), 2)
    c_diff = :math.pow(Map.get(coords, :complexity, 0.5) - Map.get(env, :complexity, 0.5), 2)
    a_diff = :math.pow(Map.get(coords, :adversariality, 0.5) - Map.get(env, :adversariality, 0.5), 2)
    s_diff = :math.pow(Map.get(coords, :security_pressure, 0.5) - Map.get(env, :security_pressure, 0.5), 2)
    dist = :math.sqrt(v_diff + c_diff + a_diff + s_diff)
    
    # Alignment: 0.0 .. 1.0
    alignment = max(0.01, 1.0 - (dist / 2.0))

    # Incorporate culture efficiency
    efficiency = inst.efficiency
    risk_tol = inst.culture.risk_tolerance
    
    # Under high volatility or adversariality, high risk tolerance is penalized slightly unless alignment is perfect
    risk_factor = if env.volatility > 0.5, do: 1.0 - 0.2 * abs(risk_tol - env.volatility), else: 1.0

    Float.round(alignment * efficiency * risk_factor, 4)
  end

  defp split_institution(inst, epoch) do
    # Mutate culture & duplicate memory
    credits_half = inst.credits_held / 2.0
    c1 = mutate_culture(inst.culture)
    c2 = mutate_culture(inst.culture)
    
    special_coords1 = mutate_coords(inst.specialization_coordinates)
    special_coords2 = mutate_coords(inst.specialization_coordinates)

    d1 = %Institution{
      id: String.to_atom("inst_split_#{inst.focus_domain}_#{System.unique_integer([:positive])}"),
      name: "Specialized #{String.capitalize(to_string(inst.focus_domain))} Lab A",
      type: :evolvable,
      focus_domain: inst.focus_domain,
      specialization_coordinates: special_coords1,
      compute_share: inst.compute_share / 2.0,
      attention_share: inst.attention_share / 2.0,
      credits_held: credits_half,
      efficiency: inst.efficiency,
      age: 0,
      fitness: inst.fitness,
      parent_ids: [inst.id],
      memory: inst.memory, # Memory compounds and duplicates to children
      culture: c1
    }

    d2 = %Institution{
      id: String.to_atom("inst_split_#{inst.focus_domain}_#{System.unique_integer([:positive])}"),
      name: "Specialized #{String.capitalize(to_string(inst.focus_domain))} Lab B",
      type: :evolvable,
      focus_domain: inst.focus_domain,
      specialization_coordinates: special_coords2,
      compute_share: inst.compute_share / 2.0,
      attention_share: inst.attention_share / 2.0,
      credits_held: credits_half,
      efficiency: inst.efficiency,
      age: 0,
      fitness: inst.fitness,
      parent_ids: [inst.id],
      memory: inst.memory,
      culture: c2
    }

    [d1, d2]
  end

  defp merge_overlapping_institutions(list, epoch) do
    # Look for pair of evolvable institutions on same domain with overlapping coords
    evolvables = Enum.filter(list, &(&1.type == :evolvable and &1.age > 0))
    constitutionals = Enum.filter(list, &(&1.type == :constitutional))

    # Detect pairs to merge
    pairs_to_merge =
      for inst1 <- evolvables, inst2 <- evolvables, inst1.id < inst2.id do
        if inst1.focus_domain == inst2.focus_domain and coordinate_overlap?(inst1.specialization_coordinates, inst2.specialization_coordinates) do
          {inst1, inst2}
        else
          nil
        end
      end
      |> Enum.reject(&is_nil/1)

    case pairs_to_merge do
      [] -> list
      [{inst1, inst2} | _] ->
        # Perform merge
        merged = merge_pair(inst1, inst2, epoch)
        # Re-assemble
        remaining = evolvables |> Enum.reject(& &1.id in [inst1.id, inst2.id])
        constitutionals ++ [merged | remaining]
    end
  end

  defp coordinate_overlap?(c1, c2) do
    # Euclidean distance < 0.2 represents high coordinate overlap
    v_diff = :math.pow(c1.volatility - c2.volatility, 2)
    c_diff = :math.pow(c1.complexity - c2.complexity, 2)
    a_diff = :math.pow(c1.adversariality - c2.adversariality, 2)
    s_diff = :math.pow(c1.security_pressure - c2.security_pressure, 2)
    dist = :math.sqrt(v_diff + c_diff + a_diff + s_diff)
    dist < 0.2
  end

  defp merge_pair(inst1, inst2, _epoch) do
    # Blend coordinates & cultures, union memories
    blended_coords = Map.new(inst1.specialization_coordinates, fn {k, v} ->
      {k, Float.round((v + Map.get(inst2.specialization_coordinates, k, 0.5)) / 2.0, 4)}
    end)

    blended_culture = Map.new(inst1.culture, fn {k, v} ->
      {k, Float.round((v + Map.get(inst2.culture, k, 0.5)) / 2.0, 4)}
    end)

    union_memory = %{
      successful_projects: (inst1.memory.successful_projects ++ inst2.memory.successful_projects) |> Enum.uniq(),
      failed_projects: (inst1.memory.failed_projects ++ inst2.memory.failed_projects) |> Enum.uniq(),
      discovered_theories: (inst1.memory.discovered_theories ++ inst2.memory.discovered_theories) |> Enum.uniq(),
      crises_survived: max(inst1.memory.crises_survived, inst2.memory.crises_survived)
    }

    %Institution{
      id: String.to_atom("inst_merge_#{inst1.focus_domain}_#{System.unique_integer([:positive])}"),
      name: "Merged generalist #{String.capitalize(to_string(inst1.focus_domain))} Institute",
      type: :evolvable,
      focus_domain: inst1.focus_domain,
      specialization_coordinates: blended_coords,
      compute_share: inst1.compute_share + inst2.compute_share,
      attention_share: inst1.attention_share + inst2.attention_share,
      credits_held: inst1.credits_held + inst2.credits_held,
      efficiency: Float.round((inst1.efficiency + inst2.efficiency) / 2.0, 4),
      age: 0,
      fitness: Float.round((inst1.fitness + inst2.fitness) / 2.0, 4),
      parent_ids: [inst1.id, inst2.id],
      memory: union_memory,
      culture: blended_culture
    }
  end

  defp check_and_found_institutions(list, epoch, env_context) do
    active_goals =
      if Code.ensure_loaded?(Tiannara.REA.Epistemic.GoalRegistry) do
        Tiannara.REA.Epistemic.GoalRegistry.active_goals()
      else
        []
      end

    unserved_goals =
      Enum.filter(active_goals, fn goal ->
        # check if any institution targets goal.target_domain
        not Enum.any?(list, &(&1.focus_domain == goal.target_domain))
      end)

    if unserved_goals == [] do
      list
    else
      # Found a new institute for the first unserved target domain
      target_goal = hd(unserved_goals)
      domain = target_goal.target_domain
      
      new_inst = %Institution{
        id: String.to_atom("inst_found_#{domain}_#{System.unique_integer([:positive])}"),
        name: "Founding #{String.capitalize(to_string(domain))} Lab",
        type: :evolvable,
        focus_domain: domain,
        specialization_coordinates: target_goal.focus_coordinates,
        compute_share: 0.05,
        attention_share: 0.05,
        credits_held: 100.0,
        efficiency: 1.0,
        age: 0,
        fitness: 0.8,
        parent_ids: [],
        memory: %{successful_projects: [], failed_projects: [], discovered_theories: [], crises_survived: 0},
        culture: %{exploration_bias: 0.5, risk_tolerance: 0.5, collaboration_bias: 0.5, security_bias: 0.5}
      }
      list ++ [new_inst]
    end
  end

  defp mutate_culture(cult) do
    Map.new(cult, fn {k, v} ->
      delta = (:rand.uniform() - 0.5) * 0.1
      {k, max(0.01, min(1.0, v + delta))}
    end)
  end

  defp mutate_coords(coords) do
    Map.new(coords, fn {k, v} ->
      delta = (:rand.uniform() - 0.5) * 0.1
      {k, max(0.0, min(1.0, v + delta))}
    end)
  end
end
