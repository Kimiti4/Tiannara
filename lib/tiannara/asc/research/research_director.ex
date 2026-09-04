defmodule Tiannara.ASC.Research.Director do
  use GenServer
  require Logger

  alias Tiannara.ASC.Core.Registry
  alias Tiannara.ASC.Core.Metrics

  @scheduling_interval :timer.minutes(15)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def submit_program(program_spec) do
    GenServer.call(__MODULE__, {:submit_program, program_spec})
  end

  def active_programs, do: GenServer.call(__MODULE__, :active_programs)

  def priorities, do: GenServer.call(__MODULE__, :priorities)

  def allocate_resources(program_id, resources) do
    GenServer.call(__MODULE__, {:allocate, program_id, resources})
  end

  def stats, do: GenServer.call(__MODULE__, :stats)

  @impl true
  def init(_opts) do
    try do
      Registry.register(:research_director, __MODULE__,
        [:research_coordination, :campaign_scheduling, :priority_balancing, :resource_allocation],
        :phase6
      )
    rescue
      _ -> :ok
    end

    schedule_scheduling()

    {:ok, %{
      programs: %{},
      campaigns: %{},
      priorities: [],
      resource_budget: %{compute: 1000, time_hours: 100, energy: 500},
      resource_used: %{compute: 0, time_hours: 0, energy: 0},
      total_programs: 0,
      total_campaigns: 0,
      total_experiments: 0,
      completed_programs: 0,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call({:submit_program, spec}, _from, state) do
    program_id = "prog_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"

    program = %{
      id: program_id,
      name: Map.get(spec, :name, "Unnamed Program"),
      domain: Map.get(spec, :domain, :general),
      objective: Map.get(spec, :objective, ""),
      priority: Map.get(spec, :priority, :medium),
      status: :active,
      campaigns: [],
      resource_allocation: Map.get(spec, :resources, %{compute: 100, time_hours: 10}),
      created_at: DateTime.utc_now(),
      completed_at: nil
    }

    try do
      Metrics.record(:research, :programs_submitted, 1, %{program_id: program_id})
    rescue
      _ -> :ok
    end

    Logger.info("ResearchDirector: New program '#{program.name}' (#{program_id})")

    {:reply, {:ok, program_id}, %{state |
      programs: Map.put(state.programs, program_id, program),
      total_programs: state.total_programs + 1
    }}
  end

  @impl true
  def handle_call(:active_programs, _from, state) do
    active = state.programs |> Map.values() |> Enum.filter(&(&1.status == :active))
    {:reply, active, state}
  end

  @impl true
  def handle_call(:priorities, _from, state) do
    {:reply, state.priorities, state}
  end

  @impl true
  def handle_call({:allocate, program_id, resources}, _from, state) do
    case Map.fetch(state.programs, program_id) do
      {:ok, program} ->
        updated = %{program | resource_allocation: resources}
        {:reply, :ok, put_in(state.programs[program_id], updated)}

      :error ->
        {:reply, {:error, :program_not_found}, state}
    end
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{
      active_programs: state.programs |> Map.values() |> Enum.count(&(&1.status == :active)),
      total_programs: state.total_programs,
      total_campaigns: state.total_campaigns,
      total_experiments: state.total_experiments,
      completed_programs: state.completed_programs,
      resource_budget: state.resource_budget,
      resource_used: state.resource_used
    }, state}
  end

  @impl true
  def handle_info(:schedule, state) do
    new_state = run_scheduling_cycle(state)
    schedule_scheduling()
    {:noreply, new_state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp run_scheduling_cycle(state) do
    priorities =
      state.programs
      |> Map.values()
      |> Enum.filter(&(&1.status == :active))
      |> Enum.sort_by(fn p ->
        priority_weight = %{critical: 4, high: 3, medium: 2, low: 1}
        Map.get(priority_weight, p.priority, 0)
      end, :desc)
      |> Enum.map(& &1.id)

    %{state | priorities: priorities}
  end

  defp schedule_scheduling do
    Process.send_after(self(), :schedule, @scheduling_interval)
  end
end
