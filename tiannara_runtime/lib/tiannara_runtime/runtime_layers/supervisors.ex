defmodule TiannaraRuntime.BootPolicy do
  @moduledoc false

  require Logger

  def required_child(module, opts \\ []) do
    if Code.ensure_loaded?(module) do
      [{module, opts}]
    else
      raise "Required module missing from boot graph: #{inspect(module)}"
    end
  end

  def optional_child(module, opts \\ []) do
    if Code.ensure_loaded?(module) do
      [{module, opts}]
    else
      Logger.warning("Skipping optional module (not loaded): #{inspect(module)}")
      []
    end
  end

  def experimental_child(module, app_env_key, opts \\ []) do
    enabled? = Application.get_env(:tiannara_runtime, app_env_key, false)

    if enabled? and Code.ensure_loaded?(module) do
      [{module, opts}]
    else
      []
    end
  end
end

defmodule TiannaraRuntime.Telemetry.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children =
      TiannaraRuntime.BootPolicy.optional_child(
        TiannaraRuntime.Observability.StreamProcessor,
        name: :observability_stream_processor
      ) ++
        TiannaraRuntime.BootPolicy.optional_child(TiannaraRuntime.Monitoring.Supervisor)

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule TiannaraRuntime.Infrastructure.Supervisor do
  @moduledoc """
  Infrastructure authority layer.

  Owns communication, identity, telemetry, and transport primitives.
  """
  use Supervisor
  import TiannaraRuntime.BootPolicy

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children =
      [
        {Phoenix.PubSub, name: TiannaraRuntime.PubSub},
        {Registry, keys: :unique, name: Tiannara.Registry},
        {TiannaraRuntime.SharedMemory, []}
      ] ++
        required_child(TiannaraRuntime.NATS.Supervisor) ++
        optional_child(TiannaraRuntime.Telemetry.Supervisor)

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule TiannaraRuntime.Execution.Supervisor do
  @moduledoc """
  Execution authority layer.

  Owns scheduling, execution substrate, and runtime bridge components.
  """
  use Supervisor
  import TiannaraRuntime.BootPolicy

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children =
      required_child(Tiannara.OPC.CoreSupervisor) ++
        optional_child(Tiannara.OPC.Supervisor)

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule TiannaraRuntime.Ecology.Supervisor do
  @moduledoc """
  Ecology authority layer.

  Owns world-state generation and ecosystem dynamics.
  """
  use Supervisor
  import TiannaraRuntime.BootPolicy

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children =
      required_child(Tiannara.UniverseSupervisor) ++
        optional_child(TiannaraRuntime.Legacy.Tiannara.OLEF.FieldSupervisor) ++
        optional_child(TiannaraRuntime.OCM.Supervisor) ++
        optional_child(Tiannara.RRG.Supervisor)

    Supervisor.init(children, strategy: :rest_for_one)
  end
end

defmodule TiannaraRuntime.Constraint.Supervisor do
  @moduledoc """
  Constraint authority layer.

  Internal hierarchy:
  - analyzers: IRD, CCR
  - stabilizers: HSV
  - policy filters: ACF
  - broker: SafetyCortex (sole external constraint emitter)
  """
  use Supervisor
  import TiannaraRuntime.BootPolicy

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    analyzer_children =
      optional_child(TiannaraRuntime.IRD.Supervisor) ++
        optional_child(TiannaraRuntime.CCR.Supervisor)

    stabilizer_children = optional_child(Tiannara.HSV.Supervisor)
    filter_children = optional_child(TiannaraRuntime.ACF.Supervisor)
    broker_children = required_child(TiannaraRuntime.Cortex.SafetyCortex)

    children = analyzer_children ++ stabilizer_children ++ filter_children ++ broker_children
    Supervisor.init(children, strategy: :rest_for_one)
  end
end

defmodule TiannaraRuntime.Meta.Supervisor do
  @moduledoc """
  Meta-governance authority layer.

  Must remain parameter-space only.
  """
  use Supervisor
  import TiannaraRuntime.BootPolicy

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = required_child(Tiannara.MetaSOPL.RateModulationSupervisor)
    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule TiannaraRuntime.RootSupervisor do
  @moduledoc """
  Flat root for constrained authority architecture.

  Boot order: Infrastructure -> Execution -> Ecology -> Constraint -> Meta.
  Control authority: Meta -> Constraint -> Ecology -> Execution.
  Telemetry direction: Execution -> Ecology -> Constraint -> Meta.
  """
  use Supervisor
  import TiannaraRuntime.BootPolicy

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    profile = Application.get_env(:tiannara_runtime, :boot_profile, :stable)

    children =
      authority_child(TiannaraRuntime.Infrastructure.Supervisor, :infrastructure) ++
        authority_child(TiannaraRuntime.Execution.Supervisor, :execution) ++
        authority_child(TiannaraRuntime.Ecology.Supervisor, :ecology) ++
        maybe_constraint_and_meta(profile)

    Supervisor.init(children, strategy: :rest_for_one)
  end

  defp authority_child(module, id) do
    [Supervisor.child_spec({module, []}, id: id)]
  end

  defp maybe_constraint_and_meta(:minimal), do: []

  defp maybe_constraint_and_meta(:stable) do
    authority_child(TiannaraRuntime.Constraint.Supervisor, :constraint) ++
      authority_child(TiannaraRuntime.Meta.Supervisor, :meta)
  end

  defp maybe_constraint_and_meta(:research) do
    authority_child(TiannaraRuntime.Constraint.Supervisor, :constraint) ++
      authority_child(TiannaraRuntime.Meta.Supervisor, :meta) ++
      TiannaraRuntime.BootPolicy.experimental_child(TiannaraRuntime.NDE.Supervisor, :enable_nde) ++
      TiannaraRuntime.BootPolicy.experimental_child(TiannaraRuntime.TWP.Supervisor, :enable_twp) ++
      TiannaraRuntime.BootPolicy.experimental_child(TiannaraRuntime.OSL.Supervisor, :enable_osl)
  end

  defp maybe_constraint_and_meta(_), do: maybe_constraint_and_meta(:stable)
end
