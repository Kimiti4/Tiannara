defmodule Tiannara.ASC.Pipeline.Supervisor do
  @moduledoc """
  DynamicSupervisor that manages one `Pipeline.Worker` per active project.

  When `CivilizationKernel.start_project/2` creates a project, it calls
  `Pipeline.Supervisor.start_worker/1` to spawn the worker under this
  supervisor. If the worker crashes it is restarted fresh, but the project
  state is preserved in `CivilizationKernel` (separate process).
  """

  use Supervisor
  require Logger

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Registry for via-tuple worker lookup
      {Registry, keys: :unique, name: Tiannara.ASC.Pipeline.Registry},

      # DynamicSupervisor for worker processes
      {DynamicSupervisor, name: Tiannara.ASC.Pipeline.DynSup, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  @doc "Spawn a pipeline worker for the given project."
  @spec start_worker(String.t()) :: {:ok, pid()} | {:error, term()}
  def start_worker(project_id) do
    spec = {Tiannara.ASC.Pipeline.Worker, {project_id, []}}
    DynamicSupervisor.start_child(Tiannara.ASC.Pipeline.DynSup, spec)
  end

  @doc "Terminate the worker for a project (e.g. on completion or failure)."
  @spec stop_worker(String.t()) :: :ok
  def stop_worker(project_id) do
    case Registry.lookup(Tiannara.ASC.Pipeline.Registry, project_id) do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(Tiannara.ASC.Pipeline.DynSup, pid)
        :ok
      [] ->
        :ok
    end
  end
end
