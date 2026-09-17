defmodule ObservationBus.CIL.Diagnostics do
  @moduledoc """
  Provides comprehensive diagnostics and health checks for all CIL subsystems.

  Used by the Observatory API status endpoint and by Mission Control
  to verify that the Constitutional Intelligence Layer is functioning correctly.
  """

  use GenServer

  @subsystems [
    :pattern_registry, :pattern_engine, :causal_engine, :anomaly_detector,
    :trend_engine, :health_engine, :recommendation_engine, :knowledge_synthesizer,
    :risk_analyzer, :confidence_engine
  ]

  defstruct [:subsystem_status, :started_at]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %__MODULE__{
      subsystem_status: Enum.into(@subsystems, %{}, &{&1, :starting}),
      started_at: DateTime.utc_now()
    }}
  end

  @doc "Report that a subsystem has started successfully."
  @spec report_started(atom()) :: :ok
  def report_started(subsystem) when subsystem in @subsystems do
    GenServer.cast(__MODULE__, {:report, subsystem, :operational})
  end

  @doc "Report that a subsystem has failed."
  @spec report_failed(atom(), String.t()) :: :ok
  def report_failed(subsystem, reason \\ "unknown") when subsystem in @subsystems do
    GenServer.cast(__MODULE__, {:report, subsystem, {:failed, reason}})
  end

  @doc "Return full diagnostic report."
  @spec report() :: map()
  def report do
    GenServer.call(__MODULE__, :report)
  end

  @doc "Return subsystem status only."
  @spec subsystem_status() :: map()
  def subsystem_status do
    GenServer.call(__MODULE__, :subsystem_status)
  end

  @impl true
  def handle_cast({:report, subsystem, status}, state) do
    updated = put_in(state.subsystem_status[subsystem], %{
      status: status,
      last_updated: DateTime.utc_now()
    })
    {:noreply, %{state | subsystem_status: updated}}
  end

  @impl true
  def handle_call(:report, _from, state) do
    all_operational = Enum.all?(state.subsystem_status, fn {_k, v} ->
      match?(%{status: :operational}, v)
    end)

    {:reply, %{
      overall_status: if(all_operational, do: :operational, else: :degraded),
      uptime: DateTime.diff(DateTime.utc_now(), state.started_at, :second),
      subsystems: state.subsystem_status,
      started_at: state.started_at
    }, state}
  end

  def handle_call(:subsystem_status, _from, state) do
    {:reply, state.subsystem_status, state}
  end
end
