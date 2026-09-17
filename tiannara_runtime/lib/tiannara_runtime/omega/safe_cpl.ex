defmodule TiannaraRuntime.Omega.SafeCPL do
  @moduledoc """
  Small fault-isolation wrapper around the Constitutional Persistence Layer.

  Omega services must keep running even when persistence is temporarily absent,
  slow, or restarting. These helpers convert CPL failures into tagged errors
  instead of letting callers crash.
  """

  alias TiannaraRuntime.OS.Persistence.ConstitutionalPersistenceLayer, as: CPL

  @timeout 2_000

  @spec record_event(atom(), map()) :: {:ok, map()} | {:error, term()}
  def record_event(type, data) when is_atom(type) and is_map(data) do
    call_if_alive(fn -> CPL.record_event(type, data) end)
  end

  @spec create_checkpoint(atom(), map()) :: {:ok, map()} | {:error, term()}
  def create_checkpoint(layer, data) when is_atom(layer) and is_map(data) do
    call_if_alive(fn -> CPL.create_checkpoint(layer, data) end)
  end

  @spec recovery_stats() :: {:ok, map()} | {:error, term()}
  def recovery_stats do
    call_if_alive(fn -> {:ok, CPL.get_recovery_stats()} end)
  end

  defp call_if_alive(fun) do
    case Process.whereis(CPL) do
      nil ->
        {:error, :cpl_unavailable}

      _pid ->
        task = Task.async(fun)

        case Task.yield(task, @timeout) || Task.shutdown(task, :brutal_kill) do
          {:ok, result} -> result
          nil -> {:error, :cpl_timeout}
          {:exit, reason} -> {:error, reason}
        end
    end
  rescue
    error -> {:error, error}
  catch
    kind, reason -> {:error, {kind, reason}}
  end
end
