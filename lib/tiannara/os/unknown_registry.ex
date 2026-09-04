defmodule TiannaraOS.UnknownRegistry do
  @moduledoc """
  Unknown Registry - Tracks unanswered scientific questions that drive research.

  Unknowns represent gaps in knowledge, unresolved questions, and areas requiring
  further investigation. They serve as the primary driver for research prioritization
  and experimental design.

  ## Constitutional Role

  Unknowns exist alongside Discoveries in the scientific hierarchy and directly
  influence Research Director priorities:

  ```
  Principles
      ↓
  Domains
      ↓
  Programs
      ↓
  Theories ←→ Unknowns (this registry)
      ↓
  Laws
      ↓
  Discoveries
  ```

  ## Unknown Categories

  - :knowledge_gap - Missing information in a domain
  - :contradiction - Conflicting evidence or theories
  - :untested_hypothesis - Hypothesis lacking experimental validation
  - :methodological_limitation - Current methods insufficient to answer
  - :emergent_question - New question arising from recent discoveries

  ## Priority Levels

  - :critical - Blocks major research progress
  - :high - Significant impact on domain understanding
  - :medium - Moderate importance
  - :low - Nice to know but not blocking

  ## Usage

      {:ok, unknown} = UnknownRegistry.get(:quantum_gravity_unification)
      {:ok, priority_list} = UnknownRegistry.get_by_priority(:medicine, :critical)
      {:ok, updated} = UnknownRegistry.mark_resolved(:cold_fusion_mechanism, discovery_id)
  """

  use GenServer
  require Logger

  defstruct [
    :id,
    :question,
    :description,
    :domain_id,
    :program_id,
    :category,
    :priority,
    :related_theory_ids,
    :related_discovery_ids,
    :blocking_research,  # Research programs blocked by this unknown
    :status,  # :open, :investigating, :resolved, :abandoned
    :created_at,
    :last_updated,
    :resolved_by_discovery_id,  # If resolved, which discovery answered it
    :lifecycle_events
  ]

  @type t :: %__MODULE__{
    id: atom(),
    question: String.t(),
    description: String.t(),
    domain_id: atom(),
    program_id: atom() | nil,
    category: atom(),
    priority: atom(),
    related_theory_ids: [atom()],
    related_discovery_ids: [atom()],
    blocking_research: [atom()],
    status: atom(),
    created_at: DateTime.t(),
    last_updated: DateTime.t(),
    resolved_by_discovery_id: atom() | nil,
    lifecycle_events: [map()]
  }

  # ==================== Public API ====================

  @doc """
  Start the Unknown Registry GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Get an unknown by ID.

  ## Parameters
  - `unknown_id`: atom()

  ## Returns
  {:ok, Unknown.t()} | {:error, String.t()}
  """
  def get(unknown_id) do
    GenServer.call(__MODULE__, {:get, unknown_id})
  end

  @doc """
  List all open unknowns in a domain.

  ## Parameters
  - `domain_id`: atom()

  ## Returns
  {:ok, [Unknown.t()]}
  """
  def list_open_by_domain(domain_id) do
    GenServer.call(__MODULE__, {:list_open_by_domain, domain_id})
  end

  @doc """
  Get unknowns filtered by priority level.

  ## Parameters
  - `domain_id`: atom()
  - `priority`: atom() (:critical, :high, :medium, :low)

  ## Returns
  {:ok, [Unknown.t()]}
  """
  def get_by_priority(domain_id, priority) do
    GenServer.call(__MODULE__, {:get_by_priority, domain_id, priority})
  end

  @doc """
  Register a new unknown/question.

  ## Parameters
  - `unknown_data`: map() with required fields

  Required fields:
  - :id
  - :question
  - :domain_id
  - :category
  - :priority

  ## Returns
  {:ok, Unknown.t()} | {:error, String.t()}
  """
  def register(unknown_data) do
    GenServer.call(__MODULE__, {:register, unknown_data})
  end

  @doc """
  Mark an unknown as resolved by a discovery.

  ## Parameters
  - `unknown_id`: atom()
  - `discovery_id`: atom()

  ## Returns
  {:ok, Unknown.t()} | {:error, String.t()}
  """
  def mark_resolved(unknown_id, discovery_id) do
    GenServer.call(__MODULE__, {:mark_resolved, unknown_id, discovery_id})
  end

  @doc """
  Update priority of an unknown.

  ## Parameters
  - `unknown_id`: atom()
  - `new_priority`: atom()

  ## Returns
  {:ok, Unknown.t()} | {:error, String.t()}
  """
  def update_priority(unknown_id, new_priority) do
    GenServer.call(__MODULE__, {:update_priority, unknown_id, new_priority})
  end

  @doc """
  Link unknown to a theory it relates to.

  ## Parameters
  - `unknown_id`: atom()
  - `theory_id`: atom()

  ## Returns
  {:ok, Unknown.t()} | {:error, String.t()}
  """
  def link_to_theory(unknown_id, theory_id) do
    GenServer.call(__MODULE__, {:link_to_theory, unknown_id, theory_id})
  end

  @doc """
  List all open unknowns across all domains.

  ## Returns
  {:ok, [Unknown.t()]}
  """
  def list_open do
    GenServer.call(__MODULE__, :list_open)
  end

  @doc """
  Get count of open unknowns by domain (for research debt calculation).

  ## Returns
  {:ok, %{domain_id => count}}
  """
  def count_by_domain do
    GenServer.call(__MODULE__, :count_by_domain)
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    state = %{
      unknowns: %{},
      domain_index: %{},  # domain_id -> [unknown_ids]
      status_index: %{    # status -> [unknown_ids]
        open: [],
        investigating: [],
        resolved: [],
        abandoned: []
      }
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:get, unknown_id}, _from, state) do
    case Map.get(state.unknowns, unknown_id) do
      nil ->
        {:reply, {:error, "Unknown not found: #{inspect(unknown_id)}"}, state}

      unknown ->
        {:reply, {:ok, unknown}, state}
    end
  end

  @impl true
  def handle_call({:list_open_by_domain, domain_id}, _from, state) do
    unknown_ids = Map.get(state.domain_index, domain_id, [])

    unknowns = Enum.map(unknown_ids, fn id ->
      Map.get(state.unknowns, id)
    end)
    |> Enum.filter(& &1)
    |> Enum.filter(fn u -> u.status == :open end)

    {:reply, {:ok, unknowns}, state}
  end

  @impl true
  def handle_call({:get_by_priority, domain_id, priority}, _from, state) do
    unknown_ids = Map.get(state.domain_index, domain_id, [])

    unknowns = Enum.map(unknown_ids, fn id ->
      Map.get(state.unknowns, id)
    end)
    |> Enum.filter(& &1)
    |> Enum.filter(fn u -> u.status == :open and u.priority == priority end)

    {:reply, {:ok, unknowns}, state}
  end

  @impl true
  def handle_call({:register, unknown_data}, _from, state) do
    with :ok <- validate_required_fields(unknown_data),
         unknown <- build_unknown(unknown_data) do
      if Map.has_key?(state.unknowns, unknown.id) do
        {:reply, {:error, "Unknown already exists: #{unknown.id}"}, state}
      else
        state = put_in(state.unknowns[unknown.id], unknown)
        state = index_by_domain(state, unknown)
        state = index_by_status(state, unknown)

        Logger.debug("[UnknownRegistry] Registered unknown #{unknown.id} in domain #{unknown.domain_id}")

        {:reply, {:ok, unknown}, state}
      end
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:mark_resolved, unknown_id, discovery_id}, _from, state) do
    case Map.get(state.unknowns, unknown_id) do
      nil ->
        {:reply, {:error, "Unknown not found: #{inspect(unknown_id)}"}, state}

      unknown ->
        if unknown.status != :open do
          {:reply, {:error, "Unknown is not open (current status: #{unknown.status})"}, state}
        else
          updated = %{unknown |
            status: :resolved,
            resolved_by_discovery_id: discovery_id,
            last_updated: DateTime.utc_now()
          }

          state = put_in(state.unknowns[unknown_id], updated)
          state = update_status_index(state, unknown_id, :open, :resolved)

          Logger.debug("[UnknownRegistry] Unknown #{unknown_id} resolved by discovery #{discovery_id}")

          {:reply, {:ok, updated}, state}
        end
    end
  end

  @impl true
  def handle_call({:update_priority, unknown_id, new_priority}, _from, state) do
    valid_priorities = [:critical, :high, :medium, :low]

    if new_priority not in valid_priorities do
      {:reply, {:error, "Invalid priority: #{inspect(new_priority)}. Must be one of: #{inspect(valid_priorities)}"}, state}
    else
      case Map.get(state.unknowns, unknown_id) do
        nil ->
          {:reply, {:error, "Unknown not found: #{inspect(unknown_id)}"}, state}

        unknown ->
          updated = %{unknown |
            priority: new_priority,
            last_updated: DateTime.utc_now()
          }

          state = put_in(state.unknowns[unknown_id], updated)

          Logger.debug("[UnknownRegistry] Unknown #{unknown_id} priority updated from #{unknown.priority} to #{new_priority}")

          {:reply, {:ok, updated}, state}
      end
    end
  end

  @impl true
  def handle_call({:link_to_theory, unknown_id, theory_id}, _from, state) do
    case Map.get(state.unknowns, unknown_id) do
      nil ->
        {:reply, {:error, "Unknown not found: #{inspect(unknown_id)}"}, state}

      unknown ->
        if theory_id in unknown.related_theory_ids do
          {:reply, {:error, "Theory already linked: #{theory_id}"}, state}
        else
          updated = %{unknown |
            related_theory_ids: unknown.related_theory_ids ++ [theory_id],
            last_updated: DateTime.utc_now()
          }

          state = put_in(state.unknowns[unknown_id], updated)

          Logger.debug("[UnknownRegistry] Unknown #{unknown_id} linked to theory #{theory_id}")

          {:reply, {:ok, updated}, state}
        end
    end
  end

  @impl true
  def handle_call(:list_open, _from, state) do
    open_ids = Map.get(state.status_index, :open, [])
    unknowns = Enum.map(open_ids, fn id -> Map.get(state.unknowns, id) end) |> Enum.filter(& &1)
    {:reply, {:ok, unknowns}, state}
  end

  @impl true
  def handle_call(:count_by_domain, _from, state) do
    counts = Enum.reduce(state.domain_index, %{}, fn {domain_id, unknown_ids}, acc ->
      open_count = Enum.count(unknown_ids, fn id ->
        case Map.get(state.unknowns, id) do
          nil -> false
          unknown -> unknown.status == :open
        end
      end)

      Map.put(acc, domain_id, open_count)
    end)

    {:reply, {:ok, counts}, state}
  end

  # ==================== Private Functions ====================

  defp validate_required_fields(data) do
    required = [:id, :question, :domain_id, :category, :priority]

    missing = Enum.filter(required, fn field ->
      not Map.has_key?(data, field) or is_nil(Map.get(data, field))
    end)

    if length(missing) > 0 do
      {:error, "Missing required fields: #{inspect(missing)}"}
    else
      :ok
    end
  end

  defp build_unknown(data) when is_map(data) do
    %__MODULE__{
      id: Map.get(data, :id),
      question: Map.get(data, :question, ""),
      description: Map.get(data, :description, ""),
      domain_id: Map.get(data, :domain_id),
      program_id: Map.get(data, :program_id),
      category: Map.get(data, :category),
      priority: Map.get(data, :priority),
      related_theory_ids: Map.get(data, :related_theory_ids, []),
      related_discovery_ids: Map.get(data, :related_discovery_ids, []),
      blocking_research: Map.get(data, :blocking_research, []),
      status: Map.get(data, :status, :open),
      created_at: Map.get(data, :created_at, DateTime.utc_now()),
      last_updated: Map.get(data, :last_updated, DateTime.utc_now()),
      resolved_by_discovery_id: Map.get(data, :resolved_by_discovery_id),
      lifecycle_events: Map.get(data, :lifecycle_events, [])
    }
  end

  defp index_by_domain(state, unknown) do
    current = Map.get(state.domain_index, unknown.domain_id, [])
    put_in(state.domain_index[unknown.domain_id], current ++ [unknown.id])
  end

  defp index_by_status(state, unknown) do
    current = Map.get(state.status_index, unknown.status, [])
    put_in(state.status_index[unknown.status], current ++ [unknown.id])
  end

  defp update_status_index(state, unknown_id, old_status, new_status) do
    # Remove from old status
    old_list = Map.get(state.status_index, old_status, [])
    updated_old = List.delete(old_list, unknown_id)
    state = put_in(state.status_index[old_status], updated_old)

    # Add to new status
    new_list = Map.get(state.status_index, new_status, [])
    put_in(state.status_index[new_status], new_list ++ [unknown_id])
  end

  def get_by_priority(_priority), do: {:ok, []}
end
