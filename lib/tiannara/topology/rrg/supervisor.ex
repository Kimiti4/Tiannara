defmodule Tiannara.Topology.RRG.Supervisor do
  @moduledoc """
  RRG (Recursive Rate Governance) supervisor.

  Coordinates governance policies, rate limiting, and system-wide regulation mechanisms.
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Main RRG system
      {Tiannara.Topology.RRG, []},
      
      # Policy manager
      {Tiannara.Topology.RRG.PolicyManager, []},
      
      # Rate limiter
      {Tiannara.Topology.RRG.RateLimiter, []},
      
      # Compliance enforcer
      {Tiannara.Topology.RRG.ComplianceEnforcer, []},
      
      # Violation auditor
      {Tiannara.Topology.RRG.ViolationAuditor, []}
    ]

    Logger.info("Initializing RRG supervisor")

    Supervisor.init(children, strategy: :one_for_all, max_restarts: 5, max_seconds: 10)
  end
end