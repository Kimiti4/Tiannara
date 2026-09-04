defmodule Tiannara.CEL.Services.ResilientDETS do
  require Logger

  def open(table, opts) do
    file = Keyword.fetch!(opts, :file)
    file_str = to_string(file)
    :ok = file |> Path.dirname() |> File.mkdir_p()

    case :dets.open_file(table, opts) do
      {:ok, ^table} ->
        {:ok, table}

      {:error, {:needs_repair, _}} ->
        Logger.warning("ResilientDETS: #{file_str} needs repair — archiving and recovering")
        archive(file_str)
        repair_or_fresh(table, opts, file_str)

      {:error, reason} ->
        Logger.error("ResilientDETS: failed to open #{file_str}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp repair_or_fresh(table, opts, file_str) do
    case :dets.open_file(table, Keyword.put(opts, :repair, true)) do
      {:ok, ^table} ->
        Logger.info("ResilientDETS: repaired #{file_str}")
        {:ok, table}

      {:error, reason} ->
        Logger.error("ResilientDETS: repair failed for #{file_str} (#{inspect(reason)}) — opening fresh")
        quarantine(file_str)
        case :dets.open_file(table, Keyword.delete(opts, :repair)) do
          {:ok, ^table} -> {:ok, table}
          {:error, reason2} -> {:error, reason2}
        end
    end
  end

  defp archive(file_str) do
    stamp = DateTime.utc_now() |> Calendar.strftime("%Y%m%dT%H%M%S")
    dest = "#{file_str}.corrupt.#{stamp}"
    case File.cp(file_str, dest) do
      :ok -> Logger.info("ResilientDETS: archived corrupt file to #{dest}")
      {:error, e} -> Logger.warning("ResilientDETS: could not archive #{file_str}: #{inspect(e)}")
    end
  end

  defp quarantine(file_str) do
    stamp = DateTime.utc_now() |> Calendar.strftime("%Y%m%dT%H%M%S")
    dest = "#{file_str}.quarantine.#{stamp}"
    _ = File.rename(file_str, dest)
  end
end
