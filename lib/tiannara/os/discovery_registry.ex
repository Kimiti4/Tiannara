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
    :evidence_envelope, :verification_graph_ids, :archive_ids
  ]

  @type t :: %__MODULE__{}

  @table :tiannara_discovery_registry
  @default_file "data/discovery_registry.dets"

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def get(id), do: GenServer.call(__MODULE__, {:get, id})
  def list_by_domain(id), do: GenServer.call(__MODULE__, {:list_by_domain, id})
  def find_by_theory(id), do: GenServer.call(__MODULE__, {:find_by_theory, id})
  def register(data), do: GenServer.call(__MODULE__, {:register, data})
  def add_application(id, application), do: GenServer.call(__MODULE__, {:add_application, id, application})
  def update_validation_status(_id, _status, _evidence_envelope \\ %{}),
    do: {:error, :validation_transition_requires_lineage}

  def update_validation_status_with_lineage(id, status, evidence_envelope, lineage_writer \\ &default_lineage_writer/1),
    do: GenServer.call(__MODULE__, {:update_validation_status_with_lineage, id, status, evidence_envelope, lineage_writer})
  def link_to_law(id, law_id), do: GenServer.call(__MODULE__, {:link_to_law, id, law_id})

  @impl true
  def init(opts) do
    default_path =
      if Application.get_env(:tiannara, :test_mode, false),
        do: "test_data/discovery_registry.dets",
        else: @default_file

    path =
      Keyword.get(
        opts,
        :file,
        Application.get_env(:tiannara, :discovery_registry_file, default_path)
      )

    File.mkdir_p!(Path.dirname(path))

    case :dets.open_file(@table, type: :set, file: String.to_charlist(path), repair: true) do
      {:ok, _} ->
        discoveries =
          :dets.traverse(@table, fn {id, discovery} -> {:continue, {id, discovery}} end)
          |> Map.new()

        state =
          Enum.reduce(Map.values(discoveries), %{discoveries: discoveries, domain_index: %{}, theory_index: %{}}, fn discovery, acc ->
            acc |> index_domain(discovery) |> index_theories(discovery)
          end)

        {:ok, state}

      {:error, reason} ->
        {:stop, {:discovery_registry_open_failed, reason}}
    end
  end

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
      case :dets.insert(@table, {discovery.id, discovery}) do
        :ok ->
          new_state = state |> put_in([:discoveries, discovery.id], discovery)
                            |> index_domain(discovery)
                            |> index_theories(discovery)
          {:reply, {:ok, discovery}, new_state}

        {:error, reason} ->
          {:reply, {:error, {:discovery_persistence_failed, reason}}, state}
      end
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
        case :dets.insert(@table, {id, updated}) do
          :ok -> {:reply, {:ok, updated}, put_in(state.discoveries[id], updated)}
          {:error, reason} -> {:reply, {:error, {:discovery_persistence_failed, reason}}, state}
        end
      _ ->
        {:reply, {:error, :operational_validation_required_for_application}, state}
    end
  end

  def handle_call({:update_validation_status_with_lineage, id, status, envelope, writer}, _, state) do
    case Map.get(state.discoveries, id) do
      nil -> {:reply, {:error, :discovery_not_found}, state}
      discovery ->
        with :ok <- transition_allowed(discovery.validation_status, status),
             :ok <- validate_promotion_evidence(status, envelope),
             {:ok, lineage} <- write_validation_lineage(discovery, status, envelope, writer) do
          updated = %{discovery |
            validation_status: status,
            evidence_envelope: Map.merge(discovery.evidence_envelope || %{}, envelope),
            verification_graph_ids: discovery.verification_graph_ids ++ [lineage.graph_id],
            archive_ids: discovery.archive_ids ++ [lineage.archive_hash],
            validated_at: if(status == :operationally_validated, do: DateTime.utc_now(), else: discovery.validated_at),
            lifecycle_events: discovery.lifecycle_events ++ [%{
              event: :validation_updated,
              from: discovery.validation_status,
              to: status,
              evidence: envelope,
              lineage: lineage
            }]
          }
          case :dets.insert(@table, {id, updated}) do
            :ok -> {:reply, {:ok, updated}, put_in(state.discoveries[id], updated)}
            {:error, reason} -> {:reply, {:error, {:discovery_persistence_failed, reason}}, state}
          end
        end
    end
  end

  def handle_call({:link_to_law, id, law_id}, _, state) do
    case Map.get(state.discoveries, id) do
      nil -> {:reply, {:error, :discovery_not_found}, state}
      %{validation_status: :operationally_validated} = discovery ->
        updated = %{discovery | law_id: law_id}
        case :dets.insert(@table, {id, updated}) do
          :ok -> {:reply, {:ok, updated}, put_in(state.discoveries[id], updated)}
          {:error, reason} -> {:reply, {:error, {:discovery_persistence_failed, reason}}, state}
        end
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
        validated_at: nil, lifecycle_events: [], evidence_envelope: %{},
        verification_graph_ids: [], archive_ids: []
      }}
    end
  end

  defp transition_allowed(:simulated, :reproduced), do: :ok
  defp transition_allowed(:reproduced, :operationally_validated), do: :ok
  defp transition_allowed(_, _), do: {:error, :invalid_status_transition}

  defp validate_promotion_evidence(:reproduced, envelope) do
    reproduction = if is_map(envelope), do: Map.get(envelope, :reproduction_evidence), else: nil

    cond do
      not is_map(envelope) ->
        {:error, :reproduction_evidence_required}
      not is_map(reproduction) ->
        {:error, :reproduction_evidence_required}
      Map.get(envelope, :evidence_class) not in [:real, :simulated] ->
        {:error, :invalid_evidence_envelope}
      Map.get(envelope, :evidence_class) != :real ->
        {:error, :real_reproduction_evidence_required}
      Map.get(envelope, :execution_mode) != :real_execution ->
        {:error, :real_execution_required}
      Map.get(envelope, :real_observation) != true ->
        {:error, :real_observation_required}
      Map.get(envelope, :effect_verified) != true ->
        {:error, :effect_verification_required}
      not is_integer(Map.get(reproduction, :replications)) or Map.get(reproduction, :replications) < 3 ->
        {:error, :three_replications_required}
      Map.get(reproduction, :independent_runs) != true ->
        {:error, :independent_replications_required}
      true ->
        :ok
    end
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

  defp write_validation_lineage(discovery, status, envelope, writer) when is_function(writer, 1) do
    ensure_lineage_services()
    node = %{
      kind: :discovery_validation_transition,
      discovery_id: discovery.id,
      parent_ids: List.last(discovery.verification_graph_ids, []) |> List.wrap(),
      provenance: %{source: :discovery_registry, transition: {discovery.validation_status, status}},
      status: status,
      artifact: %{from: discovery.validation_status, to: status, evidence: envelope}
    }
    case Tiannara.Sentinel.DiscoveryVerificationGraph.append_with_archive(node) do
      {:ok, %{graph: graph, archive: archive}} ->
        case writer.(archive) do
          {:ok, _} -> {:ok, %{graph_id: graph.node_id, archive_hash: archive.hash}}
          {:error, reason} -> {:error, {:lineage_write_failed, reason}}
          _ -> {:error, :lineage_writer_rejected}
        end
      {:error, reason} -> {:error, {:lineage_write_failed, reason}}
    end
  end

  defp write_validation_lineage(_, _, _, _), do: {:error, :lineage_writer_unavailable}

  defp default_lineage_writer(archive), do: {:ok, archive}

  defp ensure_lineage_services do
    unless Process.whereis(Tiannara.Sentinel.DiscoveryEvidenceArchive) do
      case Tiannara.Sentinel.DiscoveryEvidenceArchive.start_link([]) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
        {:error, reason} -> raise "discovery evidence archive unavailable: #{inspect(reason)}"
      end
    end
    unless Process.whereis(Tiannara.Sentinel.DiscoveryVerificationGraph) do
      case Tiannara.Sentinel.DiscoveryVerificationGraph.start_link([]) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
        {:error, reason} -> raise "discovery verification graph unavailable: #{inspect(reason)}"
      end
    end
  end

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
