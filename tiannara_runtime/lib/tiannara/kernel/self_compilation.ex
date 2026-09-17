defmodule Tiannara.Kernel.SelfCompilation do
  @moduledoc """
  5F.13: Recursive Self-Compilation Kernel.

  Allows OMCE, OLEF, HSV, CTL, OCM, TWP, OSL, NDE, RRG to evolve
  their operational rules at runtime while strictly preserving core stability invariants.
  """

  use GenServer
  require Logger

  alias Tiannara.Kernel.{RuleExtractor, MutationEngine, ValidationGate, DeploymentOrchestrator}

  @default_interval_ms 300_000 # 5 minutes
  @max_mutation_depth 3

  # ==================== Public API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Query current active rules"
  @spec active_rules() :: map()
  def active_rules do
    GenServer.call(__MODULE__, :active_rules)
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(opts) do
    interval = Keyword.get(opts, :compilation_interval_ms, @default_interval_ms)

    state = %{
      compilation_cycle: 0,
      active_rules: load_base_rules(),
      mutation_history: [],
      stability_threshold: Keyword.get(opts, :stability_threshold, 0.30),
      conn_name: opts[:connection_name] || :tiannara_nats,
      interval: interval,
      compilation_success_history: []
    }

    schedule_compilation(interval)
    {:ok, state}
  end

  @impl true
  def handle_info(:compile_cycle, state) do
    if state.compilation_cycle >= @max_mutation_depth do
      Logger.info("🔁 Self-compilation: Max mutation depth reached. Pausing evolution.")
      schedule_compilation(state.interval)
      {:noreply, %{state | compilation_cycle: 0}}
    else
      case execute_compilation_cycle(state) do
        {:ok, new_state} ->
          schedule_compilation(state.interval)
          updated_history = Enum.take([:success | state.compilation_success_history], 10)
          {:noreply, %{new_state | compilation_success_history: updated_history}}

        {:error, reason} ->
          Logger.error("❌ Self-compilation failed: #{reason}")
          schedule_compilation(state.interval)
          updated_history = Enum.take([:failure | state.compilation_success_history], 10)
          {:noreply, %{state | compilation_success_history: updated_history}}
      end
    end
  end

  @impl true
  def handle_call(:active_rules, _from, state) do
    {:reply, state.active_rules, state}
  end

  @impl true
  def handle_call(:reset, _from, state) do
    {:reply, :ok, %{state | compilation_cycle: 0, active_rules: load_base_rules(), mutation_history: [], compilation_success_history: []}}
  end

  @impl true
  def handle_cast(:reset, state) do
    {:noreply, %{state | compilation_cycle: 0, active_rules: load_base_rules(), mutation_history: [], compilation_success_history: []}}
  end

  # ==================== Helper Functions ====================

  defp schedule_compilation(interval) do
    Process.send_after(self(), :compile_cycle, interval)
  end

  defp execute_compilation_cycle(state) do
    modifier = compute_mutation_modifier(state.compilation_success_history)

    with {:ok, current_rules} <- RuleExtractor.extract(state.active_rules),
         {:ok, candidate_mutations} <- MutationEngine.generate(current_rules, state.compilation_cycle, modifier: modifier),
         {:ok, validated_rules} <- ValidationGate.verify(candidate_mutations, state.stability_threshold),
         {:ok, deployed} <- DeploymentOrchestrator.hot_swap(validated_rules, state.conn_name) do

      Logger.info("✅ Self-compilation cycle #{state.compilation_cycle + 1} complete")

      new_state = %{
        state
        | active_rules: deployed,
          compilation_cycle: state.compilation_cycle + 1,
          mutation_history: [{state.compilation_cycle, deployed} | Enum.take(state.mutation_history, 99)]
      }

      {:ok, new_state}
    end
  end

  defp compute_mutation_modifier([]), do: 1.0
  defp compute_mutation_modifier(history) do
    successes = Enum.count(history, &(&1 == :success))
    max(0.1, successes / length(history))
  end

  defp load_base_rules do
    %{
      omce: %{compression_strategy: :adaptive, threshold: 0.7},
      olef: %{diffusion_rate: 0.05, pressure_cap: 1.0},
      hsv: %{curvature_threshold: 12.0, archive_retention_ms: 86_400_000},
      ctl: %{stress_threshold: 0.75, reconciliation_budget: 100.0},
      ocm: %{semantic_drift_limit: 0.40},
      twp: %{prune_threshold: 0.35},
      osl: %{recursion_limit: 4},
      nde: %{novelty_intensity: 0.15},
      rrg: %{psi_bound: 0.30}
    }
  end
end
