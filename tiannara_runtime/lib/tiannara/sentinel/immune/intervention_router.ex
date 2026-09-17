defmodule Tiannara.Sentinel.Immune.InterventionRouter do
  @moduledoc """
  Routes recommendations to the auditor and dashboard.
  Strictly rejects any execution attempts in Phase B1.
  """
  use GenServer
  require Logger

  @allowed_statuses [:proposed]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def route(intervention) do
    GenServer.call(__MODULE__, {:route, intervention})
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:route, intervention}, _from, state) do
    if intervention.status not in @allowed_statuses do
      Logger.error("Phase B1 Constraint Violation: Attempted to route non-proposed intervention.")
      {:reply, {:error, :execution_not_supported_in_phase_b1}, state}
    else
      # Forward to StabilizationAuditor
      Tiannara.Sentinel.Immune.StabilizationAuditor.record(intervention)
      {:reply, :ok, state}
    end
  end
end
