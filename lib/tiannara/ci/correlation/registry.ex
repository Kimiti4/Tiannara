defmodule Tiannara.CI.Correlation.Record do
  @moduledoc "A single correlation record mapping correlation_id ↔ proposal ↔ lineage."

  @enforce_keys [:correlation_id, :proposal_id]
  defstruct [:correlation_id, :proposal_id, :lineage_id, :status,
             :dispatched_at, :recorded_at, :result]

  @type t :: %__MODULE__{}
end

defmodule Tiannara.CI.Correlation.Registry do
  @moduledoc """
  A durable correlation registry. Maps correlation_id ↔ proposal_id ↔
  lineage_id and persists to an append-only file so mappings SURVIVE RESTART.

  Records are appended (never overwritten) for auditability; lookups return the
  most recent record for a correlation_id. This makes the correlation durable
  and auditable, satisfying "Maintain audit trails" and "Support
  reproducibility."

  Constitutional basis: "Maintain audit trails", "Support reproducibility",
  "Preserve previous stable states", Security by design.
  """

  alias Tiannara.CI.Correlation.Record

  @doc "Register a new correlation (status :dispatched)."
  def register(correlation_id, proposal_id, lineage_id, path) do
    record = %Record{
      correlation_id: correlation_id,
      proposal_id: proposal_id,
      lineage_id: lineage_id,
      status: :dispatched,
      dispatched_at: System.system_time(:millisecond),
      recorded_at: System.system_time(:millisecond)
    }

    persist(record, path)
  end

  @doc "Mark a correlation as completed with its result."
  def complete(correlation_id, proposal_id, result, path) do
    record = %Record{
      correlation_id: correlation_id,
      proposal_id: proposal_id,
      status: :completed,
      dispatched_at: System.system_time(:millisecond),
      recorded_at: System.system_time(:millisecond),
      result: result
    }

    persist(record, path)
  end

  @doc """
  Look up the most recent record for a correlation_id. Returns
  `{:ok, record}` or `:not_found`.
  """
  def lookup(correlation_id, path) do
    case load_all(path) do
      {:ok, records} ->
        records
        |> Enum.filter(&(&1.correlation_id == correlation_id))
        |> Enum.sort_by(& &1.recorded_at, :desc)
        |> List.first()
        |> case do
          nil -> :not_found
          record -> {:ok, record}
        end

      {:error, _} = e ->
        e
    end
  end

  @doc "Load all correlation records from durable storage."
  def load_all(path) do
    case File.read(path) do
      {:ok, content} ->
        {:ok, decode_records(content)}

      {:error, :enoent} ->
        {:ok, []}

      {:error, _} = e ->
        e
    end
  end

  @doc "Return all distinct proposal_ids currently registered."
  def proposal_ids(path) do
    case load_all(path) do
      {:ok, records} -> {:ok, records |> Enum.map(& &1.proposal_id) |> Enum.uniq()}
      e -> e
    end
  end

  # Length-prefixed frames: `term_to_binary` may legitimately contain newline
  # bytes (atom-length bytes etc.), so records are framed by their byte size
  # rather than newline-delimited.
  defp decode_records(content), do: decode_records(content, [])

  defp decode_records(<<>>, acc), do: Enum.reverse(acc)

  defp decode_records(<<size::32, rest::binary>>, acc) do
    <<serialized::binary-size(size), tail::binary>> = rest
    decode_records(tail, [:erlang.binary_to_term(serialized) | acc])
  end

  defp persist(record, path) do
    File.mkdir_p!(Path.dirname(path))
    serialized = :erlang.term_to_binary(record)
    File.write(path, <<byte_size(serialized)::32, serialized::binary>>, [:append])
  end
end