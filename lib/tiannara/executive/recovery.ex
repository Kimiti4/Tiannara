defmodule Tiannara.Executive.Recovery do
  @moduledoc """
  Recovery operations for Executive Memory.

  Handles startup recovery, DETS repair, backup promotion,
  backup creation/verification, and full rebuild.

  Recovery ladder (B15/D-A12):

      detect corruption / open failure
          ↓
      attempt repair (explicit only — never raises)
          ↓
      repair unavailable or failed
          ↓
      select verified backup → restore → validate → reopen
          ↓
      no/invalid backup → explicit `{:error, reason}` (fail closed)

  "File opened" is never treated as "state successfully recovered":
  every success path runs table verification + deep integrity check.
  """

  require Logger

  alias Tiannara.Executive.{DetsStore, CorruptionDetector, Telemetry}

  @doc """
  Performs startup recovery: attempts open, falls back to repair, then backup.

  Returns `{:ok, ref}` only when the resulting table passes integrity checks.
  Returns `{:error, reason}` when recovery cannot establish integrity.
  """
  def startup_recovery(file_path) do
    case DetsStore.open(file_path) do
      {:ok, ref} ->
        if table_healthy?(ref) do
          Logger.info("[ExecutiveMemory] DETS opened successfully: #{file_path}")
          emit_recovery(file_path, :opened, :ok)
          {:ok, ref}
        else
          Logger.warning("[ExecutiveMemory] DETS table verification failed, attempting repair")
          _ = DetsStore.close(ref)
          attempt_repair(file_path)
        end

      {:error, reason} ->
        Logger.warning(
          "[ExecutiveMemory] DETS open failed (#{inspect(reason)}), attempting repair"
        )

        attempt_repair(file_path)
    end
  end

  @doc """
  Attempts to repair a DETS file, then opens and verifies the result.

  On OTP without `:dets.repair_file/1`, `DetsStore.repair/1` returns
  `{:error, :dets_repair_unavailable}` and this function routes to
  `attempt_backup_promotion/1` — the documented fallback stays reachable.
  """
  def attempt_repair(file_path) do
    Logger.warning("[ExecutiveMemory] Repairing DETS file: #{file_path}")

    case DetsStore.repair(file_path) do
      :ok ->
        Logger.info("[ExecutiveMemory] DETS repair succeeded")
        emit_recovery(file_path, :repair_attempted, :ok)

        case DetsStore.open(file_path) do
          {:ok, ref} ->
            if table_healthy?(ref) do
              emit_recovery(file_path, :repaired, :ok)
              {:ok, ref}
            else
              _ = DetsStore.close(ref)
              emit_recovery(file_path, :repair_verify_failed, :error)
              attempt_backup_promotion(file_path)
            end

          {:error, reason} ->
            emit_recovery(file_path, :repair_open_failed, {:error, reason})
            attempt_backup_promotion(file_path)
        end

      {:error, reason} ->
        Logger.error("[ExecutiveMemory] DETS repair failed: #{inspect(reason)}")
        emit_recovery(file_path, :repair_unavailable, {:error, reason})
        attempt_backup_promotion(file_path)

      other ->
        Logger.error(
          "[ExecutiveMemory] DETS repair returned unexpected result: #{inspect(other)}"
        )

        emit_recovery(file_path, :repair_unexpected, {:error, other})
        attempt_backup_promotion(file_path)
    end
  end

  @doc """
  Promotes a verified backup when the primary DETS is irrecoverable.

  Fail-closed outcomes:

    * missing backup → `{:error, :backup_unavailable}`
    * unreadable/corrupt backup → `{:error, :backup_corrupted}`
    * restore copy fails → `{:error, {:backup_copy_failed, reason}}`
    * restored table fails integrity → `{:error, :restored_state_invalid}`
    * valid backup restored and verified → `{:ok, ref}`
  """
  def attempt_backup_promotion(file_path) do
    backup = file_path <> ".backup"

    cond do
      not File.exists?(backup) ->
        Logger.error(
          "[ExecutiveMemory] No backup found — recovery cannot establish integrity: #{file_path}"
        )

        emit_recovery(file_path, :backup_unavailable, {:error, :backup_unavailable})
        {:error, :backup_unavailable}

      not verify_backup(file_path) ->
        Logger.error(
          "[ExecutiveMemory] Backup failed integrity check — refusing promotion: #{backup}"
        )

        emit_recovery(file_path, :backup_corrupted, {:error, :backup_corrupted})
        {:error, :backup_corrupted}

      true ->
        Logger.warning("[ExecutiveMemory] Promoting backup: #{backup}")

        case File.cp(backup, file_path) do
          :ok ->
            case DetsStore.open(file_path) do
              {:ok, ref} ->
                if table_healthy?(ref) do
                  Logger.info("[ExecutiveMemory] Backup restored and verified: #{file_path}")
                  emit_recovery(file_path, :backup_restored, :ok)
                  {:ok, ref}
                else
                  _ = DetsStore.close(ref)
                  Logger.error("[ExecutiveMemory] Restored state failed integrity — fail closed")

                  emit_recovery(
                    file_path,
                    :restored_state_invalid,
                    {:error, :restored_state_invalid}
                  )

                  {:error, :restored_state_invalid}
                end

              {:error, reason} ->
                Logger.error(
                  "[ExecutiveMemory] Restored backup failed to open: #{inspect(reason)}"
                )

                emit_recovery(file_path, :restore_open_failed, {:error, reason})
                {:error, {:restore_open_failed, reason}}
            end

          {:error, reason} ->
            Logger.error("[ExecutiveMemory] Backup copy failed: #{inspect(reason)}")
            emit_recovery(file_path, :backup_copy_failed, {:error, reason})
            {:error, {:backup_copy_failed, reason}}
        end
    end
  end

  @doc """
  Creates a backup of the DETS file only when the source passes integrity checks.

  Refuses to write a corrupt backup over a previously good one
  (recovery unavailable ≠ successful recovery; do not manufacture state).
  """
  def create_backup(file_path) do
    backup = file_path <> ".backup"

    cond do
      not File.exists?(file_path) ->
        Logger.warning("[ExecutiveMemory] No DETS file to backup")
        nil

      not healthy_file?(file_path) ->
        Logger.error("[ExecutiveMemory] Refusing to backup corrupt source: #{file_path}")
        emit_recovery(file_path, :backup_refused_corrupt_source, {:error, :source_corrupt})
        nil

      true ->
        case File.cp(file_path, backup) do
          :ok ->
            Logger.info("[ExecutiveMemory] Backup created: #{backup}")
            emit_recovery(file_path, :backup_created, :ok)
            backup

          {:error, reason} ->
            Logger.error("[ExecutiveMemory] Backup copy failed: #{inspect(reason)}")
            emit_recovery(file_path, :backup_create_failed, {:error, reason})
            nil
        end
    end
  end

  @doc """
  Verifies a backup file is a readable DETS table that passes deep integrity.

  Size > 0 alone is not sufficient evidence of recoverable state.
  """
  def verify_backup(file_path) do
    backup = file_path <> ".backup"
    healthy_file?(backup)
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
    emit_recovery(file_path, :rebuilt_fresh, :ok)
    DetsStore.open(file_path)
  end

  # Opens a path as DETS (unique table name) and runs full integrity checks.
  defp healthy_file?(path) do
    if File.exists?(path) and File.stat!(path).size > 0 do
      table = String.to_atom("#{path}.integrity_check")

      case :dets.open_file(table, [{:file, String.to_charlist(path)}, {:auto_save, 0}]) do
        {:ok, ref} ->
          ok = table_healthy?(ref)
          _ = :dets.close(ref)
          ok

        {:error, _} ->
          false
      end
    else
      false
    end
  end

  defp table_healthy?(ref) do
    CorruptionDetector.verify_table(ref) and CorruptionDetector.deep_check(ref).ok?
  end

  defp emit_recovery(file_path, step, outcome) do
    Telemetry.emit(:recovery, %{
      file: file_path,
      step: step,
      outcome: outcome,
      timestamp: DateTime.utc_now()
    })
  end
end
