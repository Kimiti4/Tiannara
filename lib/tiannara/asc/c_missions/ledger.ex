defmodule Tiannara.ASC.CMissions.Ledger do
  @moduledoc """
  Append-only evidence ledger for ASC autonomous-engineering missions.

  Entries are serialized with `inspect/2` (no dependencies) and appended;
  nothing is ever overwritten. The ledger is the durable record a mission
  is judged against: every phase, every patch, every gate result, and the
  final verdict.
  """

  @mission_dir "priv/asc/missions/ASC-AE-001"

  def init(dir \\ @mission_dir) do
    File.mkdir_p!(dir)
    path = Path.join(dir, "evidence.ledger")
    unless File.exists?(path), do: File.write!(path, "")
    %{path: path, seq: 0, dir: dir}
  end

  def record(ledger, phase, data) do
    ledger = %{ledger | seq: ledger.seq + 1}

    entry = %{
      seq: ledger.seq,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      phase: phase,
      data: data
    }

    line = inspect(entry, limit: :infinity, printable_limit: :infinity) <> "\n"
    File.write!(ledger.path, line, [:append])

    ledger
  end

  def entries(ledger) do
    ledger.path
    |> File.stream!([], :line)
    |> Enum.map(&Code.eval_string/1)
    |> Enum.map(&elem(&1, 0))
  end
end