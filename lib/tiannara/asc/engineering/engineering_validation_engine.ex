defmodule Tiannara.ASC.Engineering.ValidationEngine do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def validate(design) do
    GenServer.call(__MODULE__, {:validate, design}, 30_000)
  end

  @impl true
  def init(_opts) do
    {:ok, %{validations: 0, passed: 0, failed: 0}}
  end

  @impl true
  def handle_call({:validate, design}, _from, state) do
    checks = [
      check_constraints(design),
      check_safety(design),
      check_manufacturability(design),
      check_performance(design),
      check_completeness(design)
    ]

    all_passed = Enum.all?(checks, & &1.passed)
    score = Enum.sum(Enum.map(checks, & &1.score)) / length(checks)

    report = %{
      design_id: Map.get(design, :id),
      passed: all_passed,
      score: score,
      checks: checks,
      validated_at: DateTime.utc_now()
    }

    new_state = %{state |
      validations: state.validations + 1,
      passed: state.passed + if(all_passed, do: 1, else: 0),
      failed: state.failed + if(all_passed, do: 0, else: 1)
    }

    {:reply, {:ok, report}, new_state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp check_constraints(design) do
    constraints = Map.get(design, :constraints, %{})
    has_constraints = map_size(constraints) > 0

    %{name: :constraints, passed: has_constraints, score: if(has_constraints, do: 1.0, else: 0.0), detail: "#{map_size(constraints)} constraints defined"}
  end

  defp check_safety(design) do
    constraints = Map.get(design, :constraints, %{})
    safety_critical = Map.get(constraints, :safety_critical, false)
    has_safety = Map.get(design, :verification_plan, %{}) |> Map.get(:safety_checks, false)

    passed = if safety_critical, do: has_safety, else: true

    %{name: :safety, passed: passed, score: if(passed, do: 1.0, else: 0.3), detail: "Safety critical: #{safety_critical}, checks: #{has_safety}"}
  end

  defp check_manufacturability(design) do
    components = Map.get(design, :components, [])
    has_components = length(components) > 0

    %{name: :manufacturability, passed: has_components, score: if(has_components, do: 0.8, else: 0.0), detail: "#{length(components)} components"}
  end

  defp check_performance(design) do
    constraints = Map.get(design, :constraints, %{})
    has_targets = Map.has_key?(constraints, :max_latency_ms) or Map.has_key?(constraints, :availability_target)

    %{name: :performance, passed: has_targets, score: if(has_targets, do: 0.9, else: 0.4), detail: "Performance targets defined: #{has_targets}"}
  end

  defp check_completeness(design) do
    required_keys = [:architecture, :components, :interfaces, :verification_plan]
    present = Enum.filter(required_keys, &Map.has_key?(design, &1))
    complete = length(present) == length(required_keys)

    %{name: :completeness, passed: complete, score: length(present) / length(required_keys), detail: "#{length(present)}/#{length(required_keys)} required sections"}
  end
end
