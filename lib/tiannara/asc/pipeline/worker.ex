defmodule Tiannara.ASC.Pipeline.Worker do
  @moduledoc """
  One GenServer per active project. Owns the phase state machine for that
  project and delegates work to the appropriate sub-civilization module.

  The worker maintains a phase timer so the Observatory can record
  phase_durations for each project — a key input to law discovery.

  ## Phase execution model

  Each phase is executed by calling `handler_module.run(project)` which
  returns `{:ok, updated_project} | {:error, reason}`.

  While sub-civilizations are stubs (Phases B through D), `run/1` returns
  `{:ok, :stub}` and the pipeline advances immediately. Once real implementations
  are in place, the worker blocks in each phase until the sub-civilization
  signals completion via `advance_phase/2`.
  """

  use GenServer
  require Logger

  alias Tiannara.ASC.{CivilizationKernel, Project}
  alias Tiannara.ASC.Pipeline.Phases
  alias Tiannara.ASC.Observatory.ProjectObservatory


  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  def start_link({project_id, _opts} = init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: via(project_id))
  end

  @doc "Advance this project to the next phase. Called by sub-civilizations on completion."
  @spec advance_phase(String.t(), Phases.phase()) :: :ok
  def advance_phase(project_id, next_phase) do
    GenServer.cast(via(project_id), {:advance, next_phase})
  end

  @doc "Report a phase result (partial data update) from a sub-civilization."
  @spec report(String.t(), map()) :: :ok
  def report(project_id, updates) do
    GenServer.cast(via(project_id), {:report, updates})
  end

  # ---------------------------------------------------------------------------
  # GenServer callbacks
  # ---------------------------------------------------------------------------

  @impl true
  def init({project_id, _opts}) do
    {:ok, project} = CivilizationKernel.get_project(project_id)

    state = %{
      project: project,
      phase_started_at: DateTime.utc_now(),
      phase_durations: %{}
    }

    # Kick off the first phase
    send(self(), :execute_phase)
    {:ok, state}
  end

  @impl true
  def handle_info(:execute_phase, state) do
    %{project: project} = state
    Logger.info("[ASC.Pipeline] Project #{project.id} executing phase: #{project.phase}")

    case execute_phase(project) do
      {:ok, :stub} ->
        # Sub-civilization is still a stub — auto-advance to keep pipeline moving
        next_phase = next_phase_for(project.phase)
        send(self(), {:advance, next_phase})
        {:noreply, state}

      {:ok, updated_project} ->
        # Real execution completed synchronously — rare but handled
        new_state = update_project_state(state, updated_project)
        {:noreply, new_state}

      {:error, reason} ->
        Logger.warning("[ASC.Pipeline] Phase #{project.phase} failed: #{inspect(reason)}")
        fail_project(project, reason)
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:advance, next_phase}, state) do
    %{project: project, phase_started_at: started_at, phase_durations: durations} = state

    duration_ms = DateTime.diff(DateTime.utc_now(), started_at, :millisecond)
    new_durations = Map.put(durations, project.phase, duration_ms)

    ProjectObservatory.record(project.id, %{phase_durations: new_durations})

    Phoenix.PubSub.broadcast(Tiannara.PubSub, "asc:project:phase_changed", %{
      project_id: project.id,
      from: project.phase,
      to: next_phase
    })

    updated_project = Project.advance(project, next_phase)
    CivilizationKernel.update_project(updated_project)

    new_state = %{state |
      project: updated_project,
      phase_started_at: DateTime.utc_now(),
      phase_durations: new_durations
    }

    if next_phase not in [:completed, :failed] do
      send(self(), :execute_phase)
    else
      Logger.info("[ASC.Pipeline] Project #{project.id} reached terminal phase: #{next_phase}")
    end

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:advance, next_phase}, state) do
    send(self(), {:advance, next_phase})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:report, updates}, state) do
    updated_project = struct(state.project, Map.put(updates, :updated_at, DateTime.utc_now()))
    CivilizationKernel.update_project(updated_project)
    {:noreply, %{state | project: updated_project}}
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp via(project_id) do
    {:via, Registry, {Tiannara.ASC.Pipeline.Registry, project_id}}
  end

  defp execute_phase(project) do
    with mod when not is_nil(mod) <- Phases.handler(project.phase),
         true <- Code.ensure_loaded?(mod),
         true <- function_exported?(mod, :run, 1) do
      mod.run(project)
    else
      _ -> {:ok, :stub}
    end
  end

  # Testing before Implementation: define "what success looks like" before writing code.
  defp next_phase_for(:requirements),   do: :research
  defp next_phase_for(:research),       do: :architecture
  defp next_phase_for(:architecture),   do: :testing
  defp next_phase_for(:testing),        do: :implementation
  defp next_phase_for(:implementation), do: :crucible
  defp next_phase_for(:crucible),       do: :api_evolution
  defp next_phase_for(:api_evolution),  do: :deployment
  defp next_phase_for(:deployment),     do: :operations
  defp next_phase_for(:operations),     do: :completed
  defp next_phase_for(_),               do: :completed

  defp update_project_state(state, updated_project) do
    CivilizationKernel.update_project(updated_project)
    %{state | project: updated_project}
  end

  defp fail_project(project, reason) do
    failed = Project.advance(project, :failed)
    failed = %{failed | health: Map.put(failed.health, :failure_reason, inspect(reason))}
    CivilizationKernel.update_project(failed)
    Phoenix.PubSub.broadcast(Tiannara.PubSub, "asc:project:phase_changed", %{
      project_id: project.id,
      from: project.phase,
      to: :failed
    })
  end
end
