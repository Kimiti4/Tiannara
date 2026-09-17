defmodule Tiannara.Meta.OPC.Telemetry.EntropyMonitor do
  @moduledoc """
  Phase 5F.6 — Entropy Monitor

  Supervised GenServer that periodically samples and records the entropy
  of observer physics proposals passing through the OPC pipeline.

  Entropy samples are stored in a ring buffer (last @max_samples entries).
  The monitor emits a `:telemetry` event on each sample so external
  dashboards can subscribe.

  ## Usage

      EntropyMonitor.record(0.42)
      {:ok, samples} = EntropyMonitor.recent_samples()
      {:ok, avg}     = EntropyMonitor.average()
  """

  use GenServer
  require Logger

  @max_samples 500
  @sample_interval_ms 5_000

  # ── Public API ────────────────────────────────────────────────────────────

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Records a new entropy sample."
  def record(entropy) when is_number(entropy) do
    GenServer.cast(__MODULE__, {:record, entropy})
  end

  @doc "Returns the most recent entropy samples (up to @max_samples)."
  def recent_samples do
    GenServer.call(__MODULE__, :recent_samples)
  end

  @doc "Returns the rolling average entropy."
  def average do
    GenServer.call(__MODULE__, :average)
  end

  @doc "Returns the current sample count."
  def sample_count do
    GenServer.call(__MODULE__, :sample_count)
  end

  # ── GenServer Callbacks ───────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    schedule_periodic_log()
    Logger.info("📊 [EntropyMonitor] Initialized (max_samples: #{@max_samples})")
    {:ok, %{samples: [], total_recorded: 0}}
  end

  @impl true
  def handle_cast({:record, entropy}, state) do
    samples = [entropy | state.samples] |> Enum.take(@max_samples)

    :telemetry.execute(
      [:tiannara, :opc, :entropy],
      %{value: entropy},
      %{}
    )

    {:noreply, %{state | samples: samples, total_recorded: state.total_recorded + 1}}
  end

  @impl true
  def handle_call(:recent_samples, _from, state) do
    {:reply, {:ok, state.samples}, state}
  end

  @impl true
  def handle_call(:average, _from, state) do
    avg =
      case state.samples do
        [] -> 0.0
        s -> Enum.sum(s) / length(s)
      end

    {:reply, {:ok, avg}, state}
  end

  @impl true
  def handle_call(:sample_count, _from, state) do
    {:reply, {:ok, state.total_recorded}, state}
  end

  @impl true
  def handle_info(:periodic_log, state) do
    avg =
      case state.samples do
        [] -> 0.0
        s -> Enum.sum(s) / length(s)
      end

    Logger.debug(
      "📊 [EntropyMonitor] avg_entropy=#{Float.round(avg, 4)} samples=#{length(state.samples)}"
    )

    schedule_periodic_log()
    {:noreply, state}
  end

  # ── Private ───────────────────────────────────────────────────────────────

  defp schedule_periodic_log do
    Process.send_after(self(), :periodic_log, @sample_interval_ms)
  end
end
