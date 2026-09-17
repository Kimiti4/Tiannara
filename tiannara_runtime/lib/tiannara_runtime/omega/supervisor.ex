defmodule TiannaraRuntime.Omega.Supervisor do
  @moduledoc """
  Omega robustness substrate.

  Starts the readiness systems required for long soak stability while keeping
  each concern isolated under a one-for-one supervisor.
  """

  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    children = [
      {TiannaraRuntime.Omega.SentinelEventBus, Keyword.get(opts, :event_bus, [])},
      {TiannaraRuntime.Omega.FailureObservatory, Keyword.get(opts, :failure_observatory, [])},
      {TiannaraRuntime.Omega.ExecutiveMemory, Keyword.get(opts, :executive_memory, [])},
      {TiannaraRuntime.Omega.DependencyIsolation, Keyword.get(opts, :dependency_isolation, [])},
      {TiannaraRuntime.Omega.EventStoreAudit, Keyword.get(opts, :event_store_audit, [])},
      {TiannaraRuntime.Omega.CheckpointReliability,
       Keyword.get(opts, :checkpoint_reliability, [])},
      {TiannaraRuntime.Omega.RuntimeHealthEngine, Keyword.get(opts, :runtime_health, [])},
      {TiannaraRuntime.Omega.Heartbeat, Keyword.get(opts, :heartbeat, [])},
      {TiannaraRuntime.Omega.ConstitutionalScheduler, Keyword.get(opts, :scheduler, [])},
      {TiannaraRuntime.Omega.ResearchDirectorReadiness,
       Keyword.get(opts, :research_readiness, [])}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @spec status() :: map()
  def status do
    %{
      supervisor: alive?(__MODULE__),
      event_bus: alive?(TiannaraRuntime.Omega.SentinelEventBus),
      failure_observatory: alive?(TiannaraRuntime.Omega.FailureObservatory),
      executive_memory: alive?(TiannaraRuntime.Omega.ExecutiveMemory),
      dependency_isolation: alive?(TiannaraRuntime.Omega.DependencyIsolation),
      event_store_audit: alive?(TiannaraRuntime.Omega.EventStoreAudit),
      checkpoint_reliability: alive?(TiannaraRuntime.Omega.CheckpointReliability),
      runtime_health: alive?(TiannaraRuntime.Omega.RuntimeHealthEngine),
      heartbeat: alive?(TiannaraRuntime.Omega.Heartbeat),
      scheduler: alive?(TiannaraRuntime.Omega.ConstitutionalScheduler),
      research_readiness: alive?(TiannaraRuntime.Omega.ResearchDirectorReadiness)
    }
  end

  defp alive?(module) do
    case Process.whereis(module) do
      nil -> false
      pid -> Process.alive?(pid)
    end
  end
end
