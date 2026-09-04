defmodule TiannaraOS.ProgramRegistry do
  @moduledoc """
  Program Registry - Manages research initiatives within domains.

  Research Programs are organized initiatives that pursue specific scientific
  objectives within a domain. Each program contains theories, discoveries,
  experiments, and researchers working toward common goals.

  ## Constitutional Role

  Programs sit below Domains and above Theories in the scientific hierarchy:

  ```
  Principles
      ↓
  Domains
      ↓
  Research Programs (this registry)
      ↓
  Theories
      ↓
  Laws
      ↓
  Discoveries
  ```

  ## Program Structure

  Each program tracks:
  - Associated domain
  - Active theories under investigation
  - Completed discoveries
  - Assigned researchers
  - Resource allocation
  - Progress metrics
  - Knowledge capital contribution

  ## Usage

      {:ok, program} = ProgramRegistry.get(:adaptive_architecture)
      {:ok, programs} = ProgramRegistry.list_by_domain(:engineering)
      {:ok, updated} = ProgramRegistry.add_theory(:quantum_computing, :shor_algorithm)
  """

  use GenServer

  defstruct [
    # Core identification
    :id,
    :name,
    :description,
    :domain_id,
    
    # Program lifecycle
    :status,  # :active, :completed, :paused, :archived
    :priority,  # :critical, :high, :medium, :low
    :mission,  # String describing program's purpose
    :objectives,  # [String.t()] specific goals
    
    # Theory dependencies (programs require theories)
    :required_theory_ids,  # Theories this program depends on
    :theory_ids,  # Theories being investigated
    
    # Discoveries and applications
    :discovery_ids,
    :applications,  # [map()] operational applications
    
    # Resources and budget
    :researcher_ids,
    :budget_allocation,  # %{resource_type => amount}
    :budget_spent,  # %{resource_type => amount}
    :resource_allocation,  # Legacy field for compatibility
    
    # Milestones for long-horizon execution
    :milestones,  # [%{id, name, target_date, status, deliverables}]
    :current_milestone_id,  # atom() | nil
    
    # Timeline
    :start_date,
    :target_completion,
    :estimated_duration_months,  # float()
    
    # Progress tracking
    :progress_percentage,
    :last_milestone_completed_at,
    
    # Risk and impact
    :risks,  # [%{type, description, severity, mitigation}]
    :dependencies,  # [atom()] other programs this depends on
    :impact_assessment,  # map() with expected and actual impact
    
    # Metadata
    :created_at,
    :last_updated,
    :lifecycle_events
  ]

  @type t :: %__MODULE__{
    id: atom(),
    name: String.t(),
    description: String.t(),
    domain_id: atom(),
    status: atom(),
    priority: atom(),
    mission: String.t(),
    objectives: [String.t()],
    required_theory_ids: [atom()],
    theory_ids: [atom()],
    discovery_ids: [atom()],
    applications: [map()],
    researcher_ids: [String.t()],
    budget_allocation: map(),
    budget_spent: map(),
    resource_allocation: float(),
    milestones: [map()],
    current_milestone_id: atom() | nil,
    start_date: DateTime.t(),
    target_completion: DateTime.t() | nil,
    estimated_duration_months: float(),
    progress_percentage: float(),
    last_milestone_completed_at: DateTime.t() | nil,
    risks: [map()],
    dependencies: [atom()],
    impact_assessment: map(),
    created_at: DateTime.t(),
    last_updated: DateTime.t(),
    lifecycle_events: [map()]
  }

  # ==================== Public API ====================

  @doc """
  Start the Program Registry GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Get a program by ID.

  ## Parameters
  - `program_id`: atom()

  ## Returns
  {:ok, Program.t()} | {:error, String.t()}
  """
  def get(program_id) do
    GenServer.call(__MODULE__, {:get, program_id})
  end

  @doc """
  List all programs in a domain.

  ## Parameters
  - `domain_id`: atom()

  ## Returns
  {:ok, [Program.t()]}
  """
  def list_by_domain(domain_id) do
    GenServer.call(__MODULE__, {:list_by_domain, domain_id})
  end

  @doc """
  List active programs across all domains.

  ## Returns
  {:ok, [Program.t()]}
  """
  def list_active do
    GenServer.call(__MODULE__, :list_active)
  end

  @doc """
  Register a new research program.

  ## Parameters
  - `program_data`: map() with required fields

  Required fields:
  - :id
  - :name
  - :domain_id

  ## Returns
  {:ok, Program.t()} | {:error, String.t()}
  """
  def register(program_data) do
    GenServer.call(__MODULE__, {:register, program_data})
  end

  @doc """
  Add a theory to a research program.

  ## Parameters
  - `program_id`: atom()
  - `theory_id`: atom()

  ## Returns
  {:ok, Program.t()} | {:error, String.t()}
  """
  def add_theory(program_id, theory_id) do
    GenServer.call(__MODULE__, {:add_theory, program_id, theory_id})
  end

  @doc """
  Add a discovery to a research program.

  ## Parameters
  - `program_id`: atom()
  - `discovery_id`: atom()

  ## Returns
  {:ok, Program.t()} | {:error, String.t()}
  """
  def add_discovery(program_id, discovery_id) do
    GenServer.call(__MODULE__, {:add_discovery, program_id, discovery_id})
  end

  @doc """
  Update program progress percentage.

  ## Parameters
  - `program_id`: atom()
  - `progress`: float() (0.0 to 100.0)

  ## Returns
  {:ok, Program.t()} | {:error, String.t()}
  """
  def update_progress(program_id, progress) do
    GenServer.call(__MODULE__, {:update_progress, program_id, progress})
  end

  @doc """
  Update program status.

  ## Parameters
  - `program_id`: atom()
  - `new_status`: atom() (:active, :completed, :paused, :archived)

  ## Returns
  {:ok, Program.t()} | {:error, String.t()}
  """
  def update_status(program_id, new_status) do
    GenServer.call(__MODULE__, {:update_status, program_id, new_status})
  end

  @doc """
  Assign a researcher to a program.

  ## Parameters
  - `program_id`: atom()
  - `researcher_id`: String.t()

  ## Returns
  {:ok, Program.t()} | {:error, String.t()}
  """
  def assign_researcher(program_id, researcher_id) do
    GenServer.call(__MODULE__, {:assign_researcher, program_id, researcher_id})
  end

  @doc """
  Add a milestone to a program for long-horizon execution.

  Milestones represent major checkpoints enabling coherent execution over time.

  ## Parameters
  - `program_id`: atom()
  - `milestone`: map() with :id, :name, :target_date, :status, :deliverables, :dependencies

  ## Returns
  {:ok, Program.t()} | {:error, String.t()}
  """
  def add_milestone(program_id, milestone) do
    GenServer.call(__MODULE__, {:add_milestone, program_id, milestone})
  end

  @doc """
  Update milestone status and progress.

  ## Parameters
  - `program_id`: atom()
  - `milestone_id`: atom()
  - `new_status`: atom() (:pending, :in_progress, :completed, :cancelled)
  - `progress_notes`: String.t() optional notes

  ## Returns
  {:ok, Program.t()} | {:error, String.t()}
  """
  def update_milestone(program_id, milestone_id, new_status, progress_notes \\ nil) do
    GenServer.call(__MODULE__, {:update_milestone, program_id, milestone_id, new_status, progress_notes})
  end

  @doc """
  Advance program to next milestone.

  Sets current milestone as completed and activates next pending milestone.

  ## Parameters
  - `program_id`: atom()

  ## Returns
  {:ok, Program.t()} | {:error, String.t()}
  """
  def advance_to_next_milestone(program_id) do
    GenServer.call(__MODULE__, {:advance_to_next_milestone, program_id})
  end

  @doc """
  Allocate budget resources to a program.

  ## Parameters
  - `program_id`: atom()
  - `allocation`: map() %{resource_type => amount}

  ## Returns
  {:ok, Program.t()} | {:error, String.t()}
  """
  def allocate_budget(program_id, allocation) do
    GenServer.call(__MODULE__, {:allocate_budget, program_id, allocation})
  end

  @doc """
  Record budget expenditure from a program.

  ## Parameters
  - `program_id`: atom()
  - `expenditure`: map() %{resource_type => amount_spent}

  ## Returns
  {:ok, Program.t()} | {:error, String.t()}
  """
  def record_expenditure(program_id, expenditure) do
    GenServer.call(__MODULE__, {:record_expenditure, program_id, expenditure})
  end

  @doc """
  Add theory dependency to a program.

  Programs declare required theories. When a theory improves,
  all dependent programs automatically benefit.

  ## Parameters
  - `program_id`: atom()
  - `theory_id`: atom()

  ## Returns
  {:ok, Program.t()} | {:error, String.t()}
  """
  def add_theory_dependency(program_id, theory_id) do
    GenServer.call(__MODULE__, {:add_theory_dependency, program_id, theory_id})
  end

  @doc """
  Assess program impact based on discoveries and applications.

  Calculates expected vs actual impact across multiple dimensions.

  ## Parameters
  - `program_id`: atom()

  ## Returns
  {:ok, Program.t()} | {:error, String.t()}
  """
  def assess_impact(program_id) do
    GenServer.call(__MODULE__, {:assess_impact, program_id})
  end

  @doc """
  Get program execution timeline showing milestone progression.

  Returns chronological view of long-horizon execution including
  completed milestones, current status, and remaining work.

  ## Parameters
  - `program_id`: atom()

  ## Returns
  {:ok, timeline_map} | {:error, String.t()}
  """
  def get_execution_timeline(program_id) do
    GenServer.call(__MODULE__, {:get_execution_timeline, program_id})
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    state = %{
      programs: %{},
      domain_index: %{}  # domain_id -> [program_ids]
    }

    # Initialize with example programs for each domain
    state = initialize_example_programs(state)

    {:ok, state}
  end

  @impl true
  def handle_call({:get, program_id}, _from, state) do
    case Map.get(state.programs, program_id) do
      nil ->
        {:reply, {:error, "Program not found: #{inspect(program_id)}"}, state}

      program ->
        {:reply, {:ok, program}, state}
    end
  end

  @impl true
  def handle_call({:list_by_domain, domain_id}, _from, state) do
    program_ids = Map.get(state.domain_index, domain_id, [])

    programs = Enum.map(program_ids, fn id ->
      Map.get(state.programs, id)
    end)
    |> Enum.filter(& &1)

    {:reply, {:ok, programs}, state}
  end

  @impl true
  def handle_call(:list_active, _from, state) do
    programs = Map.values(state.programs)
    |> Enum.filter(fn p -> p.status == :active end)

    {:reply, {:ok, programs}, state}
  end

  @impl true
  def handle_call({:register, program_data}, _from, state) do
    with :ok <- validate_required_fields(program_data),
         program <- build_program(program_data) do
      if Map.has_key?(state.programs, program.id) do
        {:reply, {:error, "Program already exists: #{program.id}"}, state}
      else
        state = put_in(state.programs[program.id], program)
        state = index_by_domain(state, program)

        {:reply, {:ok, program}, state}
      end
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:add_theory, program_id, theory_id}, _from, state) do
    case Map.get(state.programs, program_id) do
      nil ->
        {:reply, {:error, "Program not found: #{inspect(program_id)}"}, state}

      program ->
        if theory_id in program.theory_ids do
          {:reply, {:error, "Theory already in program: #{theory_id}"}, state}
        else
          updated = %{program |
            theory_ids: program.theory_ids ++ [theory_id],
            last_updated: DateTime.utc_now()
          }

          state = put_in(state.programs[program_id], updated)

          {:reply, {:ok, updated}, state}
        end
    end
  end

  @impl true
  def handle_call({:add_discovery, program_id, discovery_id}, _from, state) do
    case Map.get(state.programs, program_id) do
      nil ->
        {:reply, {:error, "Program not found: #{inspect(program_id)}"}, state}

      program ->
        if discovery_id in program.discovery_ids do
          {:reply, {:error, "Discovery already in program: #{discovery_id}"}, state}
        else
          updated = %{program |
            discovery_ids: program.discovery_ids ++ [discovery_id],
            last_updated: DateTime.utc_now()
          }

          state = put_in(state.programs[program_id], updated)

          {:reply, {:ok, updated}, state}
        end
    end
  end

  @impl true
  def handle_call({:update_progress, program_id, progress}, _from, state) do
    if progress < 0.0 or progress > 100.0 do
      {:reply, {:error, "Progress must be between 0.0 and 100.0"}, state}
    else
      case Map.get(state.programs, program_id) do
        nil ->
          {:reply, {:error, "Program not found: #{inspect(program_id)}"}, state}

        program ->
          updated = %{program |
            progress_percentage: progress,
            last_updated: DateTime.utc_now()
          }

          state = put_in(state.programs[program_id], updated)

          {:reply, {:ok, updated}, state}
      end
    end
  end

  @impl true
  def handle_call({:update_status, program_id, new_status}, _from, state) do
    valid_statuses = [:active, :completed, :paused, :archived]

    if new_status not in valid_statuses do
      {:reply, {:error, "Invalid status: #{inspect(new_status)}. Must be one of: #{inspect(valid_statuses)}"}, state}
    else
      case Map.get(state.programs, program_id) do
        nil ->
          {:reply, {:error, "Program not found: #{inspect(program_id)}"}, state}

        program ->
          updated = %{program |
            status: new_status,
            last_updated: DateTime.utc_now()
          }

          state = put_in(state.programs[program_id], updated)

          {:reply, {:ok, updated}, state}
      end
    end
  end

  @impl true
  def handle_call({:assign_researcher, program_id, researcher_id}, _from, state) do
    case Map.get(state.programs, program_id) do
      nil ->
        {:reply, {:error, "Program not found: #{inspect(program_id)}"}, state}

      program ->
        if researcher_id in program.researcher_ids do
          {:reply, {:error, "Researcher already assigned: #{researcher_id}"}, state}
        else
          updated = %{program |
            researcher_ids: program.researcher_ids ++ [researcher_id],
            last_updated: DateTime.utc_now()
          }

          state = put_in(state.programs[program_id], updated)

          {:reply, {:ok, updated}, state}
        end
    end
  end

  @impl true
  def handle_call({:add_milestone, program_id, milestone}, _from, state) do
    case Map.get(state.programs, program_id) do
      nil ->
        {:reply, {:error, "Program not found: #{inspect(program_id)}"}, state}

      program ->
        existing_ids = Enum.map(program.milestones || [], fn m -> m.id end)
        if milestone.id in existing_ids do
          {:reply, {:error, "Milestone already exists: #{milestone.id}"}, state}
        else
          milestones = (program.milestones || []) ++ [milestone]
          
          current_milestone = if program.current_milestone_id == nil and milestone.status == :pending do
            milestone.id
          else
            program.current_milestone_id
          end

          updated = %{program |
            milestones: milestones,
            current_milestone_id: current_milestone,
            last_updated: DateTime.utc_now()
          }

          state = put_in(state.programs[program_id], updated)

          {:reply, {:ok, updated}, state}
        end
    end
  end

  @impl true
  def handle_call({:update_milestone, program_id, milestone_id, new_status, progress_notes}, _from, state) do
    case Map.get(state.programs, program_id) do
      nil ->
        {:reply, {:error, "Program not found: #{inspect(program_id)}"}, state}

      program ->
        milestones = program.milestones || []
        milestone_index = Enum.find_index(milestones, fn m -> m.id == milestone_id end)

        if milestone_index == nil do
          {:reply, {:error, "Milestone not found: #{milestone_id}"}, state}
        else
          milestone = Enum.at(milestones, milestone_index)
          updated_milestone = %{milestone | status: new_status}
          
          updated_milestone = if progress_notes do
            %{updated_milestone | progress_notes: progress_notes}
          else
            updated_milestone
          end

          updated_milestones = List.replace_at(milestones, milestone_index, updated_milestone)
          
          last_completed = if new_status == :completed do
            DateTime.utc_now()
          else
            program.last_milestone_completed_at
          end

          updated = %{program |
            milestones: updated_milestones,
            last_milestone_completed_at: last_completed,
            last_updated: DateTime.utc_now()
          }

          state = put_in(state.programs[program_id], updated)

          {:reply, {:ok, updated}, state}
        end
    end
  end

  @impl true
  def handle_call({:advance_to_next_milestone, program_id}, _from, state) do
    case Map.get(state.programs, program_id) do
      nil ->
        {:reply, {:error, "Program not found: #{inspect(program_id)}"}, state}

      program ->
        milestones = program.milestones || []
        
        current_index = Enum.find_index(milestones, fn m -> m.id == program.current_milestone_id end)
        
        if current_index == nil or current_index >= length(milestones) - 1 do
          {:reply, {:error, "No current milestone or already at final milestone"}, state}
        else
          current_milestone = Enum.at(milestones, current_index)
          updated_current = %{current_milestone | status: :completed}
          milestones = List.replace_at(milestones, current_index, updated_current)
          
          next_index = current_index + 1
          next_milestone = Enum.at(milestones, next_index)
          updated_next = %{next_milestone | status: :in_progress}
          milestones = List.replace_at(milestones, next_index, updated_next)

          updated = %{program |
            milestones: milestones,
            current_milestone_id: next_milestone.id,
            last_milestone_completed_at: DateTime.utc_now(),
            last_updated: DateTime.utc_now()
          }

          state = put_in(state.programs[program_id], updated)

          {:reply, {:ok, updated}, state}
        end
    end
  end

  @impl true
  def handle_call({:allocate_budget, program_id, allocation}, _from, state) do
    case Map.get(state.programs, program_id) do
      nil ->
        {:reply, {:error, "Program not found: #{inspect(program_id)}"}, state}

      program ->
        current_allocation = program.budget_allocation || %{}
        merged_allocation = Map.merge(current_allocation, allocation, fn _k, v1, v2 -> v1 + v2 end)

        updated = %{program |
          budget_allocation: merged_allocation,
          last_updated: DateTime.utc_now()
        }

        state = put_in(state.programs[program_id], updated)

        {:reply, {:ok, updated}, state}
    end
  end

  @impl true
  def handle_call({:record_expenditure, program_id, expenditure}, _from, state) do
    case Map.get(state.programs, program_id) do
      nil ->
        {:reply, {:error, "Program not found: #{inspect(program_id)}"}, state}

      program ->
        current_spent = program.budget_spent || %{}
        merged_spent = Map.merge(current_spent, expenditure, fn _k, v1, v2 -> v1 + v2 end)

        updated = %{program |
          budget_spent: merged_spent,
          last_updated: DateTime.utc_now()
        }

        state = put_in(state.programs[program_id], updated)

        {:reply, {:ok, updated}, state}
    end
  end

  @impl true
  def handle_call({:add_theory_dependency, program_id, theory_id}, _from, state) do
    case Map.get(state.programs, program_id) do
      nil ->
        {:reply, {:error, "Program not found: #{inspect(program_id)}"}, state}

      program ->
        required_theories = program.required_theory_ids || []
        
        if theory_id in required_theories do
          {:reply, {:error, "Theory dependency already exists: #{theory_id}"}, state}
        else
          updated = %{program |
            required_theory_ids: required_theories ++ [theory_id],
            last_updated: DateTime.utc_now()
          }

          state = put_in(state.programs[program_id], updated)

          {:reply, {:ok, updated}, state}
        end
    end
  end

  @impl true
  def handle_call({:assess_impact, program_id}, _from, state) do
    case Map.get(state.programs, program_id) do
      nil ->
        {:reply, {:error, "Program not found: #{inspect(program_id)}"}, state}

      program ->
        discovery_count = length(program.discovery_ids || [])
        application_count = length(program.applications || [])
        
        impact_score = (discovery_count * 10) + (application_count * 15)
        
        impact_assessment = %{
          scientific_contribution: discovery_count,
          practical_applications: application_count,
          estimated_impact_score: impact_score,
          assessed_at: DateTime.utc_now()
        }

        updated = %{program |
          impact_assessment: impact_assessment,
          last_updated: DateTime.utc_now()
        }

        state = put_in(state.programs[program_id], updated)

        {:reply, {:ok, updated}, state}
    end
  end

  @impl true
  def handle_call({:get_execution_timeline, program_id}, _from, state) do
    case Map.get(state.programs, program_id) do
      nil ->
        {:reply, {:error, "Program not found: #{inspect(program_id)}"}, state}

      program ->
        milestones = program.milestones || []
        
        completed = Enum.filter(milestones, fn m -> m.status == :completed end)
        in_progress = Enum.filter(milestones, fn m -> m.status == :in_progress end)
        pending = Enum.filter(milestones, fn m -> m.status == :pending end)
        
        timeline = %{
          program_id: program_id,
          program_name: program.name,
          start_date: program.start_date,
          target_completion: program.target_completion,
          current_milestone: program.current_milestone_id,
          progress_percentage: program.progress_percentage,
          milestones: %{
            total: length(milestones),
            completed: length(completed),
            in_progress: length(in_progress),
            pending: length(pending)
          },
          completed_milestones: completed,
          current_milestones: in_progress,
          upcoming_milestones: pending,
          last_milestone_completed_at: program.last_milestone_completed_at
        }

        {:reply, {:ok, timeline}, state}
    end
  end

  # ==================== Private Functions ====================

  defp validate_required_fields(data) do
    required = [:id, :name, :domain_id]

    missing = Enum.filter(required, fn field ->
      not Map.has_key?(data, field) or is_nil(Map.get(data, field))
    end)

    if length(missing) > 0 do
      {:error, "Missing required fields: #{inspect(missing)}"}
    else
      :ok
    end
  end

  defp build_program(data) when is_map(data) do
    %__MODULE__{
      id: Map.get(data, :id),
      name: Map.get(data, :name, ""),
      description: Map.get(data, :description, ""),
      domain_id: Map.get(data, :domain_id),
      status: Map.get(data, :status, :active),
      priority: Map.get(data, :priority, :medium),
      theory_ids: Map.get(data, :theory_ids, []),
      discovery_ids: Map.get(data, :discovery_ids, []),
      researcher_ids: Map.get(data, :researcher_ids, []),
      resource_allocation: Map.get(data, :resource_allocation, 0.0),
      start_date: Map.get(data, :start_date, DateTime.utc_now()),
      target_completion: Map.get(data, :target_completion),
      progress_percentage: Map.get(data, :progress_percentage, 0.0),
      created_at: Map.get(data, :created_at, DateTime.utc_now()),
      last_updated: Map.get(data, :last_updated, DateTime.utc_now()),
      lifecycle_events: Map.get(data, :lifecycle_events, [])
    }
  end

  defp index_by_domain(state, program) do
    current = Map.get(state.domain_index, program.domain_id, [])
    put_in(state.domain_index[program.domain_id], current ++ [program.id])
  end

  defp initialize_example_programs(state) do
    example_programs = [
      # Engineering
      %{id: :adaptive_architecture, name: "Adaptive Architecture", domain_id: :engineering,
        description: "Design systems that adapt to changing requirements", priority: :high},
      %{id: :resilient_systems, name: "Resilient Systems", domain_id: :engineering,
        description: "Build systems that recover from failures gracefully", priority: :high},

      # Medicine
      %{id: :adaptive_therapeutics, name: "Adaptive Therapeutics", domain_id: :medicine,
        description: "Personalized treatment protocols that adapt to patient response", priority: :critical},

      # Governance
      %{id: :constitutional_navigation, name: "Constitutional Navigation", domain_id: :governance,
        description: "Navigate complex policy landscapes using constitutional principles", priority: :high},

      # Computation
      %{id: :quantum_algorithms, name: "Quantum Algorithms", domain_id: :computation,
        description: "Develop algorithms for quantum computing systems", priority: :high},

      # Physics
      %{id: :unified_physics, name: "Unified Physics", domain_id: :physics,
        description: "Seek unification of fundamental physical forces", priority: :critical},

      # Cognition
      %{id: :meta_cognitive_architectures, name: "Meta-Cognitive Architectures", domain_id: :cognition,
        description: "Design systems that reason about their own reasoning", priority: :critical},

      # Mathematics
      %{id: :proof_verification, name: "Automated Proof Verification", domain_id: :computation,
        description: "Formal verification of mathematical proofs", priority: :medium}
    ]

    Enum.reduce(example_programs, state, fn program_data, acc ->
      program = build_program(program_data)
      acc = put_in(acc.programs[program.id], program)
      index_by_domain(acc, program)
    end)
  end
end
