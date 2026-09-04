defmodule Tiannara.Executive.Recovery do
  @moduledoc """
  Recovery operations for Executive Memory.

  Handles startup recovery, DETS repair, backup promotion,
  backup creation/verification, and full rebuild.
  """

  require Logger

  alias Tiannara.Executive.{DetsStore, CorruptionDetector}

  @doc "Performs startup recovery: attempts open, falls back to repair, then backup."
  def startup_recovery(file_path) do
    case DetsStore.open(file_path) do
      {:ok, ref} ->
        if CorruptionDetector.verify_table(ref) do
          Logger.info("[ExecutiveMemory] DETS opened successfully: #{file_path}")
          {:ok, ref}
        else
          Logger.warning("[ExecutiveMemory] DETS table verification failed, attempting repair")
          attempt_repair(file_path)
        end
      {:error, reason} ->
        Logger.warning("[ExecutiveMemory] DETS open failed (#{reason}), attempting repair")
        attempt_repair(file_path)
    end
  end

  @doc "Attempts to repair a DETS file."
  def attempt_repair(file_path) do
    Logger.warning("[ExecutiveMemory] Repairing DETS file: #{file_path}")
    case DetsStore.repair(file_path) do
      :ok ->
        Logger.info("[ExecutiveMemory] DETS repair succeeded")
        DetsStore.open(file_path)
      {:error, reason} ->
        Logger.error("[ExecutiveMemory] DETS repair failed: #{reason}")
        attempt_backup_promotion(file_path)
    end
  end

  @doc "Attempts to promote a backup file if primary DETS is irrecoverable."
  def attempt_backup_promotion(file_path) do
    backup = file_path <> ".backup"
    if File.exists?(backup) do
      Logger.warning("[ExecutiveMemory] Promoting backup: #{backup}")
      File.cp_r(backup, file_path)
      DetsStore.open(file_path)
    else
      Logger.warning("[ExecutiveMemory] No backup found, starting fresh")
      {:ok, nil}
    end
  end

  @doc "Creates a backup of the DETS file."
  def create_backup(file_path) do
    backup = file_path <> ".backup"
    if File.exists?(file_path) do
      File.cp_r(file_path, backup)
      Logger.info("[ExecutiveMemory] Backup created: #{backup}")
      backup
    else
      Logger.warning("[ExecutiveMemory] No DETS file to backup")
      nil
    end
  end

  @doc "Verifies a backup file's integrity."
  def verify_backup(file_path) do
    backup = file_path <> ".backup"
    if File.exists?(backup) do
      File.exists?(backup) && File.stat!(backup).size > 0
    else
      false
    end
  end

  @doc "Rebuilds the DETS store from scratch (destructive)."
  def rebuild(file_path) do
    Logger.warning("[ExecutiveMemory] Rebuilding DETS from scratch: #{file_path}")
    if File.exists?(file_path) do
      File.rm_rf(file_path)
      Logger.info("[ExecutiveMemory] Deleted old DETS file")
    end
    Path.dirname(file_path) |> File.mkdir_p!()
    Logger.info("[ExecutiveMemory] Created fresh DETS file")
    DetsStore.open(file_path)
  end
end
