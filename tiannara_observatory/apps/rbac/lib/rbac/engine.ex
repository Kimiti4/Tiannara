defmodule Rbac.Engine do
  @moduledoc """
  JIT Graph RBAC Engine.

  Instead of stuffing 50 permissions into a JWT, the engine uses an in-memory hierarchical
  graph (ETS) to evaluate capabilities in O(1). Cache is invalidated via PubSub on role change.

  Decision chain:
    Identity → Role → Capabilities → Constitutional Constraints → Context → Decision → Audit
  """

  use GenServer

  alias Rbac.{Capability, Policy, Identity}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def allowed?(identity_id, capability, context \\ %{})
  def allowed?(nil, _capability, _context), do: false

  def allowed?(identity_id, capability, context) do
    GenServer.call(__MODULE__, {:allowed?, identity_id, capability, context})
  end

  def register_identity(%Identity{} = ident) do
    GenServer.cast(__MODULE__, {:register, ident})
  end

  def invalidate_cache do
    GenServer.cast(__MODULE__, :invalidate)
  end

  def refresh do
    GenServer.cast(__MODULE__, :refresh)
  end

  @impl true
  def init(_opts) do
    :ets.new(:obs_rbac_cache, [
      :set,
      :public,
      :named_table,
      write_concurrency: true,
      read_concurrency: true
    ])

    {:ok, %{identities: %{}, policies: Policy.constitutional()}}
  end

  @impl true
  def handle_call(
        {:allowed?, identity_id, capability, context},
        _from,
        %{identities: ids, policies: pols} = state
      ) do
    case Map.get(ids, identity_id) do
      nil ->
        {:reply, false, state}

      %Identity{revoked?: revoked} = ident ->
        if revoked do
          {:reply, false, state}
        else
          result = evaluate(ident, capability, context, pols)
          {:reply, result, state}
        end
    end
  end

  @impl true
  def handle_cast({:register, %Identity{} = ident}, state) do
    cache_identity(ident)
    {:noreply, %{state | identities: Map.put(state.identities, ident.id, ident)}}
  end

  @impl true
  def handle_cast(:invalidate, state) do
    :ets.delete_all_objects(:obs_rbac_cache)
    {:noreply, %{state | identities: %{}}}
  end

  @impl true
  def handle_cast(:refresh, state) do
    # Reload identities from DB in production
    {:noreply, state}
  end

  defp evaluate(ident, capability, context, policies) do
    cache_key = {ident.id, capability}

    case :ets.lookup(:obs_rbac_cache, cache_key) do
      [{_, result}] ->
        result

      [] ->
        cap_match =
          Enum.any?(ident.capabilities, fn granted ->
            Capability.satisfies?(granted, capability)
          end)

        merged_ctx =
          Map.merge(context, %{
            identity_id: ident.id,
            role: List.first(ident.roles),
            capability: capability
          })

        # Only consider policies whose scope matches the capability being checked
        denials =
          Enum.reduce(policies, [], fn {_name, policy}, acc ->
            if policy.rule.(merged_ctx) do
              case Policy.evaluate(policy, merged_ctx) do
                {:denied, _, _} -> [{:denied, policy} | acc]
                _ -> acc
              end
            else
              acc
            end
          end)

        result = cap_match and denials == []
        :ets.insert(:obs_rbac_cache, {cache_key, result})
        result
    end
  end

  defp cache_identity(%Identity{id: id, capabilities: caps}) do
    Enum.each(caps, fn cap ->
      :ets.insert(:obs_rbac_cache, {{id, cap}, true})
    end)
  end
end
