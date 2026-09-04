defmodule Tiannara.ASC.Engineering.DigitalTwinManager do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def create_twin(design) do
    GenServer.call(__MODULE__, {:create, design}, 30_000)
  end

  def simulate(twin_id, scenario) do
    GenServer.call(__MODULE__, {:simulate, twin_id, scenario}, 30_000)
  end

  def twins, do: GenServer.call(__MODULE__, :twins)

  @impl true
  def init(_opts) do
    {:ok, %{twins: %{}, simulations: 0}}
  end

  @impl true
  def handle_call({:create, design}, _from, state) do
    twin_id = "twin_#{:crypto.strong_rand_bytes(6) |> Base.encode16(case: :lower)}"

    twin = %{
      id: twin_id,
      design_id: Map.get(design, :id),
      name: "Twin: #{Map.get(design, :name, "unnamed")}",
      state: :nominal,
      parameters: extract_parameters(design),
      history: [],
      created_at: DateTime.utc_now()
    }

    {:reply, {:ok, twin_id}, put_in(state.twins[twin_id], twin)}
  end

  @impl true
  def handle_call({:simulate, twin_id, scenario}, _from, state) do
    case Map.fetch(state.twins, twin_id) do
      {:ok, twin} ->
        result = run_simulation(twin, scenario)

        updated_twin = %{twin |
          state: result.predicted_state,
          history: [result | twin.history] |> Enum.take(100)
        }

        {:reply, {:ok, result}, %{state |
          twins: Map.put(state.twins, twin_id, updated_twin),
          simulations: state.simulations + 1
        }}

      :error ->
        {:reply, {:error, :twin_not_found}, state}
    end
  end

  @impl true
  def handle_call(:twins, _from, state) do
    {:reply, Map.values(state.twins), state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp extract_parameters(design) do
    constraints = Map.get(design, :constraints, %{})

    %{
      max_latency_ms: Map.get(constraints, :max_latency_ms, 1000),
      max_memory_mb: Map.get(constraints, :max_memory_mb, 512),
      availability: Map.get(constraints, :availability_target, 0.99),
      component_count: length(Map.get(design, :components, []))
    }
  end

  defp run_simulation(twin, scenario) do
    load_factor = Map.get(scenario, :load_factor, 1.0)
    duration_hours = Map.get(scenario, :duration_hours, 24)

    predicted_latency = twin.parameters.max_latency_ms * load_factor * 0.7
    predicted_memory = twin.parameters.max_memory_mb * load_factor * 0.6
    predicted_availability = max(0.9, twin.parameters.availability - (load_factor - 1.0) * 0.05)

    %{
      scenario: scenario,
      predicted_state: if(predicted_latency < twin.parameters.max_latency_ms, do: :nominal, else: :degraded),
      predicted_latency_ms: predicted_latency,
      predicted_memory_mb: predicted_memory,
      predicted_availability: predicted_availability,
      duration_hours: duration_hours,
      at: DateTime.utc_now()
    }
  end
end
