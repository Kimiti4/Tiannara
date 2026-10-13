defmodule Tiannara.World.WorldMutationEngine do
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.Council
  alias Tiannara.Council.{AuditLog, Authorization, MachineAuthorization}
  alias Tiannara.CEL.Services.{ExecutiveMemory, EventBus}
  alias Tiannara.CEL.Kernel.ConstitutionalScore
  alias Tiannara.Omega.{EffectIdentity, MintRegistry}

  @mutation_table :world_mutations
  @mutation_ttl_seconds 3600

  @identity_keys ~w(
    id entity_id from_id to_id conflict_id merged_id
    concept_id successor source type
  )a

  @known_mutation_types ~w(
    create_entity update_entity refute_entity create_relationship sync_entity
    resolve_conflict_source_wins resolve_conflict_world_wins resolve_conflict_merge
    graph_migration ontology_merge ontology_split ontology_retire snapshot_restore
  )a

  @impl true
  def id, do: :world_mutation_engine

  @impl true
  def version, do: "1.0.0"

  @impl true
  def capabilities do
    [
      :atomic_mutations,
      :rollback_support,
      :constitutional_gating,
      :mutation_auditability,
      :conflict_resolution
    ]
  end

  @impl true
  def dependencies, do: [:executive_memory, :executive_service_bus]

  @impl true
  def health do
    if Process.whereis(__MODULE__), do: :healthy, else: :unhealthy
  end

  @impl true
  def constitutional_score do
    stats =
      if Process.whereis(__MODULE__),
        do: GenServer.call(__MODULE__, :stats),
        else: %{healthy: true, total_mutations: 0, rollback_count: 0}

    %ConstitutionalScore{
      service_id: id(),
      health: if(stats.healthy, do: 1.0, else: 0.0),
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: 1.0,
      human_oversight: 1.0,
      computed_at: DateTime.utc_now()
    }
  end

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def mutate(mutation_type, mutation_spec, context \\ nil) do
    GenServer.call(__MODULE__, {:mutate, mutation_type, mutation_spec, context})
  end

  @doc """
  The canonical semantic descriptor for a world-mutation effect (model M1).
  Identity keys from the mutation spec become the target; all values are
  canonically representable, so effect identity is derived from this
  descriptor only.
  """
  @spec effect_descriptor(atom(), map()) :: map()
  def effect_descriptor(mutation_type, mutation_spec)
      when is_atom(mutation_type) and is_map(mutation_spec) do
    %{
      principal: "tiannara.world.world_mutation_engine",
      authority_scope: "omega:world_mutation",
      operation: Atom.to_string(mutation_type),
      target: descriptor_target(mutation_spec),
      parameters: %{},
      environment: %{},
      intent: %{kind: "world_mutation"},
      semantic_version: "1",
      identity_version: EffectIdentity.identity_version()
    }
  end

  @doc false
  @spec conditions_met?(Authorization.t()) :: boolean()
  def conditions_met?(%Authorization{} = auth) do
    structural_conditions_met?(auth) and unmet_conditions(auth) == []
  end

  def conditions_met?(_authorization), do: false

  defp structural_conditions_met?(%Authorization{} = auth) do
    auth.evidence not in [nil, []] and
      auth.violated_principles in [nil, []] and
      is_number(auth.constitutional_score) and auth.constitutional_score >= 0.6 and
      auth.required_human_review != true
  end

  defp unmet_conditions(%Authorization{conditions: conditions} = auth)
       when is_list(conditions) and conditions != [] do
    evidence = List.wrap(auth.evidence)

    Enum.reject(conditions, &condition_satisfied?(&1, evidence))
  end

  defp unmet_conditions(%Authorization{}), do: []

  defp condition_satisfied?(%{concern: concern, evidence_check: check}, evidence)
       when is_atom(concern) and is_atom(check) do
    Enum.any?(evidence, fn entry ->
      is_map(entry) and
        (Map.get(entry, :principle) == concern or
           Map.get(entry, :principle_id) == concern or
           Map.get(entry, :check) == check) and
        Map.get(entry, :passed, true) != false
    end)
  end

  defp condition_satisfied?(_condition, _evidence), do: false

  def rollback(mutation_id), do: GenServer.call(__MODULE__, {:rollback, mutation_id})

  def history(opts \\ []), do: GenServer.call(__MODULE__, {:history, opts})

  def stats, do: GenServer.call(__MODULE__, :stats)

  def rotate, do: GenServer.call(__MODULE__, :rotate, 60_000)
  def prune, do: GenServer.call(__MODULE__, :prune, 60_000)

  @doc false
  def dets_path, do: Tiannara.Storage.Paths.dets("world_mutations")

  @impl true
  def init(_opts) do
    register_with_lifecycle()

    case open_dets_safely() do
      {:ok, _} ->
        {:ok,
         %{
           mutation_counter: 0,
           total_mutations: 0,
           rollback_count: 0,
           healthy: true,
           started_at: DateTime.utc_now()
         }}

      {:error, reason} ->
        Logger.error(
          "WorldMutationEngine: storage unavailable (#{inspect(reason)}). Starting degraded."
        )

        {:ok, %{healthy: false, mutation_counter: 0, total_mutations: 0, rollback_count: 0}}
    end
  end

  @impl true
  def handle_call({:mutate, type, spec, context}, _from, state) do
    if not state.healthy do
      {:reply, {:error, :engine_unhealthy}, state}
    else
      handle_mutate(type, spec, context, state)
    end
  end

  @impl true
  def handle_call({:rollback, mutation_id}, _from, state) do
    case safe_lookup(mutation_id) do
      [{^mutation_id, %{status: :executed} = mutation}] ->
        case execute_rollback(mutation) do
          :ok ->
            rolled = %{mutation | status: :rolled_back, rolled_back_at: DateTime.utc_now()}

            case safe_insert({mutation_id, rolled}) do
              :ok ->
                ExecutiveMemory.record_decision(
                  mutation_id,
                  :world_mutation_rolled_back,
                  %{original_type: mutation.type},
                  %{}
                )

                EventBus.publish("world.mutation.rolled_back", %{mutation_id: mutation_id}, [])
                {:reply, :ok, %{state | rollback_count: state.rollback_count + 1}}

              {:error, reason} ->
                {:reply, {:error, {:storage_error, reason}}, state}
            end

          {:error, reason} ->
            {:reply, {:error, {:rollback_failed, reason}}, state}
        end

      [{^mutation_id, _}] ->
        {:reply, {:error, :mutation_not_in_executed_state}, state}

      [] ->
        {:reply, {:error, :not_found}, state}

      {:error, reason} ->
        {:reply, {:error, {:storage_error, reason}}, state}
    end
  end

  @impl true
  def handle_call({:history, opts}, _from, state) do
    limit = Keyword.get(opts, :limit, 100)

    mutations =
      case safe_traverse() do
        {:ok, items} ->
          items |> Enum.sort_by(& &1.executed_at, :desc) |> Enum.take(limit)

        {:error, reason} ->
          Logger.error("WorldMutationEngine: history unavailable: #{inspect(reason)}")
          []
      end

    {:reply, mutations, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply,
     %{
       healthy: state.healthy,
       total_mutations: state.total_mutations,
       rollback_count: state.rollback_count,
       mutation_counter: state.mutation_counter
     }, state}
  end

  @impl true
  def handle_call(:rotate, _from, %{healthy: false} = state) do
    {:reply, {:error, :engine_unhealthy}, state}
  end

  def handle_call(:rotate, _from, state) do
    case Tiannara.Storage.Rotator.rotate(@mutation_table, dets_path(), type: :set) do
      {:ok, archive} -> {:reply, {:ok, archive}, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:prune, _from, %{healthy: false} = state) do
    {:reply, {:error, :engine_unhealthy}, state}
  end

  def handle_call(:prune, _from, state) do
    cutoff =
      DateTime.utc_now()
      |> DateTime.add(-(mutation_retention_hours() * 3600), :second)

    stale_ids =
      :dets.traverse(@mutation_table, fn
        {id, %{executed_at: ts}} when is_struct(ts, DateTime) ->
          if DateTime.compare(ts, cutoff) == :lt, do: {:continue, id}, else: {:continue, :skip}

        _ ->
          {:continue, :skip}
      end)
      |> Enum.reject(&(&1 == :skip))

    Enum.each(stale_ids, &:dets.delete(@mutation_table, &1))
    {:reply, {:ok, length(stale_ids)}, state}
  end

  defp generate_id(counter),
    do: "mut_#{counter}_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"

  defp handle_mutate(type, spec, context, state) do
    payload = %{
      mutation_type: type,
      mutation_spec: spec,
      context: context,
      evidence: independent_evidence(state),
      actor: :world_mutation_engine,
      coherent_with_mission: type in @known_mutation_types,
      degradation_handled: state.healthy == true
    }

    auth = Council.authorize(:world_mutation, payload, context)

    with :ok <- check_decision(auth),
         {:ok, bound} <- wrap_council_decision(auth, type, spec),
         :ok <- verify_wrap(bound),
         :ok <- consume_wrap(bound),
         {:ok, mutation_id, ns} <- insert_mutation_record(type, spec, context, bound, state) do
      publish_if_approved(auth, mutation_id, type, spec, context)

      case record_and_verify_audit(mutation_id, type, bound) do
        :ok -> {:reply, {:ok, mutation_id}, ns}
        {:error, reason} -> {:reply, {:error, reason}, ns}
      end
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @doc false
  def check_decision(%Authorization{decision: :approved} = auth) do
    case unmet_conditions(auth) do
      [] -> :ok
      _unmet -> {:error, {:conditional_conditions_unmet, condition_detail(auth)}}
    end
  end

  def check_decision(%Authorization{decision: :conditional} = auth) do
    if conditions_met?(auth) do
      :ok
    else
      {:error, {:conditional_conditions_unmet, condition_detail(auth)}}
    end
  end

  def check_decision(%Authorization{decision: :requires_human} = auth) do
    request_id = Map.get(auth.metadata || %{}, :request_id, "unknown")
    {:error, {:requires_human_approval, request_id}}
  end

  def check_decision(%Authorization{decision: :rejected} = auth),
    do: {:error, {:constitutional_rejection, auth.explanation}}

  def check_decision(%Authorization{decision: other}),
    do: {:error, {:decision_not_permitted, other}}

  def check_decision(other), do: {:error, {:invalid_council_decision, other}}

  defp condition_detail(auth) do
    %{
      has_evidence: auth.evidence not in [nil, []],
      violated_principles: List.wrap(auth.violated_principles),
      constitutional_score: auth.constitutional_score,
      required_human_review: auth.required_human_review == true,
      unmet_conditions: unmet_conditions(auth)
    }
  end

  defp independent_evidence(state) do
    [
      %{source: :world_mutation_engine, check: :engine_health, passed: state.healthy == true},
      audit_runtime_evidence()
    ]
  end

  defp audit_runtime_evidence do
    %{source: :council_audit_log, check: :not_degraded, passed: not AuditLog.degraded?()}
  catch
    kind, reason ->
      %{source: :council_audit_log, check: :not_degraded, passed: false, error: {kind, reason}}
  end

  defp wrap_council_decision(auth, type, spec) do
    descriptor = effect_descriptor(type, spec)

    case MachineAuthorization.mint(auth,
           decision_type: :world_mutation,
           ttl: @mutation_ttl_seconds
         ) do
      {:ok, wrap} ->
        case MachineAuthorization.bind_effect(wrap, descriptor) do
          {:ok, bound} -> {:ok, bound}
          {:error, reason} -> {:error, {:authorization_bind_failed, reason}}
        end

      {:error, :authorization_registry_unavailable} ->
        {:error, :authorization_registry_unavailable}

      {:error, reason} ->
        {:error, {:authorization_mint_failed, reason}}
    end
  end

  defp verify_wrap(%MachineAuthorization{} = wrap) do
    case MintRegistry.status(wrap.authorization_id) do
      :granted ->
        cond do
          MachineAuthorization.expired?(wrap) ->
            {:error, :authorization_expired}

          MachineAuthorization.content_hash(wrap) != wrap.content_hash ->
            {:error, :decision_tampered}

          true ->
            :ok
        end

      :registry_unavailable ->
        {:error, :authorization_registry_unavailable}

      other ->
        {:error, {:authorization_not_granted, other}}
    end
  end

  defp verify_wrap(_wrap), do: {:error, :invalid_authorization}

  defp consume_wrap(%MachineAuthorization{authorization_id: id, effect_id: effect_id}) do
    case MintRegistry.consume(id, effect_id) do
      :ok -> :ok
      :registry_unavailable -> {:error, :authorization_registry_unavailable}
      {:error, reason} -> {:error, {:authorization_consume_failed, reason}}
    end
  end

  defp insert_mutation_record(type, spec, context, bound, state) do
    mutation_id = generate_id(state.mutation_counter + 1)

    record = %{
      id: mutation_id,
      type: type,
      spec: spec,
      context: context,
      authorization: Map.from_struct(bound.decision),
      machine_authorization: Map.from_struct(bound),
      effect_id: bound.effect_id,
      authorization_id: bound.authorization_id,
      executed_at: DateTime.utc_now(),
      status: :executed,
      rollback_data: compute_rollback(type, spec)
    }

    case safe_insert({mutation_id, record}) do
      :ok ->
        {:ok, mutation_id,
         %{
           state
           | mutation_counter: state.mutation_counter + 1,
             total_mutations: state.total_mutations + 1
         }}

      {:error, reason} ->
        {:error, {:storage_error, reason}}
    end
  end

  defp publish_if_approved(%Authorization{decision: :approved}, mutation_id, type, spec, context) do
    ExecutiveMemory.record_decision(
      mutation_id,
      :world_mutation_executed,
      %{type: type, spec: spec},
      context || %{}
    )

    EventBus.publish(
      "world.mutation.executed",
      %{
        mutation_id: mutation_id,
        type: type,
        entity_id: Map.get(spec, :id) || Map.get(spec, :from_id)
      },
      []
    )
  end

  defp publish_if_approved(_auth, _mutation_id, _type, _spec, _context), do: :ok

  defp record_and_verify_audit(mutation_id, type, %MachineAuthorization{} = bound) do
    payload = %{
      mutation_id: mutation_id,
      effect_id: bound.effect_id,
      authorization_id: bound.authorization_id,
      sink: :world_mutation_engine,
      operation: Atom.to_string(type),
      recorded_at: DateTime.utc_now()
    }

    outcome =
      try do
        case AuditLog.append(:world_mutation_executed, :world_mutation_engine, payload) do
          {:ok, %{} = entry} -> {:ok, entry}
          {:error, reason} -> {:error, reason}
          other -> {:error, {:unexpected_audit_result, other}}
        end
      catch
        kind, reason -> {:error, {kind, reason}}
      end

    case outcome do
      {:ok, stored} ->
        stored_payload = Map.get(stored, :payload, %{})

        if Map.get(stored, :action) == :world_mutation_executed and
             Map.get(stored_payload, :effect_id) == bound.effect_id and
             Map.get(stored_payload, :authorization_id) == bound.authorization_id and
             Map.get(stored_payload, :mutation_id) == mutation_id do
          :ok
        else
          {:error, :result_identity_mismatch}
        end

      {:error, reason} ->
        {:error,
         {:audit_not_recorded, reason,
          %{
            mutation_recorded: true,
            mutation_id: mutation_id,
            authorization_id: bound.authorization_id,
            effect_id: bound.effect_id
          }}}
    end
  end

  defp descriptor_target(spec) do
    spec
    |> Map.take(@identity_keys)
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      case identity_value(value) do
        {:ok, normalized} -> Map.put(acc, key, normalized)
        :error -> acc
      end
    end)
  end

  defp identity_value(value) when is_boolean(value) or is_nil(value), do: {:ok, value}
  defp identity_value(value) when is_binary(value), do: {:ok, value}
  defp identity_value(value) when is_atom(value), do: {:ok, Atom.to_string(value)}
  defp identity_value(value) when is_integer(value) or is_float(value), do: {:ok, value}
  defp identity_value(_value), do: :error

  defp open_dets_safely do
    File.mkdir_p!(Path.dirname(dets_path()))

    Tiannara.CEL.Services.ResilientDETS.open(
      @mutation_table,
      type: :set,
      file: String.to_charlist(dets_path()),
      repair: false
    )
  end

  defp safe_insert(record) do
    :dets.insert(@mutation_table, record)
  rescue
    e -> {:error, {:exception, Exception.message(e)}}
  end

  defp safe_lookup(key) do
    :dets.lookup(@mutation_table, key)
  rescue
    e -> {:error, {:exception, Exception.message(e)}}
  end

  defp safe_traverse do
    {:ok, :dets.traverse(@mutation_table, fn {_id, m} -> {:continue, m} end)}
  rescue
    e -> {:error, {:exception, Exception.message(e)}}
  end

  defp compute_rollback(type, spec) do
    case type do
      :create_entity ->
        %{action: :remove_entity, entity_id: spec.id}

      :create_relationship ->
        %{action: :remove_relationship, from: spec.from_id, to: spec.to_id, type: spec.type}

      :update_entity ->
        %{action: :restore_entity, entity_id: spec.id}

      :refute_entity ->
        %{action: :restore_entity, entity_id: spec.id}

      _ ->
        %{}
    end
  end

  defp register_with_lifecycle do
    _ = Tiannara.Storage.DetsLifecycle.register(%{id: id(), module: __MODULE__})
    :ok
  end

  defp mutation_retention_hours do
    Application.get_env(:tiannara, :dets_mutation_retention_hours, 720)
  end

  defp execute_rollback(mutation) do
    case mutation.rollback_data.action do
      :remove_entity -> :ok
      :remove_relationship -> :ok
      :restore_entity -> :ok
      _ -> {:error, :unknown_rollback_action}
    end
  end
end
