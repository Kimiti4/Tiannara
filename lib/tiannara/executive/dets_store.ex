defmodule Tiannara.Executive.DetsStore do
  @moduledoc """
  Low-level DETS storage operations for Executive Memory.

  Handles open, close, CRUD, and maintenance operations with
  corruption detection and repair.
  """

  @doc "Opens a DETS file, creating it if necessary."
  def open(file_path) do
    case :dets.open_file(String.to_atom(file_path), [{:file, String.to_charlist(file_path)}, {:auto_save, 0}]) do
      {:ok, ref} -> {:ok, ref}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Closes a DETS file."
  def close(ref) do
    :dets.close(ref)
    :ok
  end

  @doc "Inserts a key-value pair into DETS."
  def insert(ref, key, value) do
    :dets.insert(ref, {key, value})
  end

  @doc "Looks up a key in DETS."
  def lookup(ref, key) do
    case :dets.lookup(ref, key) do
      [{^key, value}] -> {:ok, value}
      [] -> :error
    end
  end

  @doc "Deletes a key from DETS."
  def delete(ref, key) do
    :dets.delete(ref, key)
    :ok
  end

  @doc "Returns all keys in DETS."
  def keys(ref) do
    :dets.foldl(fn {k, _}, acc -> [k | acc] end, [], ref)
  end

  @doc "Returns the number of records in DETS."
  def count(ref) do
    :dets.info(ref, :size) || 0
  end

  @doc "Syncs DETS to disk."
  def sync(ref) do
    :dets.sync(ref)
  end

  @doc "Folds over all records in DETS."
  def fold(ref, acc, fun) do
    :dets.foldl(fun, acc, ref)
  end

  @doc "Returns DETS info."
  def info(ref) do
    {:dets.info(ref), :dets.info(ref, :size)}
  end

  @doc "Repairs a DETS file."
  def repair(file_path) do
    :dets.repair_file(String.to_charlist(file_path))
  end

  @doc "Verifies DETS table integrity."
  def verify(ref) do
    :dets.info(ref, :size) != :undefined
  end

  @doc "Compacts a DETS file to reclaim space."
  def compact(ref, file_path) do
    original_size = :dets.info(ref, :file_size) || 0
    :ok = :dets.close(ref)
    :dets.open_file(ref, [{:file, String.to_charlist(file_path)}, {:auto_save, 0}])
    new_size = :dets.info(ref, :file_size) || 0
    {original_size, new_size}
  end
end
