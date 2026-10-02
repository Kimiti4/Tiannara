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
    :lifecycle_events,
    :evidence_envelope,
    :verification_graph_ids,
    :archive_ids
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
    lifecycle_events: [map()],
    evidence_envelope: map(),
    verification_graph_ids: [String.t()],
    archive_ids: [String.t()]
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
  @doc """
  Legacy promotion API intentionally fails closed.

  Validation-state changes must use update_validation_status_with_lineage/4
  so the registry cannot advance epistemic state without an immutable
  verification-graph/archive record.
  """
  def update_validation_status(_discovery_id, _new_status, _evidence_envelope \\ %{}) do
    {:error, :validation_transition_requires_lineage}
  end

  def update_validation_status_with_lineage(discovery_id, new_status, evidence_envelope, lineage_writer) do
    GenServer.call(__MODULE__, {:update_validation_status_with_lineage, discovery_id, new_status, evidence_envelope, lineage_writer})
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
    # Registration is always conservative: callers cannot claim a higher
    # epistemic state merely by supplying validation_status/confidence.
    with :ok <- validate_required_fields(discovery_data),
         {:ok, evidence_envelope} <- normalize_evidence(Map.get(discovery_data, :evidence_envelope, %{})),
         :ok <- validate_registration_status(Map.get(discovery_data, :validation_status, :simulated), evidence_envelope),
         discovery <- build_discovery(Map.put(discovery_data, :evidence_envelope, evidence_envelope)) do
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
  def handle_call({:update_validation_status_with_lineage, discovery_id, new_status, evidence_envelope, lineage_writer}, _from, state) do
    with {:ok, discovery} <- fetch_discovery(state, discovery_id),
         {:ok, envelope} <- normalize_evidence(evidence_envelope),
         allowed when is_list(allowed) <- Map.get(%{simulated: [:reproduced], reproduced: [:operationally_validated], operationally_validated: []}, discovery.validation_status, []),
         true <- new_status in allowed,
         :ok <- validate_transition_evidence(new_status, envelope),
         {:ok, lineage} <- write_validation_lineage(discovery, new_status, envelope, lineage_writer) do
      updated = %{discovery |
        validation_status: new_status,
        evidence_envelope: merge_evidence(discovery.evidence_envelope, envelope),
        verification_graph_ids: discovery.verification_graph_ids ++ [lineage.graph_id],
        archive_ids: discovery.archive_ids ++ [lineage.archive_hash],
        validated_at: if(new_status == :operationally_validated, do: DateTime.utc_now(), else: discovery.validated_at),
        lifecycle_events: discovery.lifecycle_events ++ [%{event: :validation_updated, from: discovery.validation_status, to: new_status, evidence: envelope, lineage: lineage}]
      }
      {:reply, {:ok, updated}, put_in(state.discoveries[discovery_id], updated)}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
      false -> {:reply, {:error, :invalid_status_transition}, state}
      _ -> {:reply, {:error, :invalid_status_transition}, state}
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

  defp fetch_discovery(state, id) do
    case Map.get(state.discoveries, id) do
      nil -> {:error, :discovery_not_found}
      discovery -> {:ok, discovery}
    end
  end

  defp write_validation_lineage(discovery, new_status, envelope, writer) when is_function(writer, 1) do
    node = %{
      kind: :discovery_validation_transition,
      discovery_id: discovery.id,
      parent_ids: Map.get(discovery, :verification_graph_ids, []),
      provenance: %{source: :discovery_registry, transition: {discovery.validation_status, new_status}},
      status: new_status,
      artifact: %{from: discovery.validation_status, to: new_status, evidence: envelope}
    }

    case Tiannara.Sentinel.DiscoveryVerificationGraph.append_with_archive(node, writer) do
      {:ok, %{graph: graph, archive: archive}} ->
        {:ok, %{graph_id: graph.node_id, archive_hash: archive.hash}}
      {:error, reason} -> {:error, {:lineage_write_failed, reason}}
    end
  end

  defp write_validation_lineage(_discovery, _new_status, _envelope, _writer),
    do: {:error, :lineage_writer_unavailable}

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
      # Never trust caller-supplied confidence/status as evidence.
      validation_status: :simulated,
      confidence: 0.0,
      uncertainty: 1.0,
      created_at: Map.get(data, :created_at, DateTime.utc_now()),
      validated_at: Map.get(data, :validated_at),
      lifecycle_events: Map.get(data, :lifecycle_events, []),
      evidence_envelope: Map.get(data, :evidence_envelope, %{}),
      verification_graph_ids: Map.get(data, :verification_graph_ids, []),
      archive_ids: Map.get(data, :archive_ids, [])
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

  defp normalize_evidence(envelope) when is_map(envelope) do
    class = Map.get(envelope, :evidence_class, Map.get(envelope, "evidence_class", :unknown))
    mode = Map.get(envelope, :execution_mode, Map.get(envelope, "execution_mode", :unknown))

    if class in [:simulated, :real, :unknown] and mode in [:simulation, :real_execution, :unknown] do
      {:ok, Map.put(envelope, :evidence_class, class) |> Map.put(:execution_mode, mode)}
    else
      {:error, :invalid_evidence_envelope}
    end
  end

  defp normalize_evidence(_), do: {:error, :invalid_evidence_envelope}

  defp validate_registration_status(:simulated, envelope) do
    if Map.get(envelope, :evidence_class) == :simulated and
         Map.get(envelope, :execution_mode) == :simulation do
      :ok
    else
      {:error, :simulated_registration_requires_simulation_evidence}
    end
  end
  defp validate_registration_status(:reproduced, _envelope), do: {:error, :registration_must_start_simulated}
  defp validate_registration_status(:operationally_validated, _envelope), do: {:error, :registration_must_start_simulated}
  defp validate_registration_status(_, _), do: {:error, :invalid_validation_status}

  defp validate_transition_evidence(:reproduced, envelope) do
    reproduced = Map.get(envelope, :reproduction_evidence, Map.get(envelope, "reproduction_evidence"))
    if present?(reproduced), do: :ok, else: {:error, :reproduction_evidence_required}
  end

  defp validate_transition_evidence(:operationally_validated, envelope) do
    real = Map.get(envelope, :evidence_class)
    mode = Map.get(envelope, :execution_mode)
    real_observed = Map.get(envelope, :real_observation, false)
    effect_verified = Map.get(envelope, :effect_verified, false)
    acl = Map.get(envelope, :acl_status)
    oavl = Map.get(envelope, :oavl_status)

    cond do
      real != :real -> {:error, :real_evidence_required}
      mode != :real_execution -> {:error, :real_execution_required}
      real_observed != true -> {:error, :real_observation_required}
      effect_verified != true -> {:error, :effect_verification_required}
      acl not in [:pass, :passed] -> {:error, :acl_validation_required}
      oavl not in [:pass, :passed] -> {:error, :oavl_validation_required}
      true -> :ok
    end
  end

  defp merge_evidence(old, new), do: Map.merge(old || %{}, new)

  defp present?(value), do: not is_nil(value) and value not in [[], %{}, "", false]

end
