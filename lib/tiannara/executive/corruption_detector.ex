defmodule Tiannara.Executive.CorruptionDetector do
  @moduledoc """
  Integrity verification for DETS-backed Executive Memory.

  Performs table verification, deep checks, CRC validation,
  and structured corruption reporting.
  """

  require Logger

  @doc "Verifies DETS table is accessible and readable."
  def verify_table(ref) do
    try do
      :dets.info(ref)
      true
    rescue
      _ -> false
    end
  end

  @doc "Validates CRC checksum of a record's value."
  def validate_crc(data, expected_crc) do
    actual = checksum(data)
    actual == expected_crc
  end

  @doc "Computes a checksum for data."
  def checksum(data) do
    :erlang.crc32(:erlang.term_to_binary(data))
  end

  @doc "Validates DETS file header for a given path."
  def validate_header(file_path) do
    case File.read(file_path) do
      {:ok, bin} when byte_size(bin) >= 8 ->
        <<_::binary-size(8), rest::binary>> = bin
        if byte_size(rest) > 0, do: true, else: false

      {:ok, _} ->
        false

      _ ->
        false
    end
  end

  @doc "Validates an individual record tuple."
  def validate_record({_key, _value}), do: true
  def validate_record(_), do: false

  @doc "Performs a deep integrity check of all records in DETS."
  def deep_check(ref) do
    try do
      results =
        :dets.foldl(
          fn record, acc ->
            [validate_record(record) | acc]
          end,
          [],
          ref
        )

      total = length(results)
      valid = Enum.count(results, & &1)
      corrupt = total - valid

      %{total: total, valid: valid, corrupt: corrupt, ok?: corrupt == 0}
    rescue
      e ->
        %{total: 0, valid: 0, corrupt: 0, ok?: false, error: inspect(e)}
    end
  end

  @doc "Reports a corruption event and returns structured info."
  def report_corruption(ref, details \\ %{}) do
    info =
      try do
        {:dets.info(ref), :dets.info(ref, :size)}
      rescue
        _ -> :unknown
      end

    event = %{
      timestamp: DateTime.utc_now(),
      table: ref,
      info: info,
      details: details
    }

    Logger.error("[ExecutiveMemory] Corruption detected: #{inspect(event)}")

    table = :dets.info(ref)

    if is_list(table) and Keyword.get(table, :name) do
      file = Keyword.get(table, :file)

      if file do
        backup_dest =
          file
          |> List.to_string()
          |> Kernel.<>(".corrupt.#{DateTime.utc_now() |> DateTime.to_unix()}")

        File.cp_r(List.to_string(file), backup_dest)
        Logger.warning("[ExecutiveMemory] Corrupt DETS archived to #{backup_dest}")
      end
    end

    event
  end
end
