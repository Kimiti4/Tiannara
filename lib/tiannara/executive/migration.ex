defmodule Tiannara.Executive.Migration do
  @moduledoc """
  Schema version management and migrations for Executive Memory.

  Stores the current schema version in DETS and provides
  idempotent migration paths between versions.
  """

  require Logger

  @current_version 2

  @doc "Returns the current schema version."
  def current_version, do: @current_version

  @doc "Runs all pending migrations to bring the store up to current version."
  def migrate(ref) do
    version = get_version(ref)
    Logger.info("[ExecutiveMemory] Current schema version: #{version}, target: #{@current_version}")

    cond do
      version < 1 -> migrate_v0_to_v1(ref)
      version < 2 -> migrate_v1_to_v2(ref)
      true -> :ok
    end

    set_version(ref, @current_version)
    Logger.info("[ExecutiveMemory] Migration complete to version #{@current_version}")
    :ok
  end

  @doc "Gets the stored schema version from DETS."
  def get_version(ref) do
    case :dets.lookup(ref, :__schema_version__) do
      [{:__schema_version__, v}] -> v
      [] -> 0
    end
  end

  @doc "Sets the schema version in DETS."
  def set_version(ref, version) do
    :dets.insert(ref, {:__schema_version__, version})
  end

  defp migrate_v0_to_v1(ref) do
    Logger.info("[ExecutiveMemory] Running migration v0→v1: adding schema version")
    :dets.insert(ref, {:__schema_version__, 1})
    Logger.info("[ExecutiveMemory] Migration v0→v1 complete")
  end

  defp migrate_v1_to_v2(ref) do
    Logger.info("[ExecutiveMemory] Running migration v1→v2: adding memory class metadata")
    :dets.foldl(fn {key, _value}, _acc ->
      unless key == :__schema_version__ do
        meta_key = {:__class__, key}
        case :dets.lookup(ref, meta_key) do
          [] -> :dets.insert(ref, {meta_key, :operational})
          _ -> :ok
        end
      end
    end, [], ref)
    Logger.info("[ExecutiveMemory] Migration v1→v2 complete")
  end
end
