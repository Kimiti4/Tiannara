defmodule ObservatoryState.Reconciliation do
  use GenServer

  @interval :timer.minutes(15)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def status do
    GenServer.call(__MODULE__, :status)
  end

  def reconcile_now do
    GenServer.cast(__MODULE__, :reconcile)
  end

  @impl true
  def init(_opts) do
    schedule()
    {:ok, %{last_reconciliation: nil, last_status: :pending, checks: %{}}}
  end

  @impl true
  def handle_info(:reconcile, state) do
    checks = %{
      runtime: check_table(:obs_runtime_state),
      scientific: check_table(:obs_scientific_state),
      engineering: check_table(:obs_engineering_state),
      knowledge: check_table(:obs_knowledge_state),
      planetary: check_table(:obs_planetary_state),
      civilization: check_table(:obs_civilization_state),
      evolution: check_table(:obs_evolution_state),
      governance: check_table(:obs_governance_state),
      certification: check_table(:obs_certification_state)
    }

    all_healthy = Enum.all?(checks, fn {_, v} -> v.status == :healthy end)
    schedule()

    {:noreply,
     %{
       state
       | last_reconciliation: DateTime.utc_now(),
         last_status: if(all_healthy, do: :healthy, else: :diverged),
         checks: checks
     }}
  end

  @impl true
  def handle_cast(:reconcile, state) do
    send(self(), :reconcile)
    {:noreply, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply,
     %{
       last_reconciliation: state.last_reconciliation,
       status: state.last_status,
       checks: state.checks,
       healthy: state.last_status == :healthy
     }, state}
  end

  defp schedule do
    Process.send_after(self(), :reconcile, @interval)
  end

  defp check_table(table_name) do
    try do
      case :ets.info(table_name) do
        :undefined ->
          %{status: :missing_table, table: table_name, size: 0}

        info when is_list(info) ->
          size = info[:size] || 0

          if size > 0 do
            sample = :ets.tab2list(table_name) |> Enum.take(1)
            checksum = :erlang.md5(:erlang.term_to_binary(sample))

            %{
              status: :healthy,
              table: table_name,
              size: size,
              checksum: Base.encode16(checksum, case: :lower)
            }
          else
            %{status: :healthy, table: table_name, size: 0}
          end
      end
    rescue
      _ -> %{status: :error, table: table_name, error: "ETS access failed"}
    end
  end
end
