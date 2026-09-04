defmodule TiannaraOS.PrincipleRegistry do
  @moduledoc """
  Principle Registry - Stores universal scientific principles that govern all research domains.

  Principles are immutable, foundational truths that guide scientific reasoning across
  all domains. They form the top of the constitutional hierarchy and cannot be violated
  by any subsystem.

  ## Constitutional Role

  Principles sit at the apex of the scientific hierarchy:

  ```
  Principles (this registry)
      ↓
  Research Domains
      ↓
  Research Programs
      ↓
  Theories
      ↓
  Laws
      ↓
  Discoveries
      ↓
  Interventions
      ↓
  Experiments
      ↓
  Evidence
  ```

  ## Examples

  Universal principles include:
  - Optionality Preservation
  - Adaptive Memory Ecology
  - Uncertainty Weighted Governance
  - Structured Exploration
  - Constitutional Traceability

  ## Usage

      {:ok, principle} = PrincipleRegistry.get(:optionality_preservation)
      principles = PrincipleRegistry.list_all()
      domain_principles = PrincipleRegistry.for_domain(:engineering)
  """

  use GenServer

  alias TiannaraOS.LifecycleRegistry

  defstruct [
    :id,
    :name,
    :description,
    :domain_applications,  # Map of domain -> application description
    :created_at,
    :last_validated,
    :validation_count,
    :supporting_evidence_ids,
    :lifecycle_events
  ]

  @type t :: %__MODULE__{
    id: atom(),
    name: String.t(),
    description: String.t(),
    domain_applications: map(),
    created_at: DateTime.t(),
    last_validated: DateTime.t() | nil,
    validation_count: non_neg_integer(),
    supporting_evidence_ids: [String.t()],
    lifecycle_events: [map()]
  }

  # ==================== Public API ====================

  @doc """
  Start the Principle Registry GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Get a principle by ID.

  ## Parameters
  - `principle_id`: atom() - principle identifier

  ## Returns
  {:ok, Principle.t()} | {:error, String.t()}
  """
  def get(principle_id) do
    GenServer.call(__MODULE__, {:get, principle_id})
  end

  @doc """
  List all registered principles.

  ## Returns
  {:ok, [Principle.t()]}
  """
  def list_all do
    GenServer.call(__MODULE__, :list_all)
  end

  @doc """
  Get principles applicable to a specific domain.

  ## Parameters
  - `domain`: atom() - research domain (e.g., :engineering, :medicine)

  ## Returns
  {:ok, [Principle.t()]}
  """
  def for_domain(domain) do
    GenServer.call(__MODULE__, {:for_domain, domain})
  end

  @doc """
  Register a new principle.

  ## Parameters
  - `principle`: Principle struct or map with required fields

  ## Returns
  {:ok, Principle.t()} | {:error, String.t()}
  """
  def register(principle) do
    GenServer.call(__MODULE__, {:register, principle})
  end

  @doc """
  Add supporting evidence to a principle.

  ## Parameters
  - `principle_id`: atom()
  - `evidence_id`: String.t()

  ## Returns
  {:ok, Principle.t()} | {:error, String.t()}
  """
  def add_supporting_evidence(principle_id, evidence_id) do
    GenServer.call(__MODULE__, {:add_supporting_evidence, principle_id, evidence_id})
  end

  @doc """
  Record validation event for a principle.

  ## Parameters
  - `principle_id`: atom()

  ## Returns
  {:ok, Principle.t()} | {:error, String.t()}
  """
  def record_validation(principle_id) do
    GenServer.call(__MODULE__, {:record_validation, principle_id})
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    state = %{
      principles: %{},
      domain_index: %{}  # domain -> [principle_ids]
    }

    # Initialize with core constitutional principles
    state = initialize_core_principles(state)

    {:ok, state}
  end

  @impl true
  def handle_call({:get, principle_id}, _from, state) do
    case Map.get(state.principles, principle_id) do
      nil ->
        {:reply, {:error, "Principle not found: #{inspect(principle_id)}"}, state}

      principle ->
        {:reply, {:ok, principle}, state}
    end
  end

  @impl true
  def handle_call(:list_all, _from, state) do
    principles = Map.values(state.principles)
    {:reply, {:ok, principles}, state}
  end

  @impl true
  def handle_call({:for_domain, domain}, _from, state) do
    principle_ids = Map.get(state.domain_index, domain, [])

    principles = Enum.map(principle_ids, fn id ->
      Map.get(state.principles, id)
    end)
    |> Enum.filter(& &1)

    {:reply, {:ok, principles}, state}
  end

  @impl true
  def handle_call({:register, principle_data}, _from, state) do
    principle = build_principle(principle_data)

    if Map.has_key?(state.principles, principle.id) do
      {:reply, {:error, "Principle already exists: #{principle.id}"}, state}
    else
      state = put_in(state.principles[principle.id], principle)
      state = index_by_domain(state, principle)

      try do
        LifecycleRegistry.track_entity(:principle, principle.id, :created, %{
          name: principle.name,
          timestamp: principle.created_at
        })
      rescue
        _ -> :ok
      end

      {:reply, {:ok, principle}, state}
    end
  end

  @impl true
  def handle_call({:add_supporting_evidence, principle_id, evidence_id}, _from, state) do
    case Map.get(state.principles, principle_id) do
      nil ->
        {:reply, {:error, "Principle not found: #{inspect(principle_id)}"}, state}

      principle ->
        updated = %{principle |
          supporting_evidence_ids: principle.supporting_evidence_ids ++ [evidence_id]
        }

        state = put_in(state.principles[principle_id], updated)

        try do
          LifecycleRegistry.track_entity(:principle, principle_id, :evidence_added, %{
            evidence_id: evidence_id,
            total_evidence: length(updated.supporting_evidence_ids)
          })
        rescue
          _ -> :ok
        end

        {:reply, {:ok, updated}, state}
    end
  end

  @impl true
  def handle_call({:record_validation, principle_id}, _from, state) do
    case Map.get(state.principles, principle_id) do
      nil ->
        {:reply, {:error, "Principle not found: #{inspect(principle_id)}"}, state}

      principle ->
        updated = %{principle |
          last_validated: DateTime.utc_now(),
          validation_count: principle.validation_count + 1
        }

        state = put_in(state.principles[principle_id], updated)

        try do
          LifecycleRegistry.track_entity(:principle, principle_id, :validated, %{
            validation_count: updated.validation_count,
            timestamp: updated.last_validated
          })
        rescue
          _ -> :ok
        end

        {:reply, {:ok, updated}, state}
    end
  end

  # ==================== Private Functions ====================

  defp build_principle(data) when is_map(data) do
    %__MODULE__{
      id: Map.get(data, :id),
      name: Map.get(data, :name, ""),
      description: Map.get(data, :description, ""),
      domain_applications: Map.get(data, :domain_applications, %{}),
      created_at: Map.get(data, :created_at, DateTime.utc_now()),
      last_validated: Map.get(data, :last_validated),
      validation_count: Map.get(data, :validation_count, 0),
      supporting_evidence_ids: Map.get(data, :supporting_evidence_ids, []),
      lifecycle_events: Map.get(data, :lifecycle_events, [])
    }
  end

  defp index_by_domain(state, principle) do
    Enum.reduce(principle.domain_applications, state, fn {domain, _application}, acc ->
      current = Map.get(acc.domain_index, domain, [])
      put_in(acc.domain_index[domain], current ++ [principle.id])
    end)
  end

  defp initialize_core_principles(state) do
    core_principles = [
      %{
        id: :optionality_preservation,
        name: "Optionality Preservation",
        description: "Preserve future options and avoid premature commitment in system design",
        domain_applications: %{
          engineering: "Design systems with extensible interfaces and backward compatibility",
          medicine: "Maintain multiple treatment pathways to preserve patient options",
          governance: "Create adaptable policies that accommodate future scenarios"
        }
      },
      %{
        id: :adaptive_memory_ecology,
        name: "Adaptive Memory Ecology",
        description: "Memory systems should adapt to usage patterns and information value",
        domain_applications: %{
          computation: "Implement tiered storage based on access frequency and importance",
          cognition: "Prioritize retention of high-value experiences and patterns",
          economics: "Allocate memory resources based on expected utility"
        }
      },
      %{
        id: :uncertainty_weighted_governance,
        name: "Uncertainty Weighted Governance",
        description: "Governance decisions should account for uncertainty in evidence",
        domain_applications: %{
          governance: "Weight policy decisions by confidence levels in supporting data",
          medicine: "Adjust treatment protocols based on diagnostic uncertainty",
          science: "Scale experimental rigor with hypothesis uncertainty"
        }
      },
      %{
        id: :structured_exploration,
        name: "Structured Exploration",
        description: "Systematic exploration of possibility spaces rather than random search",
        domain_applications: %{
          science: "Design experiments to maximize information gain per resource unit",
          mathematics: "Explore proof strategies systematically through lemma decomposition",
          engineering: "Evaluate design alternatives through structured trade-off analysis"
        }
      },
      %{
        id: :constitutional_traceability,
        name: "Constitutional Traceability",
        description: "All conclusions must be traceable to supporting evidence and reasoning",
        domain_applications: %{
          science: "Every theory must cite supporting experiments and observations",
          governance: "Every policy decision must reference constitutional principles",
          medicine: "Every diagnosis must link to patient evidence and medical literature"
        }
      }
    ]

    Enum.reduce(core_principles, state, fn principle_data, acc ->
      principle = build_principle(principle_data)
      acc = put_in(acc.principles[principle.id], principle)
      index_by_domain(acc, principle)
    end)
  end
end
