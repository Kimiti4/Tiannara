defmodule TiannaraOS.DiscoveryRegistry do
  @moduledoc """
  Discovery Registry - Stores scientific discoveries with complete evidence traceability.

  Discoveries represent validated scientific findings that link to supporting experiments,
  evidence, theories, and operational applications. Every discovery maintains full
  constitutional traceability back to its evidentiary foundation.

  ## Constitutional Role

  Discoveries sit below Laws in the scientific hierarchy:

  ```
  Principles
      ↓
  Domains
      ↓
  Programs
      ↓
  Theories
      ↓
  Laws
      ↓
  Discoveries (this registry)
      ↓
  Interventions
      ↓
  Experiments
      ↓
  Evidence
  ```

  ## Traceability Requirements

  Every discovery must include:
  - supporting experiment IDs
  - evidence IDs
  - associated theory IDs
  - validation status
  - confidence level
  - operational applications

  Nothing appears without lineage.

  ## Usage

      {:ok, discovery} = DiscoveryRegistry.get(:dna_structure)
      {:ok, related} = DiscoveryRegistry.find_by_theory(:evolution_theory)
      {:ok, updated} = DiscoveryRegistry.add_application(:crispr, :gene_therapy)
  """

  use GenServer

  require Logger

  defstruct [
    :id,
    :name,
    :description,
    :domain_id,
    :program_id,
    :experiment_ids,
    :evidence_ids,
    :theory_ids,
    :law_id,  # Optional: if discovery led to law formation
    :applications,
    :validation_status,  # :simulated, :reproduced, :operationally_validated
    :confidence,
    :uncertainty,
    :created_at,
    :validated_at,
    :lifecycle_events
  ]

  @type t :: %__MODULE__{
    id: atom(),
    name: String.t(),
    description: String.t(),
    domain_id: atom(),
    program_id: atom(),
    experiment_ids: [String.t()],
    evidence_ids: [String.t()],
    theory_ids: [atom()],
    law_id: atom() | nil,
    applications: [map()],
    validation_status: atom(),
    confidence: float(),
    uncertainty: float(),
    created_at: DateTime.t(),
    validated_at: DateTime.t() | nil,
    lifecycle_events: [map()]
  }

  # ==================== Public API ====================

  @doc """
  Start the Discovery Registry GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Get a discovery by ID.

  ## Parameters
  - `discovery_id`: atom()

  ## Returns
  {:ok, Discovery.t()} | {:error, String.t()}
  """
  def get(discovery_id) do
    GenServer.call(__MODULE__, {:get, discovery_id})
  end

  @doc """
  List all discoveries in a domain.

  ## Parameters
  - `domain_id`: atom()

  ## Returns
  {:ok, [Discovery.t()]}
  """
  def list_by_domain(domain_id) do
    GenServer.call(__MODULE__, {:list_by_domain, domain_id})
  end

  @doc """
  Find discoveries associated with a specific theory.

  ## Parameters
  - `theory_id`: atom()

  ## Returns
  {:ok, [Discovery.t()]}
  """
  def find_by_theory(theory_id) do
    GenServer.call(__MODULE__, {:find_by_theory, theory_id})
  end

  @doc """
  Register a new discovery.

  ## Parameters
  - `discovery_data`: map() with required fields

  Required fields:
  - :id
  - :name
  - :domain_id
  - :experiment_ids
  - :evidence_ids
  - :theory_ids

  ## Returns
  {:ok, Discovery.t()} | {:error, String.t()}
  """
  def register(discovery_data) do
    GenServer.call(__MODULE__, {:register, discovery_data})
  end

  @doc """
  Add an operational application to a discovery.

  ## Parameters
  - `discovery_id`: atom()
  - `application`: map() with :name, :description, :domain

  ## Returns
  {:ok, Discovery.t()} | {:error, String.t()}
  """
  def add_application(discovery_id, application) do
    GenServer.call(__MODULE__, {:add_application, discovery_id, application})
  end

  @doc """
  Update validation status for a discovery.

  Validation pipeline:
  :simulated → :reproduced → :operationally_validated

  ## Parameters
  - `discovery_id`: atom()
  - `new_status`: atom()

  ## Returns
  {:ok, Discovery.t()} | {:error, String.t()}
  """
  def update_validation_status(discovery_id, new_status) do
    GenServer.call(__MODULE__, {:update_validation_status, discovery_id, new_status})
  end

  @doc """
  Link discovery to a scientific law (if it contributed to law formation).

  ## Parameters
  - `discovery_id`: atom()
  - `law_id`: atom()

  ## Returns
  {:ok, Discovery.t()} | {:error, String.t()}
  """
  def link_to_law(discovery_id, law_id) do
    GenServer.call(__MODULE__, {:link_to_law, discovery_id, law_id})
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    state = %{
      discoveries: %{},
      domain_index: %{},  # domain_id -> [discovery_ids]
      theory_index: %{}   # theory_id -> [discovery_ids]
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:get, discovery_id}, _from, state) do
    case Map.get(state.discoveries, discovery_id) do
      nil ->
        {:reply, {:error, "Discovery not found: #{inspect(discovery_id)}"}, state}

      discovery ->
        {:reply, {:ok, discovery}, state}
    end
  end

  @impl true
  def handle_call({:list_by_domain, domain_id}, _from, state) do
    discovery_ids = Map.get(state.domain_index, domain_id, [])

    discoveries = Enum.map(discovery_ids, fn id ->
      Map.get(state.discoveries, id)
    end)
    |> Enum.filter(& &1)

    {:reply, {:ok, discoveries}, state}
  end

  @impl true
  def handle_call({:find_by_theory, theory_id}, _from, state) do
    discovery_ids = Map.get(state.theory_index, theory_id, [])

    discoveries = Enum.map(discovery_ids, fn id ->
      Map.get(state.discoveries, id)
    end)
    |> Enum.filter(& &1)

    {:reply, {:ok, discoveries}, state}
  end

  @impl true
  def handle_call({:register, discovery_data}, _from, state) do
    # Validate required fields
    with :ok <- validate_required_fields(discovery_data),
         discovery <- build_discovery(discovery_data) do
      if Map.has_key?(state.discoveries, discovery.id) do
        {:reply, {:error, "Discovery already exists: #{discovery.id}"}, state}
      else
        state = put_in(state.discoveries[discovery.id], discovery)
        state = index_by_domain(state, discovery)
        state = index_by_theories(state, discovery)

        Logger.debug(fn -> "LifecycleRegistry.track_entity would have been called for :discovery, #{inspect(discovery.id)}, :registered, name=#{discovery.name}" end)

        {:reply, {:ok, discovery}, state}
      end
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:add_application, discovery_id, application}, _from, state) do
    case Map.get(state.discoveries, discovery_id) do
      nil ->
        {:reply, {:error, "Discovery not found: #{inspect(discovery_id)}"}, state}

      discovery ->
        updated = %{discovery |
          applications: discovery.applications ++ [application]
        }

        state = put_in(state.discoveries[discovery_id], updated)

        Logger.debug(fn -> "LifecycleRegistry.track_entity would have been called for :discovery, #{inspect(discovery_id)}, :application_added, name=#{Map.get(application, :name)}" end)

        {:reply, {:ok, updated}, state}
    end
  end

  @impl true
  def handle_call({:update_validation_status, discovery_id, new_status}, _from, state) do
    case Map.get(state.discoveries, discovery_id) do
      nil ->
        {:reply, {:error, "Discovery not found: #{inspect(discovery_id)}"}, state}

      discovery ->
        # Validate status transition
        valid_transitions = %{
          :simulated => [:reproduced],
          :reproduced => [:operationally_validated],
          :operationally_validated => []
        }

        allowed = Map.get(valid_transitions, discovery.validation_status, [])

        if new_status not in allowed do
          {:reply, {:error, "Invalid status transition: #{discovery.validation_status} → #{new_status}"}, state}
        else
          updated = %{discovery |
            validation_status: new_status,
            validated_at: if(new_status == :operationally_validated, do: DateTime.utc_now(), else: discovery.validated_at)
          }

          # Increase confidence based on validation level
          updated = update_confidence_for_validation(updated)

          state = put_in(state.discoveries[discovery_id], updated)

          Logger.debug(fn -> "LifecycleRegistry.track_entity would have been called for :discovery, #{inspect(discovery_id)}, :validation_updated, old=#{discovery.validation_status}, new=#{new_status}" end)

          {:reply, {:ok, updated}, state}
        end
    end
  end

  @impl true
  def handle_call({:link_to_law, discovery_id, law_id}, _from, state) do
    case Map.get(state.discoveries, discovery_id) do
      nil ->
        {:reply, {:error, "Discovery not found: #{inspect(discovery_id)}"}, state}

      discovery ->
        updated = %{discovery | law_id: law_id}
        state = put_in(state.discoveries[discovery_id], updated)

        Logger.debug(fn -> "LifecycleRegistry.track_entity would have been called for :discovery, #{inspect(discovery_id)}, :linked_to_law, law=#{inspect(law_id)}" end)

        {:reply, {:ok, updated}, state}
    end
  end

  # ==================== Private Functions ====================

  defp validate_required_fields(data) do
    required = [:id, :name, :domain_id, :experiment_ids, :evidence_ids, :theory_ids]

    missing = Enum.filter(required, fn field ->
      not Map.has_key?(data, field) or is_nil(Map.get(data, field))
    end)

    if length(missing) > 0 do
      {:error, "Missing required fields: #{inspect(missing)}"}
    else
      :ok
    end
  end

  defp build_discovery(data) when is_map(data) do
    %__MODULE__{
      id: Map.get(data, :id),
      name: Map.get(data, :name, ""),
      description: Map.get(data, :description, ""),
      domain_id: Map.get(data, :domain_id),
      program_id: Map.get(data, :program_id),
      experiment_ids: Map.get(data, :experiment_ids, []),
      evidence_ids: Map.get(data, :evidence_ids, []),
      theory_ids: Map.get(data, :theory_ids, []),
      law_id: Map.get(data, :law_id),
      applications: Map.get(data, :applications, []),
      validation_status: Map.get(data, :validation_status, :simulated),
      confidence: Map.get(data, :confidence, 0.5),
      uncertainty: Map.get(data, :uncertainty, 0.5),
      created_at: Map.get(data, :created_at, DateTime.utc_now()),
      validated_at: Map.get(data, :validated_at),
      lifecycle_events: Map.get(data, :lifecycle_events, [])
    }
  end

  defp index_by_domain(state, discovery) do
    current = Map.get(state.domain_index, discovery.domain_id, [])
    put_in(state.domain_index[discovery.domain_id], current ++ [discovery.id])
  end

  defp index_by_theories(state, discovery) do
    Enum.reduce(discovery.theory_ids, state, fn theory_id, acc ->
      current = Map.get(acc.theory_index, theory_id, [])
      put_in(acc.theory_index[theory_id], current ++ [discovery.id])
    end)
  end

  defp update_confidence_for_validation(discovery) do
    base_confidence = discovery.confidence

    confidence_boost = case discovery.validation_status do
      :simulated -> 0.0
      :reproduced -> 0.15
      :operationally_validated -> 0.30
      _ -> 0.0
    end

    new_confidence = min(base_confidence + confidence_boost, 1.0)

    # Recalculate uncertainty as inverse of confidence
    new_uncertainty = Float.round(1.0 - new_confidence, 2)

    %{discovery |
      confidence: Float.round(new_confidence, 2),
      uncertainty: new_uncertainty
    }
  end
end
