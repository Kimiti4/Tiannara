defmodule Tiannara.ASC.Engineering.Director do
  use GenServer
  require Logger

  alias Tiannara.ASC.Engineering.{
    DesignSynthesisEngine, OptimizationEngine,
    ValidationEngine, ManufacturingPlanner, KnowledgeBase
  }
  alias Tiannara.Operations.CampaignIntegration

  @engineering_interval :timer.hours(4)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def engineer, do: GenServer.cast(__MODULE__, :engineer)
  def submit_principle(principle), do: GenServer.call(__MODULE__, {:submit, principle})
  def active_programs, do: GenServer.call(__MODULE__, :active_programs)
  def stats, do: GenServer.call(__MODULE__, :stats)
  def backlog, do: GenServer.call(__MODULE__, :backlog)

  @impl true
  def init(_opts) do
    subscribe_to_inputs()
    schedule_engineering()

    {:ok, %{
      programs: %{},
      backlog: [],
      total_principles: 0,
      total_designs: 0,
      total_validated: 0,
      total_failed: 0,
      cycles: 0,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_cast(:engineer, state) do
    {:noreply, run_cycle(state)}
  end

  @impl true
  def handle_call({:submit, principle}, _from, state) do
    program_id = "eng_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"

    program = %{
      id: program_id,
      principle: principle,
      status: :queued,
      design: nil,
      validation: nil,
      manufacturing_plan: nil,
      created_at: DateTime.utc_now()
    }

    {:reply, {:ok, program_id}, %{state |
      programs: Map.put(state.programs, program_id, program),
      backlog: [program_id | state.backlog],
      total_principles: state.total_principles + 1
    }}
  end

  @impl true
  def handle_call(:active_programs, _from, state) do
    active = state.programs |> Map.values() |> Enum.filter(&(&1.status in [:queued, :designing, :validating]))
    {:reply, active, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{
      total_principles: state.total_principles,
      total_designs: state.total_designs,
      total_validated: state.total_validated,
      total_failed: state.total_failed,
      cycles: state.cycles,
      backlog_size: length(state.backlog),
      active_programs: state.programs |> Map.values() |> Enum.count(&(&1.status in [:queued, :designing, :validating]))
    }, state}
  end

  @impl true
  def handle_call(:backlog, _from, state) do
    {:reply, state.backlog, state}
  end

  @impl true
  def handle_info({:executive_bus_message, %{type: "campaign.phase8a.input", payload: payload}}, state) do
    principles = extract_principles(payload)

    new_state = Enum.reduce(principles, state, fn principle, acc ->
      program_id = "eng_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
      program = %{id: program_id, principle: principle, status: :queued, design: nil, validation: nil, manufacturing_plan: nil, created_at: DateTime.utc_now()}

      %{acc |
        programs: Map.put(acc.programs, program_id, program),
        backlog: [program_id | acc.backlog],
        total_principles: acc.total_principles + 1
      }
    end)

    {:noreply, new_state}
  end

  @impl true
  def handle_info(:scheduled_engineering, state) do
    new_state = run_cycle(state)
    schedule_engineering()
    {:noreply, new_state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp run_cycle(%{backlog: []} = state), do: state

  defp run_cycle(state) do
    {batch, remaining} = Enum.split(state.backlog, 3)

    {state, results} = Enum.reduce(batch, {state, []}, fn program_id, {acc_state, acc_results} ->
      program = Map.get(acc_state.programs, program_id)

      if program == nil do
        {acc_state, acc_results}
      else
        case process_program(program) do
          {:ok, updated_program} ->
            {put_in(acc_state.programs[program_id], updated_program), [:ok | acc_results]}

          {:error, _reason} ->
            failed = %{program | status: :failed}
            {put_in(acc_state.programs[program_id], failed), [:error | acc_results]}
        end
      end
    end)

    passed = Enum.count(results, &(&1 == :ok))
    failed = Enum.count(results, &(&1 == :error))

    if passed > 0 do
      CampaignIntegration.route_result(:phase8, %{
        status: :completed,
        designs: passed,
        failed: failed,
        completed_at: DateTime.utc_now()
      })
    end

    %{state |
      backlog: remaining,
      total_designs: state.total_designs + passed,
      total_validated: state.total_validated + passed,
      total_failed: state.total_failed + failed,
      cycles: state.cycles + 1
    }
  end

  defp process_program(program) do
    with \
      {:ok, design} <- DesignSynthesisEngine.synthesize(program.principle),
      {:ok, optimized} <- OptimizationEngine.optimize(design),
      {:ok, validation} <- ValidationEngine.validate(optimized),
      {:ok, mfg_plan} <- ManufacturingPlanner.plan(optimized) do
      KnowledgeBase.store_design(optimized)

      {:ok, %{program |
        status: :completed,
        design: optimized,
        validation: validation,
        manufacturing_plan: mfg_plan
      }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp extract_principles(payload) do
    principles = get_in(payload, [:result, :principles]) || []
    if is_list(principles), do: principles, else: [Map.get(payload, :result, payload)]
  end

  defp subscribe_to_inputs do
    try do
      Tiannara.CEL.Services.EventBus.subscribe("campaign.phase8a.input")
    rescue
      _ -> :ok
    end
  end

  defp schedule_engineering do
    Process.send_after(self(), :scheduled_engineering, @engineering_interval)
  end
end
