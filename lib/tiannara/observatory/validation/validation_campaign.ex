defmodule Tiannara.Observatory.ValidationCampaign do
  use GenServer
  require Logger

  alias Tiannara.Observatory.Validation.Checks
  alias Tiannara.Observatory.Validation.Reporter
  alias Tiannara.Observatory.Validation.MetricsStore

  @type duration_ms :: non_neg_integer()
  @type interval_ms :: non_neg_integer()
  @type check_atom :: atom()

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          duration: duration_ms(),
          interval: interval_ms(),
          checks: [check_atom()],
          started_at: DateTime.t() | nil,
          status: :idle | :running | :completed | :failed | :cancelled,
          results: [map()],
          constitutional_score: float() | nil
        }

  defstruct id: nil,
            name: "Unnamed Campaign",
            duration: :timer.hours(1),
            interval: :timer.minutes(5),
            checks: [],
            started_at: nil,
            status: :idle,
            results: [],
            constitutional_score: nil

  def start_link(%__MODULE__{} = campaign) do
    GenServer.start_link(__MODULE__, campaign,
      name: via_tuple(campaign.id),
      restart: :transient
    )
  end

  def launch_preset(preset_name, opts \\ []) do
    campaign = preset(preset_name, opts)
    {:ok, pid} = start_link(campaign)
    GenServer.cast(pid, :begin)
    {:ok, campaign.id, pid}
  end

  def cancel(campaign_id) do
    case Registry.lookup(Tiannara.Observatory.ValidationRegistry, campaign_id) do
      [{pid, _}] -> GenServer.cast(pid, :cancel)
      [] -> {:error, :not_found}
    end
  end

  def status(campaign_id) do
    case Registry.lookup(Tiannara.Observatory.ValidationRegistry, campaign_id) do
      [{pid, _}] -> GenServer.call(pid, :status)
      [] -> {:error, :not_found}
    end
  end

  def preset(name, opts \\ []), do: preset_by_name(name, opts)

  defp preset_by_name(:quick, opts) do
    struct!(__MODULE__,
      id: generate_id("quick"),
      name: "Quick Validation (5 min)",
      duration: Keyword.get(opts, :duration, :timer.minutes(5)),
      interval: Keyword.get(opts, :interval, :timer.seconds(30)),
      checks: [:memory_growth, :mailbox_growth, :scheduler_latency, :constitutional_score]
    )
  end

  defp preset_by_name(:soak_24h, opts) do
    struct!(__MODULE__,
      id: generate_id("soak24"),
      name: "24-Hour Runtime Validation",
      duration: Keyword.get(opts, :duration, :timer.hours(24)),
      interval: Keyword.get(opts, :interval, :timer.minutes(5)),
      checks: [
        :memory_growth, :mailbox_growth, :scheduler_latency, :constitutional_score,
        :event_bus_health, :world_model_consistency, :executive_memory_replay,
        :knowledge_integrity, :resource_usage, :dets_integrity, :ets_growth
      ]
    )
  end

  defp preset_by_name(:chaos, opts) do
    struct!(__MODULE__,
      id: generate_id("chaos"),
      name: "Chaos Validation (1 hr)",
      duration: Keyword.get(opts, :duration, :timer.hours(1)),
      interval: Keyword.get(opts, :interval, :timer.seconds(10)),
      checks: [:memory_growth, :mailbox_growth, :scheduler_latency, :event_bus_health, :process_survival, :resource_usage]
    )
  end

  defp preset_by_name(:regression, opts) do
    struct!(__MODULE__,
      id: generate_id("regression"),
      name: "Regression Suite",
      duration: Keyword.get(opts, :duration, :timer.minutes(30)),
      interval: Keyword.get(opts, :interval, :timer.minutes(1)),
      checks: [:constitutional_score, :world_model_consistency, :executive_memory_replay, :knowledge_integrity, :event_bus_health]
    )
  end

  @impl true
  def init(%__MODULE__{} = campaign) do
    MetricsStore.create_table(campaign.id)
    {:ok, campaign}
  end

  @impl true
  def handle_cast(:begin, %__MODULE__{status: :idle} = state) do
    now = DateTime.utc_now()
    state = %{state | status: :running, started_at: now}
    Logger.info("[ValidationCampaign] Started '#{state.name}' (#{length(state.checks)} checks, #{format_duration(state.duration)}, interval #{format_duration(state.interval)})")
    publish_event(:campaign_started, state)
    schedule_tick(state)
    schedule_completion(state)
    {:noreply, state}
  end

  def handle_cast(:begin, state), do: {:noreply, state}

  @impl true
  def handle_cast(:cancel, state) do
    Logger.info("[ValidationCampaign] Cancelled '#{state.name}'")
    state = %{state | status: :cancelled}
    publish_event(:campaign_cancelled, state)
    {:stop, :normal, state}
  end

  @impl true
  def handle_info(:tick, %__MODULE__{status: :running} = state) do
    tick_result = run_checks(state.checks, state.id)
    state = %{state | results: state.results ++ [tick_result]}
    MetricsStore.record(state.id, tick_result)
    publish_event(:tick_completed, %{campaign_id: state.id, result: tick_result})

    if any_critical_failures?(tick_result) do
      Logger.warning("[ValidationCampaign] Critical failure detected in '#{state.name}'")
      publish_event(:critical_failure, %{campaign_id: state.id, result: tick_result})
    end

    schedule_tick(state)
    {:noreply, state}
  end

  def handle_info(:tick, state), do: {:noreply, state}

  @impl true
  def handle_info(:complete, %__MODULE__{status: :running} = state) do
    state = %{state | status: :completed}
    report = Reporter.generate(state)
    publish_event(:campaign_completed, %{campaign_id: state.id, report: report})
    Logger.info("[ValidationCampaign] Completed '#{state.name}' — #{length(state.results)} ticks collected")
    {:stop, :normal, state}
  end

  def handle_info(:complete, state), do: {:noreply, state}

  @impl true
  def handle_call(:status, _from, state) do
    summary = %{
      id: state.id, name: state.name, status: state.status,
      ticks_collected: length(state.results), started_at: state.started_at, checks: state.checks
    }
    {:reply, summary, state}
  end

  defp run_checks(checks, campaign_id) do
    timestamp = DateTime.utc_now()
    results = Enum.map(checks, fn check -> {check, Checks.execute(check)} end)
    %{
      campaign_id: campaign_id, timestamp: timestamp, checks: results,
      passed: Enum.count(results, fn {_, r} -> r.status == :pass end),
      failed: Enum.count(results, fn {_, r} -> r.status == :fail end),
      warnings: Enum.count(results, fn {_, r} -> r.status == :warn end)
    }
  end

  defp any_critical_failures?(tick_result) do
    Enum.any?(tick_result.checks, fn
      {_, %{status: :fail, severity: :critical}} -> true
      _ -> false
    end)
  end

  defp schedule_tick(%{interval: interval}), do: Process.send_after(self(), :tick, interval)

  defp schedule_completion(%{duration: duration}), do: Process.send_after(self(), :complete, duration)

  defp publish_event(type, payload) do
    if Code.ensure_loaded?(Tiannara.EventBus) do
      Tiannara.EventBus.publish(:observatory, type, payload)
    else
      Logger.debug("[ValidationCampaign] Event: #{type}")
    end
  end

  defp via_tuple(id), do: {:via, Registry, {Tiannara.Observatory.ValidationRegistry, id}}

  defp generate_id(prefix), do: "#{prefix}-#{System.system_time(:millisecond)}-#{:rand.uniform(9999)}"

  defp format_duration(ms) do
    cond do
      ms >= :timer.hours(1) -> "#{div(ms, :timer.hours(1))}h"
      ms >= :timer.minutes(1) -> "#{div(ms, :timer.minutes(1))}m"
      true -> "#{div(ms, :timer.seconds(1))}s"
    end
  end
end
