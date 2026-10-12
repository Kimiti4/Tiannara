defmodule TiannaraOS.DiscoveryRegistry do
  @moduledoc """
  Discovery Registry - Stores discoveries with explicit evidence lineage.

  Mathematical results use the same registry but remain below laws and
  operational interventions. Registration always begins as :simulated;
  promotion requires an explicit evidence envelope.
  """
  use GenServer
  require Logger

  defstruct [
    :id, :name, :description, :domain_id, :program_id, :experiment_ids,
    :evidence_ids, :theory_ids, :law_id, :applications, :validation_status,
    :confidence, :uncertainty, :created_at, :validated_at, :lifecycle_events,
    :evidence_envelope
  ]

  @type t :: %__MODULE__{}

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def get(id), do: GenServer.call(__MODULE__, {:get, id})
  def list_by_domain(id), do: GenServer.call(__MODULE__, {:list_by_domain, id})
  def find_by_theory(id), do: GenServer.call(__MODULE__, {:find_by_theory, id})
  def register(data), do: GenServer.call(__MODULE__, {:register, data})
  def add_application(id, application), do: GenServer.call(__MODULE__, {:add_application, id, application})
  def update_validation_status(id, status, evidence_envelope \\ %{}),
    do: GenServer.call(__MODULE__, {:update_validation_status, id, status, evidence_envelope})
  def link_to_law(id, law_id), do: GenServer.call(__MODULE__, {:link_to_law, id, law_id})

  @impl true
  def init(_), do: {:ok, %{discoveries: %{}, domain_index: %{}, theory_index: %{}}}

  @impl true
  def handle_call({:get, id}, _, state), do: reply_get(state, id)

  def handle_call({:list_by_domain, id}, _, state) do
    {:reply, {:ok, Enum.map(Map.get(state.domain_index, id, []), &Map.get(state.discoveries, &1)) |> Enum.filter(& &1)}, state}
  end

  def handle_call({:find_by_theory, id}, _, state) do
    {:reply, {:ok, Enum.map(Map.get(state.theory_index, id, []), &Map.get(state.discoveries, &1)) |> Enum.filter(& &1)}, state}
  end

  def handle_call({:register, data}, _, state) do
    with :ok <- required(data),
         {:ok, discovery} <- build_discovery(data),
         false <- Map.has_key?(state.discoveries, discovery.id) do
      new_state = state |> put_in([:discoveries, discovery.id], discovery)
                        |> index_domain(discovery)
                        |> index_theories(discovery)
      {:reply, {:ok, discovery}, new_state}
    else
      true -> {:reply, {:error, :discovery_already_exists}, state}
      {:error, _} = e -> {:reply, e, state}
    end
  end

  def handle_call({:add_application, id, application}, _, state) do
    case Map.get(state.discoveries, id) do
      nil -> {:reply, {:error, :discovery_not_found}, state}
      %{validation_status: :operationally_validated} = discovery ->
        updated = %{discovery | applications: discovery.applications ++ [application]}
        {:reply, {:ok, updated}, put_in(state.discoveries[id], updated)}
      _ ->
        {:reply, {:error, :operational_validation_required_for_application}, state}
    end
  end

  def handle_call({:update_validation_status, id, status, envelope}, _, state) do
    case Map.get(state.discoveries, id) do
      nil -> {:reply, {:error, :discovery_not_found}, state}
      discovery ->
        with :ok <- transition_allowed(discovery.validation_status, status),
             :ok <- validate_promotion_evidence(status, envelope) do
          updated = %{discovery |
            validation_status: status,
            evidence_envelope: envelope,
            validated_at: if(status == :operationally_validated, do: DateTime.utc_now(), else: discovery.validated_at)
          }
          {:reply, {:ok, updated}, put_in(state.discoveries[id], updated)}
        end
    end
  end

  def handle_call({:link_to_law, id, law_id}, _, state) do
    case Map.get(state.discoveries, id) do
      nil -> {:reply, {:error, :discovery_not_found}, state}
      %{validation_status: :operationally_validated} = discovery ->
        updated = %{discovery | law_id: law_id}
        {:reply, {:ok, updated}, put_in(state.discoveries[id], updated)}
      _ -> {:reply, {:error, :operational_validation_required_for_law_link}, state}
    end
  end

  defp reply_get(state, id) do
    case Map.get(state.discoveries, id) do
      nil -> {:reply, {:error, :discovery_not_found}, state}
      discovery -> {:reply, {:ok, discovery}, state}
    end
  end

  defp required(data) when is_map(data) do
    fields = [:id, :name, :domain_id, :experiment_ids, :evidence_ids, :theory_ids]
    case Enum.find(fields, &(not Map.has_key?(data, &1) or is_nil(Map.get(data, &1)))) do
      nil -> :ok
      field -> {:error, {:missing_required_field, field}}
    end
  end
  defp required(_), do: {:error, :invalid_discovery}

  defp build_discovery(data) do
    requested = Map.get(data, :validation_status, :simulated)
    if requested != :simulated do
      {:error, :registration_must_start_simulated}
    else
      {:ok, %__MODULE__{
        id: data.id, name: data.name, description: Map.get(data, :description, ""),
        domain_id: data.domain_id, program_id: Map.get(data, :program_id),
        experiment_ids: data.experiment_ids, evidence_ids: data.evidence_ids,
        theory_ids: data.theory_ids, law_id: nil, applications: [],
        validation_status: :simulated, confidence: 0.0, uncertainty: 1.0,
        created_at: Map.get(data, :created_at, DateTime.utc_now()),
        validated_at: nil, lifecycle_events: [], evidence_envelope: %{}
      }}
    end
  end

  defp transition_allowed(:simulated, :reproduced), do: :ok
  defp transition_allowed(:reproduced, :operationally_validated), do: :ok
  defp transition_allowed(_, _), do: {:error, :invalid_status_transition}

  defp validate_promotion_evidence(:reproduced, envelope) do
    if is_map(envelope) and Map.has_key?(envelope, :reproduction_evidence),
      do: :ok, else: {:error, :reproduction_evidence_required}
  end

  defp validate_promotion_evidence(:operationally_validated, envelope) do
    required = [:evidence_class, :execution_mode, :real_observation, :effect_verified, :acl_status, :oavl_status]
    cond do
      not is_map(envelope) -> {:error, :operational_evidence_required}
      Enum.any?(required, &(not Map.has_key?(envelope, &1))) -> {:error, :operational_evidence_incomplete}
      envelope.evidence_class != :real -> {:error, :real_evidence_required}
      envelope.execution_mode != :real_execution -> {:error, :real_execution_required}
      envelope.real_observation != true -> {:error, :real_observation_required}
      envelope.effect_verified != true -> {:error, :effect_verification_required}
      envelope.acl_status not in [:pass, :passed] -> {:error, :acl_required}
      envelope.oavl_status not in [:pass, :passed] -> {:error, :oavl_required}
      true -> :ok
    end
  end
  defp validate_promotion_evidence(_, _), do: {:error, :unsupported_promotion_status}

  defp index_domain(state, discovery) do
    ids = Map.get(state.domain_index, discovery.domain_id, [])
    put_in(state.domain_index[discovery.domain_id], ids ++ [discovery.id])
  end

  defp index_theories(state, discovery) do
    Enum.reduce(discovery.theory_ids, state, fn theory_id, acc ->
      ids = Map.get(acc.theory_index, theory_id, [])
      put_in(acc.theory_index[theory_id], ids ++ [discovery.id])
    end)
  end
end
