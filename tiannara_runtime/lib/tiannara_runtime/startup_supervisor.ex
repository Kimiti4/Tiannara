defmodule TiannaraRuntime.StartupSupervisor do
  @moduledoc """
  Tiannara Startup Supervisor

  Canonical OTP Supervisor for all Tiannara systems. Uses :rest_for_one strategy
  to ensure proper startup order: CPL first, then Omega robustness, then COP,
  then core runtime.

  This is the single source of truth for child process supervision.
  All system startup MUST go through this supervisor.
  """

  use Supervisor
  require Logger

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    Logger.info("Initializing Tiannara Startup Supervisor...")

    cpl_opts = Keyword.take(opts, [:checkpoint_interval, :storage_path])
    omega_opts = Keyword.get(opts, :omega_opts, [])
    cop_opts = Keyword.get(opts, :cop_opts, [])
    runtime_opts = Keyword.get(opts, :runtime_opts, [])

    children = [
      {TiannaraRuntime.OS.Persistence.ConstitutionalPersistenceLayer,
       Keyword.merge(
         [checkpoint_interval: 30_000, storage_path: "data/cpl"],
         cpl_opts
       )},
      {TiannaraRuntime.Omega.Supervisor, omega_opts},
      {TiannaraRuntime.OS.Observatory, cop_opts},
      {TiannaraRuntimeWeb.Endpoint, []},
      {TiannaraRuntime.RootSupervisor, runtime_opts},
      {TiannaraRuntime.DiscoveryRunner, [cycle_interval: 60_000]}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  @doc """
  Returns the status of all supervised systems.
  """
  @spec status() :: map()
  def status do
    %{
      supervisor: alive?(__MODULE__),
      cpl: alive?(TiannaraRuntime.OS.Persistence.ConstitutionalPersistenceLayer),
      omega: alive?(TiannaraRuntime.Omega.Supervisor),
      cop: alive?(TiannaraRuntime.OS.Observatory),
      runtime: alive?(TiannaraRuntime.RootSupervisor)
    }
  end

  @doc """
  Verifies that all systems are running.
  """
  @spec all_running?() :: boolean()
  def all_running? do
    status = status()
    status.supervisor and status.cpl and status.omega and status.cop and status.runtime
  end

  defp alive?(module) do
    case Process.whereis(module) do
      nil -> false
      pid -> Process.alive?(pid)
    end
  end
end
