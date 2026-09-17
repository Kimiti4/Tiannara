defmodule TiannaraOS.Provenance.Producer do
  @moduledoc """
  Stage 3 runtime instrumentation surface (Council-authorized).

  Exactly ONE code path for opening, completing, and failing an execution at
  the real runtime boundaries (Phase-4 `RealExecution`, OPC
  `ExecutionRuntime`). The adapter composes the identity authority (mint) with
  the runtime contract (lifecycle), so producer-local authority over
  `execution_id` is eliminated and every lifecycle reaches a unique terminal
  state.

  Semantics:
    * begin/3      -> authority-MINTED id + opened lifecycle window (a caller
                     may fold a previous lifecycle in to keep one window, and
                     may declare a distributed parent via
                     %{"parent_execution_id" => parent_id})
    * complete/4   -> terminal "completed"
    * fail/4       -> terminal "failed"
    * partial/4    -> terminal "partial"
    * timeout/4    -> terminal "timed_out"   (Stage 4 failure vocabulary)
    * cancel/4     -> terminal "cancelled"
    * abort/4      -> terminal "aborted"
    * unknown/4    -> terminal "unknown"     (NOT CERTIFIABLE, never upgraded)

  Violations are never silently accepted: a terminal on an id/attempt that is
  unknown, orphaned, closed, or attributed to another producer returns
  `{:error, reason, culprit}` exactly as the runtime contract specifies.
  """

  alias TiannaraOS.Provenance.{IdentityAuthority, RuntimeContract}

  @event_keys ["event_type", "execution_id", "producer", "attempt"]

  @doc "Authority-minted id + opened runtime-contract lifecycle for a producer."
  def begin(producer, fields \\ %{}, lifecycle \\ %{})
      when is_binary(producer) and is_map(fields) and is_map(lifecycle) do
    minted = IdentityAuthority.mint(producer)

    with {execution_id, _record} when is_binary(execution_id) <- minted,
         {:ok, normalized, lifecycle2} <- RuntimeContract.accept(start_event(producer, execution_id, fields), lifecycle) do
      {:ok, execution_id, normalized, lifecycle2}
    end
  end

  @doc "Close an opened execution as `completed` (terminal, unique)."
  def complete(producer, execution_id, lifecycle, fields \\ %{})
      when is_binary(producer) and is_binary(execution_id) and is_map(lifecycle) and is_map(fields) do
    terminal(producer, execution_id, lifecycle, "completed", fields)
  end

  @doc "Close an opened execution as `failed` (terminal, unique)."
  def fail(producer, execution_id, lifecycle, fields \\ %{})
      when is_binary(producer) and is_binary(execution_id) and is_map(lifecycle) and is_map(fields) do
    terminal(producer, execution_id, lifecycle, "failed", fields)
  end

  @doc "Close an opened execution as `partial` (terminal, unique)."
  def partial(producer, execution_id, lifecycle, fields \\ %{})
      when is_binary(producer) and is_binary(execution_id) and is_map(lifecycle) and is_map(fields) do
    terminal(producer, execution_id, lifecycle, "partial", fields)
  end

  @doc "Close an opened execution as `timed_out` (Stage 4 failure vocabulary, terminal, unique)."
  def timeout(producer, execution_id, lifecycle, fields \\ %{})
      when is_binary(producer) and is_binary(execution_id) and is_map(lifecycle) and is_map(fields) do
    terminal(producer, execution_id, lifecycle, "timed_out", fields)
  end

  @doc "Close an opened execution as `cancelled` (Stage 4 failure vocabulary, terminal, unique)."
  def cancel(producer, execution_id, lifecycle, fields \\ %{})
      when is_binary(producer) and is_binary(execution_id) and is_map(lifecycle) and is_map(fields) do
    terminal(producer, execution_id, lifecycle, "cancelled", fields)
  end

  @doc "Close an opened execution as `aborted` (Stage 4 failure vocabulary, terminal, unique)."
  def abort(producer, execution_id, lifecycle, fields \\ %{})
      when is_binary(producer) and is_binary(execution_id) and is_map(lifecycle) and is_map(fields) do
    terminal(producer, execution_id, lifecycle, "aborted", fields)
  end

  @doc """
  Close an opened execution as `unknown` (Stage 4 failure vocabulary). An
  UNKNOWN outcome closes the lifecycle once and is NOT CERTIFIABLE; it is never
  silently upgraded to `completed`.
  """
  def unknown(producer, execution_id, lifecycle, fields \\ %{})
      when is_binary(producer) and is_binary(execution_id) and is_map(lifecycle) and is_map(fields) do
    terminal(producer, execution_id, lifecycle, "unknown", fields)
  end

  defp terminal(producer, execution_id, lifecycle, event_type, fields) do
    RuntimeContract.accept(
      start_event(producer, execution_id, fields) |> Map.put("event_type", event_type),
      lifecycle
    )
  end

  defp start_event(producer, execution_id, fields) do
    Map.merge(
      %{
        "event_type" => "started",
        "execution_id" => execution_id,
        "producer" => producer,
        "attempt" => 1
      },
      fields
    )
  end

  @doc false
  def event_keys, do: @event_keys
end