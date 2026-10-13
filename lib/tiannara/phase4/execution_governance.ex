defmodule Tiannara.Phase4.ExecutionGovernance do
  @moduledoc """
  Shared authorization→effect admission for the S03/S04 real-execution sinks
  (Step-5 §8 rows "S03 real exec" and "S04 pilot", implemented together because
  the rows share one delta).

  Delivers in one place the four deltas those rows require:
    * M3  pre-execution binding to a canonical `EffectIdentity` descriptor
          (sink-computed; a bound grant may never point at another effect);
    * M4  single-use grant consumption (`MintRegistry.consume` CAS) BEFORE the
          consequential run;
    * M6  sink-local executed-effect dedup keyed by effect_id (one ETS claim
          per canonical effect for the lifetime of the node — session-scoped
          like UWM's in-memory executed set);
    * M8  hash-chained `Council.AuditLog` edge, fail-closed on append.

  Gate order (clone of the S01 governed-sink contract, human-grant flavoured):
      struct present -> status :granted -> unexpired -> registry :granted ->
      descriptor identity -> one-shot bind-or-verify (struct AND registry) ->
      executed-effect claim -> consume CAS.
  Every refusal is a named atom. A refused consume releases the effect claim
  so a fresh grant may retry an effect that never happened; a completed
  execution keeps the claim for the node lifetime.

  Constitution: "Capability must never outpace verification".
  """

  alias Tiannara.Council.AuditLog
  alias Tiannara.Omega.{EffectIdentity, MintRegistry}
  alias Tiannara.Omega.HumanDelivery.Authorization

  @executed_table :phase4_executed_effects

  @type admission :: %{grant: Authorization.t(), effect_id: String.t()}

  @doc """
  Authorize one execution: verify the grant, bind or verify it against the
  canonical `descriptor`, claim the effect, and consume the grant. Returns the
  (possibly bound) grant plus the canonical effect_id. The caller MUST call
  `release/1` if the execution then fails to occur.
  """
  @spec begin(Authorization.t() | term(), map()) :: {:ok, admission()} | {:error, term()}
  def begin(grant, descriptor)

  def begin(%Authorization{} = grant, descriptor) when is_map(descriptor) do
    with :ok <- check_granted(grant),
         :ok <- check_unexpired(grant),
         :ok <- check_registered(grant),
         {:ok, effect_id} <- canonical_effect_id(descriptor),
         {:ok, bound} <- ensure_bound(grant, descriptor, effect_id),
         :ok <- check_registry_binding(bound, effect_id),
         :ok <- claim_effect(effect_id),
         :ok <- consume_once(bound, effect_id) do
      {:ok, %{grant: bound, effect_id: effect_id}}
    end
  end

  def begin(%Authorization{}, _descriptor), do: {:error, :authorization_grant_required}
  def begin(_, _), do: {:error, :authorization_grant_required}

  @doc "Release an executed-effect claim after a failed execution (M6)."
  @spec release(String.t()) :: :ok
  def release(effect_id) when is_binary(effect_id) do
    case :ets.whereis(@executed_table) do
      :undefined -> :ok
      tid -> :ets.delete(tid, effect_id)
    end

    :ok
  end

  @doc "Test/observability seam: has this canonical effect already run here?"
  @spec executed?(String.t()) :: boolean()
  def executed?(effect_id) when is_binary(effect_id) do
    case :ets.whereis(@executed_table) do
      :undefined -> false
      tid -> :ets.member(tid, effect_id)
    end
  end

  @doc """
  Append a fail-closed audit edge (M8). Payload must already carry the
  effect/authorization/execution identities; `execution_recorded` is added so
  an audit failure never hides that the effect did occur.
  """
  @spec record_audit(atom(), term(), map()) :: :ok | {:error, term()}
  def record_audit(action, actor, payload) when is_atom(action) and is_map(payload) do
    detail = Map.put(payload, :execution_recorded, true)

    try do
      case AuditLog.append(action, actor, detail) do
        {:ok, %{} = _entry} -> :ok
        {:error, reason} -> {:error, {:audit_not_recorded, reason, detail}}
        other -> {:error, {:audit_not_recorded, {:unexpected_audit_result, other}, detail}}
      end
    catch
      kind, reason -> {:error, {:audit_not_recorded, {kind, reason}, detail}}
    end
  end

  # ------------------------------------------------------------ gate steps --

  defp check_granted(%Authorization{status: :granted}), do: :ok
  defp check_granted(%Authorization{}), do: {:error, :authorization_grant_denied}

  defp check_unexpired(grant) do
    if Authorization.expired?(grant) do
      {:error, :grant_expired}
    else
      :ok
    end
  end

  defp check_registered(grant) do
    case MintRegistry.status(grant.authorization_id) do
      :granted -> :ok
      :consumed -> {:error, :already_consumed}
      :not_registered -> {:error, :authorization_not_registered}
      :registry_unavailable -> {:error, :authorization_registry_unavailable}
    end
  end

  defp canonical_effect_id(descriptor) do
    case EffectIdentity.effect_id(descriptor) do
      {:ok, effect_id} -> {:ok, effect_id}
      {:error, reason} -> {:error, {:invalid_effect_descriptor, reason}}
    end
  end

  defp ensure_bound(%Authorization{effect_id: nil} = grant, descriptor, effect_id) do
    case Authorization.bind_effect(grant, descriptor) do
      {:ok, bound} ->
        case MintRegistry.record_bind(bound.authorization_id, effect_id) do
          :ok -> {:ok, bound}
          {:error, {:already_bound, ^effect_id}} -> {:ok, bound}
          {:error, {:already_bound, _other}} -> {:error, :registry_binding_mismatch}
          {:error, :not_registered} -> {:error, :authorization_not_registered}
          {:error, :already_consumed} -> {:error, :already_consumed}
          {:error, reason} -> {:error, {:authorization_bind_failed, reason}}
          :registry_unavailable -> {:error, :authorization_registry_unavailable}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp ensure_bound(%Authorization{effect_id: bound_id} = grant, _descriptor, effect_id) do
    if bound_id == effect_id do
      {:ok, grant}
    else
      {:error, :effect_id_mismatch}
    end
  end

  defp check_registry_binding(%Authorization{} = grant, effect_id) do
    case MintRegistry.binding(grant.authorization_id) do
      {:ok, ^effect_id} -> :ok
      {:ok, _other} -> {:error, :registry_binding_mismatch}
      :not_bound -> {:error, :registry_binding_mismatch}
      :not_registered -> {:error, :authorization_not_registered}
      :registry_unavailable -> {:error, :authorization_registry_unavailable}
    end
  end

  defp claim_effect(effect_id) do
    table = ensure_executed_table()

    case :ets.insert_new(table, {effect_id, System.system_time(:second)}) do
      true -> :ok
      false -> {:error, :effect_already_executed}
    end
  rescue
    ArgumentError ->
      table = ensure_executed_table()

      case :ets.insert_new(table, {effect_id, System.system_time(:second)}) do
        true -> :ok
        false -> {:error, :effect_already_executed}
      end
  end

  defp ensure_executed_table do
    case :ets.whereis(@executed_table) do
      :undefined ->
        keeper =
          spawn(fn ->
            receive do
              :stop -> :ok
            end
          end)

        try do
          :ets.new(@executed_table, [:named_table, :public, :set, {:heir, keeper, nil}])
        rescue
          ArgumentError ->
            Process.sleep(1)
            ensure_executed_table()
        end

      tid ->
        tid
    end
  end

  defp consume_once(grant, effect_id) do
    result =
      case MintRegistry.consume(grant.authorization_id, effect_id) do
        :ok ->
          :ok

        {:error, :already_consumed} ->
          {:error, :already_consumed}

        {:error, :not_registered} ->
          {:error, :authorization_not_registered}

        {:error, :registry_binding_mismatch} ->
          {:error, :registry_binding_mismatch}

        :registry_unavailable ->
          {:error, :authorization_registry_unavailable}

        {:error, reason} ->
          {:error, {:authorization_consume_failed, reason}}
      end

    case result do
      :ok -> :ok
      {:error, _} -> release(effect_id); result
    end
  end
end
