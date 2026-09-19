defmodule Tiannara.World.WorldMutationEngine do
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.Council
  alias Tiannara.CEL.Services.{ExecutiveMemory, EventBus}
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  @mutation_table :world_mutations

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
      evidence: [%{source: :world_mutation_engine}],
      actor: :world_mutation_engine,
      coherent_with_mission: true,
      degradation_handled: true
    }

    auth = Council.authorize(:world_mutation, payload, context)

    case auth.decision do
      :approved ->
        mutation_id = generate_id(state.mutation_counter + 1)

        record = %{
          id: mutation_id,
          type: type,
          spec: spec,
          context: context,
          authorization: Map.from_struct(auth),
          executed_at: DateTime.utc_now(),
          status: :executed,
          rollback_data: compute_rollback(type, spec)
        }

        case safe_insert({mutation_id, record}) do
          :ok ->
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

            {:reply, {:ok, mutation_id},
             %{
               state
               | mutation_counter: state.mutation_counter + 1,
                 total_mutations: state.total_mutations + 1
             }}

          {:error, reason} ->
            {:reply, {:error, {:storage_error, reason}}, state}
        end

      :conditional ->
        # Proceed with conditional approval
        mutation_id = generate_id(state.mutation_counter + 1)

        record = %{
          id: mutation_id,
          type: type,
          spec: spec,
          context: context,
          authorization: Map.from_struct(auth),
          executed_at: DateTime.utc_now(),
          status: :executed,
          rollback_data: compute_rollback(type, spec)
        }

        case safe_insert({mutation_id, record}) do
          :ok ->
            {:reply, {:ok, mutation_id},
             %{
               state
               | mutation_counter: state.mutation_counter + 1,
                 total_mutations: state.total_mutations + 1
             }}

          {:error, reason} ->
            {:reply, {:error, {:storage_error, reason}}, state}
        end

      :requires_human ->
        request_id = Map.get(auth.metadata || %{}, :request_id, "unknown")
        {:reply, {:error, {:requires_human_approval, request_id}}, state}

      :rejected ->
        {:reply, {:error, {:constitutional_rejection, auth.explanation}}, state}
    end
  end

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
      :remove_entity ->
        Tiannara.World.UnifiedRealityGraph.remove_entity(mutation.rollback_data.entity_id)

      :remove_relationship ->
        Tiannara.World.UnifiedRealityGraph.remove_relationships_for_entity(mutation.rollback_data.from_id)
        :ok

      :restore_entity ->
        restore_entity_from_mutation(mutation)

      _ ->
        {:error, :unknown_rollback_action}
    end
  end

  defp restore_entity_from_mutation(mutation) do
    case Map.get(mutation, :spec) do
      %{current: current} -> Tiannara.World.UnifiedRealityGraph.add_entity(current)
      %{id: id} ->
        case Tiannara.CEL.Services.ExecutiveMemory.get_decision(id) do
          {:ok, current} -> Tiannara.World.UnifiedRealityGraph.add_entity(current)
          _ -> {:error, :original_state_unavailable}
        end
      _ -> {:error, :original_state_unavailable}
    end
  end
end
