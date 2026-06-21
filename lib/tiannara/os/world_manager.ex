defmodule TiannaraOS.WorldManager do
  @moduledoc """
  Manages the lifecycle of active research worlds in TiannaraOS.
  Orchestrates world creation (World Spawn), institutional seating, and world retirement.
  Reads and writes all operations through the canonical CivilizationKernel.
  """

  require Logger

  alias TiannaraOS.World
  alias TiannaraOS.WorldTemplate
  alias TiannaraOS.CivilizationKernel
  alias Tiannara.REA.Epistemic.Institution

  # Domain mapping helper for labs
  @lab_domains %{
    # Cybersecurity labs
    security_lab: :governance,
    threat_lab: :cybernetics,
    malware_lab: :computation,
    tool_lab: :engineering,
    # Robotics labs
    control_lab: :robotics,
    perception_lab: :cognition,
    planning_lab: :logistics,
    safety_lab: :cybernetics,
    # Mathematics labs
    number_theory_lab: :mathematics,
    topology_lab: :mathematics,
    analysis_lab: :mathematics,
    logic_lab: :mathematics
  }

  @doc """
  Spawns a new research world from the specified template ID.
  Updates the global state substrate dynamically.
  """
  @spec spawn_world(atom(), keyword()) :: {:ok, World.t()} | {:error, any()}
  def spawn_world(template_id, opts \\ []) do
    case WorldTemplate.get_template(template_id) do
      nil ->
        {:error, :template_not_found}

      template ->
        tenant_id = opts[:tenant_id] || "default_tenant"
        world_id = opts[:world_id] || String.to_atom("world_#{template_id}_#{System.unique_integer([:positive])}")
        
        # 1. Spawn institutions for each lab in the template
        {insts, inst_ids} = create_lab_institutions(template.labs, world_id)

        # 2. Spawn starting theories for the template
        {theories, theory_ids} = create_starting_theories(template_id, world_id)

        # 3. Construct the world struct
        new_world = %World{
          id: world_id,
          name: "#{template.name} - Instance #{System.unique_integer([:positive])}",
          template_id: template_id,
          labs: template.labs,
          institutions: inst_ids,
          theories: theory_ids,
          discovery_registry: [],
          economy: %{budget: 500.0, credits_allocated: %{}},
          tenant_id: tenant_id
        }

        # 4. Transactionally commit to Civilization Kernel
        update_result =
          CivilizationKernel.update_state(fn state ->
            # Merge new institutions, theories, and the world itself into state
            updated_worlds = Map.put(state.worlds, world_id, new_world)
            updated_insts = Map.merge(state.institutions, insts)
            updated_theories = Map.merge(state.theories, theories)

            %{state | worlds: updated_worlds, institutions: updated_insts, theories: updated_theories}
          end)

        case update_result do
          {:ok, _state} ->
            Logger.info("🌍 [World Manager] Spawned world #{world_id} from template #{template_id}.")
            {:ok, new_world}

          {:error, reason} ->
            Logger.error("❌ [World Manager] Failed to spawn world #{world_id}: #{inspect(reason)}")
            {:error, reason}
        end
    end
  end

  @doc """
  Retires (destroys) a world, removing its local institutions and theories.
  """
  @spec destroy_world(atom()) :: {:ok, atom()} | {:error, any()}
  def destroy_world(world_id) do
    # Fetch world first to get related institution & theory IDs
    state = CivilizationKernel.get_state()

    case Map.get(state.worlds, world_id) do
      nil ->
        {:error, :world_not_found}

      world ->
        update_result =
          CivilizationKernel.update_state(fn current_state ->
            # Delete world
            updated_worlds = Map.delete(current_state.worlds, world_id)
            
            # Delete institutions belonging to this world
            updated_insts = Map.drop(current_state.institutions, world.institutions)

            # Delete theories belonging to this world
            updated_theories = Map.drop(current_state.theories, world.theories)

            %{current_state | worlds: updated_worlds, institutions: updated_insts, theories: updated_theories}
          end)

        case update_result do
          {:ok, _state} ->
            Logger.info("🧹 [World Manager] Successfully destroyed world #{world_id}.")
            {:ok, world_id}

          {:error, reason} ->
            Logger.error("❌ [World Manager] Failed to destroy world #{world_id}: #{inspect(reason)}")
            {:error, reason}
        end
    end
  end

  # --- PRIVATE HELPERS ---

  defp create_lab_institutions(labs, world_id) do
    Enum.reduce(labs, {%{}, []}, fn lab, {insts_acc, ids_acc} ->
      inst_id = String.to_atom("inst_#{lab.id}_#{world_id}")
      domain = Map.get(@lab_domains, lab.id, :science)

      new_inst = %Institution{
        id: inst_id,
        name: "#{lab.name} Executor",
        type: :evolvable,
        focus_domain: domain,
        specialization_coordinates: %{volatility: 0.5, complexity: 0.5, adversariality: 0.5, security_pressure: 0.5},
        compute_share: 0.0,
        attention_share: 0.0,
        credits_held: 100.0,
        efficiency: 1.0,
        age: 0,
        fitness: 0.8,
        parent_ids: [],
        memory: %{successful_projects: [], failed_projects: [], discovered_theories: [], crises_survived: 0},
        culture: %{exploration_bias: 0.5, risk_tolerance: 0.5, collaboration_bias: 0.5, security_bias: 0.5}
      }

      {Map.put(insts_acc, inst_id, new_inst), [inst_id | ids_acc]}
    end)
  end

  defp create_starting_theories(template_id, world_id) do
    # Creates starting dummy theories for the template
    t1_id = String.to_atom("theory_alpha_#{template_id}_#{world_id}")
    t2_id = String.to_atom("theory_beta_#{template_id}_#{world_id}")

    # Use basic maps for theory storage to prevent complex dependency loops in mock state
    t1 = %{
      id: t1_id,
      world_id: world_id,
      name: "Baseline #{String.capitalize(to_string(template_id))} Theory Alpha",
      coherence: 0.9,
      redundancy: 0.1,
      flow_signature: 0.5,
      value: 0.5
    }

    t2 = %{
      id: t2_id,
      world_id: world_id,
      name: "Baseline #{String.capitalize(to_string(template_id))} Theory Beta",
      coherence: 0.85,
      redundancy: 0.2,
      flow_signature: 0.4,
      value: 0.5
    }

    theories = %{t1_id => t1, t2_id => t2}
    {theories, [t1_id, t2_id]}
  end
end
