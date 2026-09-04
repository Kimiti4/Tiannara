defmodule TiannaraOS.ResearchEconomy do
  @moduledoc """
  Research Economy - Manages finite scientific capital across the research civilization.

  Research is constrained by limited resources. This module tracks and allocates:
  - Knowledge Capital (accumulated discoveries, theories, laws)
  - Funding (financial resources for research)
  - Personnel (researchers, validators, reviewers)
  - Compute (computational resources)
  - Laboratory Time (physical experiment capacity)
  - Validation Budget (resources for independent verification)
  - Publication Budget (resources for dissemination)
  - Infrastructure (facilities, equipment)
  - Data Collection (observational capacity)
  - Simulation Capacity (computational modeling)

  ## Constitutional Role

  The Research Economy ensures realistic trade-offs in resource allocation.
  No infinite research. Every allocation has opportunity costs.

  ```
  Research Strategy
      ↓
  Research Economy (this module)
      ↓
  Portfolio Allocation
      ↓
  Programs
      ↓
  Experiments
  ```

  ## Resource Types

  Each resource type has:
  - total_available: Total quantity available
  - allocated: Quantity currently allocated to programs
  - reserved: Quantity reserved for critical operations
  - available: total_available - allocated - reserved

  ## Usage

      {:ok, economy} = ResearchEconomy.initialize_economy(civilization_id)
      {:ok, updated} = ResearchEconomy.allocate_resource(economy, :funding, :medicine, 1000)
      {:ok, budget} = ResearchEconomy.get_budget_summary(economy)
      {:ok, remaining} = ResearchEconomy.check_availability(economy, :compute)
  """

  use GenServer

  alias Tiannara.LifecycleRegistry

  defstruct [
    :civilization_id,
    :resources,
    :allocations,
    :transactions,
    :created_at,
    :last_updated
  ]

  @type t :: %__MODULE__{
    civilization_id: atom(),
    resources: map(),
    allocations: map(),
    transactions: [map()],
    created_at: DateTime.t(),
    last_updated: DateTime.t()
  }

  @resource_types [
    :knowledge_capital,
    :funding,
    :personnel,
    :compute,
    :laboratory_time,
    :validation_budget,
    :publication_budget,
    :infrastructure,
    :data_collection,
    :simulation_capacity
  ]

  # ==================== Public API ====================

  @doc """
  Start the Research Economy GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Initialize research economy with default resource levels.

  ## Parameters
  - `civilization_id`: atom()
  - `initial_resources`: map() with optional custom initial values

  ## Returns
  {:ok, ResearchEconomy.t()}
  """
  def initialize_economy(civilization_id, initial_resources \\ %{}) do
    GenServer.call(__MODULE__, {:initialize, civilization_id, initial_resources})
  end

  @doc """
  Allocate resources to a domain or program.

  ## Parameters
  - `resource_type`: atom() - type of resource to allocate
  - `recipient`: atom() - domain_id or program_id
  - `amount`: float() - quantity to allocate

  ## Returns
  {:ok, ResearchEconomy.t()} | {:error, String.t()}
  """
  def allocate_resource(resource_type, recipient, amount) do
    GenServer.call(__MODULE__, {:allocate, resource_type, recipient, amount})
  end

  @doc """
  Release allocated resources back to the pool.

  ## Parameters
  - `resource_type`: atom()
  - `recipient`: atom()
  - `amount`: float()

  ## Returns
  {:ok, ResearchEconomy.t()} | {:error, String.t()}
  """
  def release_resource(resource_type, recipient, amount) do
    GenServer.call(__MODULE__, {:release, resource_type, recipient, amount})
  end

  @doc """
  Check availability of a resource.

  ## Parameters
  - `resource_type`: atom()

  ## Returns
  {:ok, available_amount} | {:error, String.t()}
  """
  def check_availability(resource_type) do
    GenServer.call(__MODULE__, {:check_availability, resource_type})
  end

  @doc """
  Get complete budget summary.

  Shows total, allocated, reserved, and available for all resource types.

  ## Returns
  {:ok, budget_summary}
  """
  def get_budget_summary do
    GenServer.call(__MODULE__, :get_budget_summary)
  end

  @doc """
  Get allocation breakdown by recipient.

  ## Parameters
  - `resource_type`: atom()

  ## Returns
  {:ok, %{recipient => amount}}
  """
  def get_allocations_by_recipient(resource_type) do
    GenServer.call(__MODULE__, {:get_allocations_by_recipient, resource_type})
  end

  @doc """
  Transfer resources between recipients.

  ## Parameters
  - `resource_type`: atom()
  - `from`: atom()
  - `to`: atom()
  - `amount`: float()

  ## Returns
  {:ok, ResearchEconomy.t()} | {:error, String.t()}
  """
  def transfer_resource(resource_type, from, to, amount) do
    GenServer.call(__MODULE__, {:transfer, resource_type, from, to, amount})
  end

  @doc """
  Record economic transaction for audit trail.

  ## Parameters
  - `transaction`: map() with :type, :resource, :from, :to, :amount, :timestamp

  ## Returns
  {:ok, ResearchEconomy.t()}
  """
  def record_transaction(transaction) do
    GenServer.call(__MODULE__, {:record_transaction, transaction})
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    state = %{
      economy: nil,
      initialized: false
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:initialize, civilization_id, initial_resources}, _from, state) do
    if state.initialized do
      {:reply, {:error, "Economy already initialized"}, state}
    else
      resources = initialize_resources(initial_resources)
      allocations = initialize_allocations()

      economy = %__MODULE__{
        civilization_id: civilization_id,
        resources: resources,
        allocations: allocations,
        transactions: [],
        created_at: DateTime.utc_now(),
        last_updated: DateTime.utc_now()
      }

      try do
        LifecycleRegistry.track_entity(:economy, civilization_id, :initialized, %{
          resource_types: length(@resource_types),
          timestamp: economy.created_at
        })
      rescue
        _ -> :ok
      end

      new_state = %{state |
        economy: economy,
        initialized: true
      }

      {:reply, {:ok, economy}, new_state}
    end
  end

  @impl true
  def handle_call({:allocate, resource_type, recipient, amount}, _from, state) do
    if not state.initialized do
      {:reply, {:error, "Economy not initialized"}, state}
    else
      economy = state.economy

      with :ok <- validate_resource_type(resource_type),
           :ok <- validate_amount(amount),
           :ok <- check_sufficient_availability(economy, resource_type, amount) do
        # Update allocation
        current_allocation = get_in(economy.allocations, [resource_type, recipient]) || 0
        new_allocation = current_allocation + amount

        allocations = put_in(economy.allocations, [resource_type, recipient], new_allocation)

        # Record transaction
        transaction = %{
          type: :allocation,
          resource: resource_type,
          recipient: recipient,
          amount: amount,
          timestamp: DateTime.utc_now()
        }

        updated_economy = %{economy |
          allocations: allocations,
          transactions: economy.transactions ++ [transaction],
          last_updated: DateTime.utc_now()
        }

        try do
          LifecycleRegistry.track_entity(:economy, economy.civilization_id, :resource_allocated, %{
            resource: resource_type,
            recipient: recipient,
            amount: amount
          })
        rescue
          _ -> :ok
        end

        new_state = %{state | economy: updated_economy}
        {:reply, {:ok, updated_economy}, new_state}
      else
        {:error, reason} -> {:reply, {:error, reason}, state}
      end
    end
  end

  @impl true
  def handle_call({:release, resource_type, recipient, amount}, _from, state) do
    if not state.initialized do
      {:reply, {:error, "Economy not initialized"}, state}
    else
      economy = state.economy

      with :ok <- validate_resource_type(resource_type),
           :ok <- validate_amount(amount),
           :ok <- check_sufficient_allocation(economy, resource_type, recipient, amount) do
        # Reduce allocation
        current_allocation = get_in(economy.allocations, [resource_type, recipient]) || 0
        new_allocation = max(0, current_allocation - amount)

        allocations = put_in(economy.allocations, [resource_type, recipient], new_allocation)

        # Record transaction
        transaction = %{
          type: :release,
          resource: resource_type,
          recipient: recipient,
          amount: amount,
          timestamp: DateTime.utc_now()
        }

        updated_economy = %{economy |
          allocations: allocations,
          transactions: economy.transactions ++ [transaction],
          last_updated: DateTime.utc_now()
        }

        new_state = %{state | economy: updated_economy}
        {:reply, {:ok, updated_economy}, new_state}
      else
        {:error, reason} -> {:reply, {:error, reason}, state}
      end
    end
  end

  @impl true
  def handle_call({:check_availability, resource_type}, _from, state) do
    if not state.initialized do
      {:reply, {:error, "Economy not initialized"}, state}
    else
      case validate_resource_type(resource_type) do
        :ok ->
          economy = state.economy
          available = calculate_availability(economy, resource_type)
          {:reply, {:ok, available}, state}

        error -> {:reply, error, state}
      end
    end
  end

  @impl true
  def handle_call(:get_budget_summary, _from, state) do
    if not state.initialized do
      {:reply, {:error, "Economy not initialized"}, state}
    else
      economy = state.economy

      summary = Enum.reduce(@resource_types, %{}, fn resource_type, acc ->
        total = get_in(economy.resources, [resource_type, :total]) || 0
        allocated = get_in(economy.allocations, [resource_type])
        |> Enum.map(fn {_recipient, amount} -> amount end)
        |> Enum.sum()

        reserved = get_in(economy.resources, [resource_type, :reserved]) || 0
        available = max(0, total - allocated - reserved)

        Map.put(acc, resource_type, %{
          total: total,
          allocated: allocated,
          reserved: reserved,
          available: available,
          utilization_rate: if(total > 0, do: Float.round((allocated / total) * 100, 2), else: 0)
        })
      end)

      {:reply, {:ok, summary}, state}
    end
  end

  @impl true
  def handle_call({:get_allocations_by_recipient, resource_type}, _from, state) do
    if not state.initialized do
      {:reply, {:error, "Economy not initialized"}, state}
    else
      case validate_resource_type(resource_type) do
        :ok ->
          economy = state.economy
          allocations = get_in(economy.allocations, [resource_type]) || %{}
          {:reply, {:ok, allocations}, state}

        error -> {:reply, error, state}
      end
    end
  end

  @impl true
  def handle_call({:transfer, resource_type, from, to, amount}, _from, state) do
    if not state.initialized do
      {:reply, {:error, "Economy not initialized"}, state}
    else
      economy = state.economy

      with :ok <- validate_resource_type(resource_type),
           :ok <- validate_amount(amount),
           :ok <- check_sufficient_allocation(economy, resource_type, from, amount) do
        # Reduce from source
        from_current = get_in(economy.allocations, [resource_type, from]) || 0
        from_new = max(0, from_current - amount)

        # Increase to destination
        to_current = get_in(economy.allocations, [resource_type, to]) || 0
        to_new = to_current + amount

        allocations = economy.allocations
        |> put_in([resource_type, from], from_new)
        |> put_in([resource_type, to], to_new)

        # Record transaction
        transaction = %{
          type: :transfer,
          resource: resource_type,
          from: from,
          to: to,
          amount: amount,
          timestamp: DateTime.utc_now()
        }

        updated_economy = %{economy |
          allocations: allocations,
          transactions: economy.transactions ++ [transaction],
          last_updated: DateTime.utc_now()
        }

        new_state = %{state | economy: updated_economy}
        {:reply, {:ok, updated_economy}, new_state}
      else
        {:error, reason} -> {:reply, {:error, reason}, state}
      end
    end
  end

  @impl true
  def handle_call({:record_transaction, transaction}, _from, state) do
    if not state.initialized do
      {:reply, {:error, "Economy not initialized"}, state}
    else
      economy = state.economy

      updated_economy = %{economy |
        transactions: economy.transactions ++ [transaction],
        last_updated: DateTime.utc_now()
      }

      new_state = %{state | economy: updated_economy}
      {:reply, {:ok, updated_economy}, new_state}
    end
  end

  # ==================== Private Functions ====================

  defp initialize_resources(custom_resources) do
    # Default resource levels (can be customized)
    defaults = %{
      knowledge_capital: %{total: 10000, reserved: 500},
      funding: %{total: 1000000, reserved: 50000},
      personnel: %{total: 1000, reserved: 50},
      compute: %{total: 100000, reserved: 5000},
      laboratory_time: %{total: 10000, reserved: 500},
      validation_budget: %{total: 200000, reserved: 10000},
      publication_budget: %{total: 50000, reserved: 2500},
      infrastructure: %{total: 500, reserved: 25},
      data_collection: %{total: 50000, reserved: 2500},
      simulation_capacity: %{total: 75000, reserved: 3750}
    }

    Map.merge(defaults, custom_resources)
  end

  defp initialize_allocations do
    Enum.into(@resource_types, %{}, fn resource_type ->
      {resource_type, %{}}
    end)
  end

  defp validate_resource_type(resource_type) do
    if resource_type in @resource_types do
      :ok
    else
      {:error, "Invalid resource type: #{inspect(resource_type)}. Must be one of: #{inspect(@resource_types)}"}
    end
  end

  defp validate_amount(amount) do
    if is_number(amount) and amount > 0 do
      :ok
    else
      {:error, "Amount must be a positive number"}
    end
  end

  defp check_sufficient_availability(economy, resource_type, amount) do
    available = calculate_availability(economy, resource_type)

    if amount <= available do
      :ok
    else
      {:error, "Insufficient #{resource_type} available. Requested: #{amount}, Available: #{available}"}
    end
  end

  defp check_sufficient_allocation(economy, resource_type, recipient, amount) do
    current = get_in(economy.allocations, [resource_type, recipient]) || 0

    if amount <= current do
      :ok
    else
      {:error, "Insufficient allocation for #{recipient}. Requested: #{amount}, Current: #{current}"}
    end
  end

  defp calculate_availability(economy, resource_type) do
    total = get_in(economy.resources, [resource_type, :total]) || 0
    allocated = get_in(economy.allocations, [resource_type])
    |> Enum.map(fn {_recipient, amount} -> amount end)
    |> Enum.sum()
    reserved = get_in(economy.resources, [resource_type, :reserved]) || 0

    max(0, total - allocated - reserved)
  end
end
