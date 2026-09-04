defmodule Tiannara.ASC.Engineering.ManufacturingPlanner do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def plan(design) do
    GenServer.call(__MODULE__, {:plan, design}, 30_000)
  end

  @impl true
  def init(_opts) do
    {:ok, %{plans_generated: 0}}
  end

  @impl true
  def handle_call({:plan, design}, _from, state) do
    mfg_plan = %{
      design_id: Map.get(design, :id),
      bom: generate_bom(design),
      assembly_sequence: generate_assembly_sequence(design),
      tooling: generate_tooling(design),
      cost_estimate: estimate_cost(design),
      lead_time_weeks: estimate_lead_time(design),
      quality_control: generate_qc_plan(design),
      generated_at: DateTime.utc_now()
    }

    {:reply, {:ok, mfg_plan}, %{state | plans_generated: state.plans_generated + 1}}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp generate_bom(design) do
    components = Map.get(design, :components, [])

    Enum.map(components, fn comp ->
      %{
        reference: comp.id,
        description: comp.name,
        quantity: 1,
        unit_cost: 10.0,
        lead_time_days: 14
      }
    end)
  end

  defp generate_assembly_sequence(design) do
    [
      %{step: 1, operation: "Prepare enclosure", duration_min: 10},
      %{step: 2, operation: "Mount PCB", duration_min: 15},
      %{step: 3, operation: "Connect wiring", duration_min: 20},
      %{step: 4, operation: "Functional test", duration_min: 30},
      %{step: 5, operation: "Close and seal", duration_min: 10},
      %{step: 6, operation: "Final inspection", duration_min: 15}
    ]
  end

  defp generate_tooling(design) do
    [
      %{name: "Screwdriver set", type: :hand_tool, cost: 50},
      %{name: "Soldering station", type: :bench_tool, cost: 200},
      %{name: "Test fixture", type: :custom, cost: 500}
    ]
  end

  defp estimate_cost(design) do
    components = Map.get(design, :components, [])
    component_count = length(components)

    %{
      materials: component_count * 10.0,
      labor: component_count * 5.0 * 0.5,
      tooling_amortized: 50.0,
      testing: 25.0,
      overhead: component_count * 3.0,
      total: component_count * 18.0 + 75.0
    }
  end

  defp estimate_lead_time(design) do
    %{
      procurement_weeks: 2,
      assembly_weeks: 1,
      testing_weeks: 1,
      total_weeks: 4
    }
  end

  defp generate_qc_plan(design) do
    %{
      incoming_inspection: true,
      in_process_checks: [%{step: 4, check: "Functional test"}],
      final_inspection: true,
      sampling: :aql_1_0,
      documentation: :full_traceability
    }
  end
end
