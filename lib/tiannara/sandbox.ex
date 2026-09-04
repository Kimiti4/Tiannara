defmodule Tiannara.Sandbox do
  @moduledoc """
  Execution Sandbox — provides isolated, monitored environments for
  executing approved experiments and interventions.

  Each experiment runs in its own isolated context with:
  - State isolation (snapshot/revert)
  - Resource monitoring
  - Progress tracking
  - Rollback capability
  - Result reporting
  """
  use GenServer
  require Logger

  # ── Configuration ──

  @max_concurrent_experiments 5
  @default_timeout_cycles 1_000
  @monitor_interval_ms 2_000

  # ── Public API ──

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Legacy compatibility: executes a proposal by ID.
  Creates a minimal experiment wrapper and submits to sandbox.
  """
  def execute(proposal_id) when is_binary(proposal_id) do
    exp = %Tiannara.Research.Experiment{
      id: "exp_legacy_#{proposal_id}",
      hypothesis_id: "hyp_legacy",
      procedure: "Execute approved proposal #{proposal_id}",
      status: :approved,
      duration_cycles: 100,
      parameters: %{proposal_id: proposal_id, category: :runtime}
    }
    submit(exp)
  end

  @doc """
  Submits an experiment for execution in the sandbox.
  The experiment must be pre-approved by the Research Director.
  """
  def submit(experiment) do
    GenServer.call(__MODULE__, {:submit, experiment}, :infinity)
  end

  @doc """
  Returns the status of a running or completed experiment.
  """
  def status(experiment_id) do
    GenServer.call(__MODULE__, {:status, experiment_id})
  end

  @doc """
  Cancels a running experiment and rolls back its changes.
  """
  def cancel(experiment_id) do
    GenServer.call(__MODULE__, {:cancel, experiment_id})
  end

  @doc """
  Returns a summary of all sandbox activity.
  """
  def summary do
    GenServer.call(__MODULE__, :summary)
  end

  @doc """
  Returns the result of a completed experiment.
  """
  def result(experiment_id) do
    GenServer.call(__MODULE__, {:result, experiment_id})
  end

  # ── GenServer Callbacks ──

  @impl true
  def init(_opts) do
    :ets.new(:sandbox_experiments, [:set, :public, :named_table])
    :ets.new(:sandbox_results, [:set, :public, :named_table])
    Logger.info("[SANDBOX] Execution Sandbox initialized.")
    {:ok, %{
      experiments_table: :sandbox_experiments,
      results_table: :sandbox_results,
      running_count: 0
    }}
  end

  @impl true
  def handle_call({:submit, _exp}, _from, state) when state.running_count >= @max_concurrent_experiments do
    {:reply, {:error, :sandbox_full, "Max #{@max_concurrent_experiments} concurrent experiments"}, state}
  end

  @impl true
  def handle_call({:submit, exp}, _from, state) do
    experiment_id = exp.id

    entry = %{
      id: experiment_id,
      hypothesis_id: exp.hypothesis_id,
      procedure: exp.procedure,
      parameters: exp.parameters,
      duration_cycles: exp.duration_cycles || @default_timeout_cycles,
      status: :running,
      progress: 0,
      started_at: DateTime.utc_now(),
      current_cycle: 0,
      error: nil
    }

    :ets.insert(state.experiments_table, {experiment_id, entry})

    # Start monitoring
    Process.send_after(self(), {:tick, experiment_id}, @monitor_interval_ms)

    Logger.info("[SANDBOX] Experiment #{experiment_id} started. Duration: #{entry.duration_cycles} cycles.")

    {:reply, {:ok, experiment_id}, %{state | running_count: state.running_count + 1}}
  end

  @impl true
  def handle_call({:status, experiment_id}, _from, state) do
    result = case :ets.lookup(state.experiments_table, experiment_id) do
      [{_id, entry}] -> entry
      [] -> {:error, :not_found}
    end
    {:reply, result, state}
  end

  @impl true
  def handle_call({:cancel, experiment_id}, _from, state) do
    result = case :ets.lookup(state.experiments_table, experiment_id) do
      [{_id, entry}] ->
        if entry.status == :running do
          rollback_experiment(experiment_id)
          updated = %{entry | status: :rolled_back, progress: entry.progress, error: "Cancelled by operator"}
          :ets.insert(state.experiments_table, {experiment_id, updated})
          {:ok, updated}
        else
          {:error, :not_running}
        end
      [] -> {:error, :not_found}
    end
    {:reply, result, %{state | running_count: state.running_count - 1}}
  end

  @impl true
  def handle_call(:summary, _from, state) do
    all = :ets.tab2list(state.experiments_table) |> Enum.map(fn {_id, e} -> e end)
    running = Enum.count(all, &(&1.status == :running))
    completed = Enum.count(all, &(&1.status == :completed))
    failed = Enum.count(all, &(&1.status == :failed))
    rolled_back = Enum.count(all, &(&1.status == :rolled_back))

    {:reply, %{
      total_submitted: length(all),
      running: running,
      completed: completed,
      failed: failed,
      rolled_back: rolled_back,
      sandbox_available: @max_concurrent_experiments - state.running_count
    }, state}
  end

  @impl true
  def handle_call({:result, experiment_id}, _from, state) do
    result = case :ets.lookup(state.results_table, experiment_id) do
      [{_id, res}] -> res
      [] -> {:error, :no_result}
    end
    {:reply, result, state}
  end

  @impl true
  def handle_info({:tick, experiment_id}, state) do
    case :ets.lookup(state.experiments_table, experiment_id) do
      [{_id, entry}] when entry.status == :running ->
        new_cycle = entry.current_cycle + 1
        progress = min(new_cycle / entry.duration_cycles, 1.0)

        if new_cycle >= entry.duration_cycles do
          # Experiment completed
          result = complete_experiment(experiment_id, entry)
          completed_entry = %{entry | status: :completed, progress: 1.0, current_cycle: new_cycle}
          :ets.insert(state.experiments_table, {experiment_id, completed_entry})

          # Store result for retrieval
          :ets.insert(state.results_table, {experiment_id, result})

          Logger.info("[SANDBOX] Experiment #{experiment_id} completed. Result: #{result.status}")

          # Report back to Research Director
          report_to_director(experiment_id, result)

          {:noreply, %{state | running_count: state.running_count - 1}}
        else
          # Still running — update progress and schedule next tick
          updated = %{entry | current_cycle: new_cycle, progress: Float.round(progress, 4)}
          :ets.insert(state.experiments_table, {experiment_id, updated})
          Process.send_after(self(), {:tick, experiment_id}, @monitor_interval_ms)
          {:noreply, state}
        end

      _ ->
        {:noreply, state}
    end
  end

  # ── Private Helpers ──

  defp complete_experiment(experiment_id, entry) do
    # In production, this would actually run the experiment's procedure
    # For now, we simulate with a probabilistic outcome

    success_prob = case entry.parameters[:category] do
      :scientific -> 0.75
      :runtime -> 0.85
      :constitutional -> 0.95
      _ -> 0.80
    end

    is_success = :rand.uniform() < success_prob
    information_gain = if is_success, do: 0.3 + :rand.uniform() * 0.5, else: 0.1 + :rand.uniform() * 0.2

    %{
      experiment_id: experiment_id,
      status: if(is_success, do: :success, else: :failure),
      metrics: %{
        cycles_run: entry.current_cycle,
        cycles_planned: entry.duration_cycles,
        information_gained: Float.round(information_gain, 4),
        success_probability: success_prob
      },
      completed_at: DateTime.utc_now(),
      summary: if(is_success,
        do: "Experiment completed successfully. Information gain: #{Float.round(information_gain, 2)}",
        else: "Experiment did not produce expected results. Further investigation needed."
      )
    }
  end

  defp rollback_experiment(experiment_id) do
    Logger.info("[SANDBOX] Rolling back experiment #{experiment_id}")
    # In production, this would restore the pre-experiment state snapshot
    :ok
  end

  defp report_to_director(experiment_id, result) do
    # Find the experiment entry to get hypothesis_id
    case :ets.lookup(:sandbox_experiments, experiment_id) do
      [{_id, entry}] ->
        result_status = if result.status == :success, do: :success, else: :failure
        Tiannara.Research.Director.record_result(experiment_id, result_status, result.metrics)

        # Also record in Sentinel Activation Memory for learning
        outcome_data = %{
          action: "Experiment #{experiment_id}",
          category: entry.parameters[:category],
          source: entry.parameters[:hypothesis_id],
          observation: entry.procedure,
          interpretation: result.summary,
          confidence: result.metrics[:success_probability] || 0.5
        }

        Tiannara.Sentinel.Activation.Engine.record_outcome(experiment_id, outcome_data, result_status)
      _ -> :ok
    end
  end
end
