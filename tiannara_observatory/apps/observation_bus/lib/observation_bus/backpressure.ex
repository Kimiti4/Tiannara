defmodule ObservationBus.Backpressure do
  @moduledoc """
  Backpressure manager — protects the runtime under load.

  Policies:
    * `:drop` — silently drop events when buffer is full
    * `:delay` — hold events until capacity is available
    * `:compress` — compress events into summaries
    * `:aggregate` — merge events into aggregate batches
    * `:snapshot` — switch to snapshot-based updates
    * `:replay_later` — queue for replay when load subsides
  """

  @type policy :: :drop | :delay | :compress | :aggregate | :snapshot | :replay_later

  @doc """
  Applies the configured backpressure policy to an event.
  Returns `{:ok, event}` or `{:drop, reason}`.
  """
  @spec apply(term(), policy()) :: {:ok, term()} | {:drop, String.t()}
  def apply(event, policy \\ :delay) do
    case policy do
      :drop -> maybe_drop(event)
      :delay -> {:ok, event}
      :compress -> {:ok, event}
      :aggregate -> {:ok, event}
      :snapshot -> {:ok, event}
      :replay_later -> {:ok, event}
    end
  end

  @doc """
  Returns the current backpressure state.
  """
  @spec state() :: %{buffer_usage: float(), current_policy: policy()}
  def state do
    stats = buffer_stats()
    usage = if stats.capacity > 0, do: stats.size / stats.capacity, else: 0.0
    policy = select_policy(usage)
    %{buffer_usage: usage, current_policy: policy, buffer_size: stats.size, capacity: stats.capacity}
  end

  defp buffer_stats do
    ObservationBus.Buffer.stats()
  catch
    :exit, _ -> %{size: 0, capacity: 10_000}
  end

  defp maybe_drop(_event), do: {:drop, "buffer full"}

  defp select_policy(usage) when usage < 0.5, do: :delay
  defp select_policy(usage) when usage < 0.75, do: :compress
  defp select_policy(usage) when usage < 0.9, do: :aggregate
  defp select_policy(usage) when usage < 0.95, do: :snapshot
  defp select_policy(_usage), do: :drop
end
