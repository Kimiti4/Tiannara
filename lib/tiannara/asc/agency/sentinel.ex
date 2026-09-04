defmodule Tiannara.ASC.Agency.Sentinel do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    interval = Keyword.get(opts, :interval, :timer.seconds(30))
    schedule_tick(interval)
    {:ok, %{interval: interval}}
  end

  @impl true
  def handle_info(:tick, state) do
    context = %{
      system_health: :healthy,
      pending_challenges: safe_call(Tiannara.CRAV.SoakTest, :status, [], 0),
      recent_observations: []
    }
    case evaluate_trigger(context) do
      {:trigger, reason} ->
        Logger.info("[Sentinel] Agency cycle triggered: #{reason}")
        Tiannara.ASC.Agency.Orchestrator.request_cycle(context, reason)
      :wait -> :ok
    end
    schedule_tick(state.interval)
    {:noreply, state}
  end

  defp evaluate_trigger(%{pending_challenges: count}) when is_integer(count) and count > 0, do: {:trigger, :pending_challenges}
  defp evaluate_trigger(_), do: :wait

  defp safe_call(mod, fun, args, default) do
    if Code.ensure_loaded?(mod) and Process.whereis(mod) != nil do
      apply(mod, fun, args)
    else
      default
    end
  rescue
    _ -> default
  end

  defp schedule_tick(interval), do: Process.send_after(self(), :tick, interval)
end
