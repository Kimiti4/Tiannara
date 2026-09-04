defmodule Tiannara.Omega.OmegaRuntime do
  @moduledoc """
  Omega Runtime — TIA-OMEGA-INTEGRATION

  Top-level supervisor for Tiannara's Ω agency integration layer.
  Wires together all integration subsystems into a coherent,
  continuously operating autonomous scientific agent.

  ## Supervised Integration Layer

      Omega Integration (Artifact 16)
          ├── AgencyLoop
          ├── RuntimeHealthAggregator
          ├── ConstitutionalComplianceMonitor
          └── Observatory
  """

  use Supervisor
  require Logger

  alias Tiannara.Omega.{
    AgencyLoop,
    RuntimeHealthAggregator,
    ConstitutionalComplianceMonitor,
    Observatory
  }

  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec status() :: map()
  def status do
    RuntimeHealthAggregator.full_status()
  end

  @spec health() :: map()
  def health do
    RuntimeHealthAggregator.health()
  end

  @spec current_phase() :: atom()
  def current_phase do
    AgencyLoop.current_phase()
  end

  @spec compliance() :: map()
  def compliance do
    ConstitutionalComplianceMonitor.status()
  end

  @spec observatory() :: map()
  def observatory do
    Observatory.dashboard()
  end

  @impl true
  def init(opts) do
    Logger.info("""
    ╔══════════════════════════════════════════════════════════╗
    ║           TIANNARA Ω AGENCY INTEGRATION                 ║
    ║           TIA-OMEGA-INTEGRATION                         ║
    ╚══════════════════════════════════════════════════════════╝
    """)

    compliance_interval = Keyword.get(opts, :compliance_interval_ms, 60_000)

    children = [
      %{id: RuntimeHealthAggregator, start: {RuntimeHealthAggregator, :start_link, [[]]}, restart: :permanent, shutdown: 5_000, type: :worker},
      %{id: ConstitutionalComplianceMonitor, start: {ConstitutionalComplianceMonitor, :start_link, [[interval_ms: compliance_interval]]}, restart: :permanent, shutdown: 5_000, type: :worker},
      %{id: Observatory, start: {Observatory, :start_link, [[]]}, restart: :permanent, shutdown: 5_000, type: :worker},
      %{id: AgencyLoop, start: {AgencyLoop, :start_link, [[]]}, restart: :permanent, shutdown: 10_000, type: :worker}
    ]

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 3, max_seconds: 60)
  end
end
