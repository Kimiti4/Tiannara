defmodule Tiannara.Omega.ConsequentialActionGate do
  @moduledoc """
  Mandatory human-authorization gate for consequential runtime actions.

  This gate is intentionally narrower than certification: a certificate proves
  an evidence predicate; it never grants authority. A consequential action
  requires an AuthorizationGrant bound to the exact action identifier and an
  authenticated human identity.

  The gate is fail-closed and can optionally consume a durable action registry
  entry so the same authorization cannot be replayed.
  """

  alias Tiannara.Omega.HumanDelivery.{Authorization, AuthenticatedHumanIdentity}

  @lock_table :consequential_action_gate_locks

  @spec authorize(term(), Authorization.t() | term(), AuthenticatedHumanIdentity.t() | term()) ::
          {:ok, map()} | {:error, term()}
  def authorize(action_id, grant, identity) do
    with :ok <- validate_action_id(action_id),
         :ok <- validate_grant(grant, action_id),
         :ok <- validate_identity(identity, grant) do
      {:ok,
       %{
         action_id: action_id,
         authorization_id: grant.authorization_id,
         human_id: grant.human_id,
         authorized_at: System.system_time(:second)
       }}
    end
  end

  @spec consume(term(), Authorization.t() | term(), AuthenticatedHumanIdentity.t() | term(), binary()) ::
          {:ok, map()} | {:error, term()}
  def consume(action_id, grant, identity, registry_path) when is_binary(registry_path) do
    table = ensure_registry_table(registry_path)
    key = {:action, grant_key(grant)}

    with_lock(key, fn ->
      with {:ok, receipt} <- authorize(action_id, grant, identity),
           :ok <- reject_replay(table, key),
           :ok <- persist_receipt(table, key, receipt, registry_path) do
        {:ok, receipt}
      end
    end)
  end

  def consume(_action_id, _grant, _identity, _registry_path),
    do: {:error, :action_registry_path_required}

  defp validate_action_id(nil), do: {:error, :action_id_required}
  defp validate_action_id(""), do: {:error, :action_id_required}
  defp validate_action_id(_), do: :ok

  defp validate_grant(nil, _), do: {:error, :authorization_grant_required}

  defp validate_grant(%Authorization{status: :granted} = grant, action_id) do
    cond do
      Authorization.expired?(grant) ->
        {:error, :grant_expired}

      not Authorization.valid_for?(grant, action_id) ->
        {:error, :grant_does_not_match_action}

      true ->
        :ok
    end
  end

  defp validate_grant(%Authorization{status: status}, _),
    do: {:error, {:authorization_not_granted, status}}

  defp validate_grant(_, _), do: {:error, :authorization_grant_required}

  defp validate_identity(
         %AuthenticatedHumanIdentity{} = identity,
         %Authorization{} = grant
       ) do
    cond do
      not AuthenticatedHumanIdentity.authenticated?(identity) ->
        {:error, :identity_not_authenticated}

      identity.human_id != grant.human_id ->
        {:error, :identity_does_not_match_grant}

      true ->
        :ok
    end
  end

  defp validate_identity(_, _), do: {:error, :identity_not_authenticated}

  defp grant_key(%Authorization{authorization_id: id}) when not is_nil(id), do: id
  defp grant_key(_), do: {:invalid, System.unique_integer([:monotonic])}

  defp ensure_registry_table(path) do
    table = table_name(path)

    case :ets.whereis(table) do
      :undefined ->
        try do
          :ets.new(table, [:named_table, :public, :set])
        rescue
          ArgumentError -> table
        end

      _ ->
        table
    end
  end

  defp table_name(path) do
    digest = :crypto.hash(:sha256, path) |> Base.encode16(case: :lower)
    String.to_atom("tiannara_action_gate_" <> binary_part(digest, 0, 16))
  end

  defp reject_replay(table, key) do
    if :ets.member(table, key), do: {:error, :authorization_already_consumed}, else: :ok
  end

  defp persist_receipt(table, key, receipt, path) do
    if :ets.insert_new(table, {key, receipt}) do
      File.mkdir_p!(Path.dirname(path))

      line =
        Jason.encode!(%{
          "action_id" => receipt.action_id,
          "authorization_id" => receipt.authorization_id,
          "human_id" => receipt.human_id,
          "authorized_at" => receipt.authorized_at
        })

      case File.write(path, line <> "\n", [:append]) do
        :ok ->
          :ok

        {:error, reason} ->
          :ets.delete(table, key)
          {:error, {:action_registry_write_failed, reason}}
      end
    else
      {:error, :authorization_already_consumed}
    end
  end

  defp with_lock(key, fun) do
    table = ensure_lock_table()

    case :ets.insert_new(table, {key, self()}) do
      true ->
        try do
          fun.()
        after
          :ets.delete(table, key)
        end

      false ->
        case :ets.lookup(table, key) do
          [{^key, pid}] when is_pid(pid) and not Process.alive?(pid) ->
            :ets.delete(table, key)
            with_lock(key, fun)

          _ ->
            Process.sleep(1)
            with_lock(key, fun)
        end
    end
  end

  defp ensure_lock_table do
    case :ets.whereis(@lock_table) do
      :undefined ->
        try do
          :ets.new(@lock_table, [:named_table, :public, :set])
        rescue
          ArgumentError -> @lock_table
        end

      _ ->
        @lock_table
    end
  end
end
