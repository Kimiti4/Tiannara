defmodule TelemetryGateway.ReplayVerifier do
  @doc """
  Verifies replay chain integrity for events.
  Checks that previous_hash → current_hash chain is valid.
  """
  def verify(event, previous_hash \\ nil)

  def verify(event, nil) do
    lineage = event[:lineage] || event.lineage || %{}

    case lineage[:previous_hash] || lineage["previous_hash"] do
      nil -> {:ok, event}
      prev_hash -> verify(event, prev_hash)
    end
  end

  def verify(event, previous_hash) do
    lineage = event[:lineage] || event.lineage || %{}
    declared_prev = lineage[:previous_hash] || lineage["previous_hash"]

    cond do
      is_nil(declared_prev) ->
        {:ok, event}

      declared_prev != previous_hash ->
        {:error, :replay_hash_mismatch, %{expected: previous_hash, got: declared_prev}}

      true ->
        current = compute_hash(event)
        {:ok, Map.put(event, :replay_hash, current)}
    end
  end

  def compute_hash(event) do
    payload =
      :erlang.term_to_binary(%{
        id: event.id,
        domain: event.domain,
        timestamp: event.timestamp,
        payload: event.payload,
        previous_hash:
          get_in(event, [:lineage, :previous_hash]) || get_in(event, ["lineage", "previous_hash"])
      })

    :crypto.hash(:sha256, payload) |> Base.encode16(case: :lower)
  end
end
