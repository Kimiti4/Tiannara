defmodule Tiannara.Operations.CampaignScheduler do
  use GenServer
  require Logger

  alias Tiannara.ASC.CivilizationRunner

  @scheduling_interval :timer.hours(12)

  defp emit(:cycle_start),
    do:
      :telemetry.execute(
        [:tiannara, :campaign, :cycle_start],
        %{system_time: System.system_time()},
        %{}
      )

  defp emit(:cycle_stop, dur, ok) do
    :telemetry.execute([:tiannara, :campaign, :cycle_stop], %{duration_ms: dur}, %{ok: ok})
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def schedule_now, do: GenServer.cast(__MODULE__, :schedule)
  def status, do: GenServer.call(__MODULE__, :status)

  @impl true
  def init(_opts) do
    schedule_next()

    {:ok,
     %{
       last_run_at: nil,
       next_run_at: DateTime.utc_now() |> DateTime.add(@scheduling_interval, :millisecond),
       runs_completed: 0,
       runs_failed: 0,
       last_result: nil
     }}
  end

  @impl true
  def handle_cast(:schedule, state) do
    new_state =
      if Tiannara.Application.asc_enabled?() do
        Logger.info("CampaignScheduler: Starting scheduled campaign run")
        emit(:cycle_start)
        start = System.monotonic_time(:millisecond)
        result = CivilizationRunner.run_all()
        dur = System.monotonic_time(:millisecond) - start
        emit(:cycle_stop, dur, match?({:ok, _}, result))
        record_run(result, state)
      else
        # ASC disabled — the loop plumbing stays alive, but there's nothing to execute.
        Logger.debug("CampaignScheduler: ASC disabled — skipping campaign cycle")
        state
      end

    {:noreply, new_state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(:scheduled_run, state) do
    new_state =
      if Tiannara.Application.asc_enabled?() do
        Logger.info("CampaignScheduler: Starting scheduled campaign run")
        emit(:cycle_start)
        start = System.monotonic_time(:millisecond)
        result = CivilizationRunner.run_all()
        dur = System.monotonic_time(:millisecond) - start
        emit(:cycle_stop, dur, match?({:ok, _}, result))
        record_run(result, state)
      else
        # ASC disabled — the loop plumbing stays alive, but there's nothing to execute.
        Logger.debug("CampaignScheduler: ASC disabled — skipping campaign cycle")
        state
      end

    schedule_next()
    {:noreply, new_state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp record_run({:ok, results}, state) do
    Logger.info("CampaignScheduler: Run completed — #{length(results)} phases")

    %{
      state
      | last_run_at: DateTime.utc_now(),
        runs_completed: state.runs_completed + 1,
        last_result: {:ok, results}
    }
  end

  defp record_run({:error, reason}, state) do
    Logger.warning("CampaignScheduler: Run failed: #{inspect(reason)}")

    %{
      state
      | last_run_at: DateTime.utc_now(),
        runs_failed: state.runs_failed + 1,
        last_result: {:error, reason}
    }
  end

  defp schedule_next do
    Process.send_after(self(), :scheduled_run, @scheduling_interval)
  end
end
