defmodule MetricsEngine.AlertEngine do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def register_rule(name, rule_fn, severity \\ :info) do
    GenServer.cast(__MODULE__, {:register, name, rule_fn, severity})
  end

  def evaluate(context) do
    GenServer.call(__MODULE__, {:evaluate, context})
  end

  def alerts(opts \\ []) do
    GenServer.call(__MODULE__, {:alerts, opts})
  end

  @impl true
  def init(_opts) do
    {:ok, %{rules: %{}, alerts: :queue.new(), alert_count: 0}}
  end

  @impl true
  def handle_cast({:register, name, rule_fn, severity}, %{rules: r} = state) do
    {:noreply,
     %{state | rules: Map.put(r, name, %{name: name, rule: rule_fn, severity: severity})}}
  end

  @impl true
  def handle_call({:evaluate, context}, _from, %{rules: rules, alerts: q, alert_count: c} = state) do
    triggered =
      Enum.reduce(rules, [], fn {_name, rule}, acc ->
        case rule.rule.(context) do
          true ->
            alert = %{
              id: Ecto.UUID.generate(),
              rule: rule.name,
              severity: rule.severity,
              timestamp: DateTime.utc_now(),
              context: context
            }

            [alert | acc]

          false ->
            acc
        end
      end)

    updated_q = Enum.reduce(triggered, q, fn alert, acc -> :queue.in(alert, acc) end)
    {:reply, triggered, %{state | alerts: updated_q, alert_count: c + length(triggered)}}
  end

  @impl true
  def handle_call({:alerts, _opts}, _from, %{alerts: q} = state) do
    {:reply, :queue.to_list(q) |> Enum.reverse(), state}
  end
end
