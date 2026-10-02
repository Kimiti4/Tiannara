defmodule Tiannara.Sentinel.MathematicalEvidenceArchive do
  @moduledoc """
  Append-only, lineage-aware archive for mathematical and scientific evidence.

  This is deliberately separate from theorem truth. Every artifact retains its
  assumptions, provenance, execution mode and epistemic status. Hashes bind
  parent lineage so later replay/audit can detect substitution.
  """

  @spec append(map(), [map()]) :: {:ok, map()} | {:error, term()}
  def append(record, parents) when is_map(record) and is_list(parents) do
    with :ok <- validate_record(record),
         :ok <- validate_parents(parents) do
      parent_hashes = Enum.map(parents, &Map.get(&1, :hash))
      canonical = Map.drop(record, [:hash])
      hash = :crypto.hash(:sha256, :erlang.term_to_binary({parent_hashes, canonical}))
             |> Base.encode16(case: :lower)

      {:ok, Map.merge(record, %{
        hash: hash,
        parent_hashes: parent_hashes,
        archived_at: DateTime.utc_now(),
        archive_status: :append_only
      })}
    end
  end

  def append(_, _), do: {:error, :invalid_evidence_archive_record}

  defp validate_record(record) do
    required = [:id, :kind, :status, :artifact, :provenance]
    case Enum.find(required, &(not Map.has_key?(record, &1))) do
      nil -> :ok
      key -> {:error, {:missing_field, key}}
    end
  end

  defp validate_parents(parents) do
    if Enum.all?(parents, &(is_map(&1) and is_binary(Map.get(&1, :hash)))),
      do: :ok,
      else: {:error, :invalid_parent_evidence}
  end
end
