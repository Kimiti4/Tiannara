defmodule Tiannara.ASC.AutonomousDiscovery do
  @moduledoc """
  The Autonomous Discovery Engine (ADE).
  Orchestrates the scientific method across all 20 domains,
  guided by Meta-Science and grounded in the Reasoning Layer.

  B11/D-A2 vertical slice: one physics pilot cycle with explicit identity
  (mission/hypothesis/experiment/execution ids), independent structural
  validation, provenance-carrying fact persistence, rejection without
  false facts, and bounded execution. Research knowledge is not
  deployment authority.
  """

  alias Tiannara.MetaScience.PortfolioOptimizer
  alias Tiannara.MetaScience.BottleneckDetector
  alias Tiannara.Domains.CanonicalRegistry
  alias Tiannara.Observatory
  alias Tiannara.Reasoning.KnowledgeRepresentation
  alias Tiannara.Memory.Artifact
  alias Tiannara.Memory.KnowledgeStore

  @default_timeout_ms 5_000

  @doc """
  Executes one full cycle of the Autonomous Scientific Method.

  Options:
    * `:timeout_ms` — bound on simulate+validate (default #{@default_timeout_ms});
      timeout is never reported as success.
    * `:candidates` — override candidate list (tests / explicit slice runs).
  """
  @spec run_discovery_cycle(keyword()) ::
          {:ok, atom(), term()}
          | {:stalled, term()}
          | {:error, term()}
  def run_discovery_cycle(opts \\ []) do
    timeout_ms = Keyword.get(opts, :timeout_ms, @default_timeout_ms)

    with {:ok, domain_metrics} <- collect_domain_metrics(),
         {:ok, :healthy} <- BottleneckDetector.analyze_pipeline(domain_metrics),
         {:ok, candidates} <- candidate_experiments(domain_metrics, opts),
         {:ok, best_experiment} <- PortfolioOptimizer.select_next_experiment(candidates) do
      execute_experiment(best_experiment, timeout_ms: timeout_ms)
    else
      {:warning, :discovery_stall, info} ->
        Observatory.report_bottleneck(:discovery_stall, info)
        {:stalled, info}

      error ->
        Observatory.report_failure(:discovery_cycle, error)
        error
    end
  end

  @doc """
  Runs one already-shaped candidate `%{experiment: exp}` under a hard timeout.

  Returns:
    * `{:ok, :discovery_integrated, fact}` — validated fact persisted with identity + lineage
    * `{:ok, :hypothesis_rejected, counterexamples}` — contradiction recorded, no fact
    * `{:ok, :validation_unavailable, reason}` — no success-shaped conclusion
    * `{:ok, :simulation_unavailable, reason}` — no success-shaped conclusion
    * `{:ok, :experiment_timeout, timeout_ms}` — bounded execution, not success
    * `{:ok, :experiment_crashed, reason}` — bounded execution, not success
    * `{:ok, :knowledge_update_failed, reason}` — validation ok but persistence failed
  """
  @spec execute_experiment(map(), keyword()) :: {:ok, atom(), term()}
  def execute_experiment(%{experiment: exp}, opts \\ []) do
    timeout_ms = Keyword.get(opts, :timeout_ms, @default_timeout_ms)
    domain_module = exp.domain_module

    mission_id = new_id("mission")
    hypothesis_id = new_id("hyp")
    experiment_id = new_id("exp")
    execution_id = new_id("exec")

    identity = %{
      mission_id: mission_id,
      hypothesis_id: hypothesis_id,
      experiment_id: experiment_id,
      execution_id: execution_id
    }

    task =
      Task.async(fn ->
        stage_run(domain_module, exp, identity)
      end)

    # Isolate experiment crashes from the caller (bounded execution).
    Process.flag(:trap_exit, true)

    result =
      case Task.yield(task, timeout_ms) || Task.shutdown(task, :brutal_kill) do
        {:ok, {:integrated, fact}} ->
          {:ok, :discovery_integrated, fact}

        {:ok, {:rejected, counterexamples}} ->
          record_rejection(exp, identity, counterexamples)
          {:ok, :hypothesis_rejected, counterexamples}

        {:ok, {:validation_unavailable, reason}} ->
          {:ok, :validation_unavailable, reason}

        {:ok, {:simulation_unavailable, reason}} ->
          {:ok, :simulation_unavailable, reason}

        {:ok, {:knowledge_update_failed, reason}} ->
          {:ok, :knowledge_update_failed, reason}

        nil ->
          {:ok, :experiment_timeout, timeout_ms}

        {:exit, reason} ->
          {:ok, :experiment_crashed, reason}
      end

    Process.flag(:trap_exit, false)
    flush_exit_signals()
    result
  end

  defp flush_exit_signals do
    receive do
      {:EXIT, _pid, _reason} -> flush_exit_signals()
    after
      0 -> :ok
    end
  end

  defp stage_run(domain_module, exp, identity) do
    with {:ok, sim_result} <- domain_module.simulate(exp.hypothesis, exp.context),
         {:ok, validation} <- domain_module.validate(%{model: sim_result}) do
      handle_validation(exp, sim_result, validation, identity)
    else
      {:error, reason} ->
        if simulation_failed_early?(reason) do
          {:simulation_unavailable, reason}
        else
          {:validation_unavailable, reason}
        end
    end
  end

  # Physics/Calc errors before validation carry solver/stage atoms.
  defp simulation_failed_early?(reason)
       when reason in [
              :ode_solver_unavailable,
              :invalid_equation_spec,
              :invalid_initial_conditions,
              :non_finite_state,
              :dimension_mismatch,
              :simulation_unavailable,
              :no_path
            ],
       do: true

  defp simulation_failed_early?(_), do: false

  defp handle_validation(exp, sim_result, validation, identity) do
    case validation do
      %{valid: true, checks: checks} = v when is_list(checks) and checks != [] ->
        passed = Enum.count(checks, & &1.within_tolerance)
        confidence = passed / length(checks)

        if passed == length(checks) do
          persist_fact(exp, sim_result, v, confidence, identity)
        else
          {:rejected, failed_checks(checks)}
        end

      %{valid: false, checks: checks} when is_list(checks) ->
        {:rejected, failed_checks(checks)}

      %{valid: false} = v ->
        {:rejected, Map.drop(v, [:provenance])}

      %{valid: true} ->
        # valid without measurements must not produce a success-shaped fact
        {:knowledge_update_failed, :missing_measurement}

      {:error, reason} ->
        {:validation_unavailable, reason}

      other when is_map(other) ->
        if Map.has_key?(other, :valid) do
          {:knowledge_update_failed, :missing_measurement}
        else
          {:validation_unavailable, :formal_verification_unavailable}
        end

      other ->
        {:validation_unavailable, other}
    end
  end

  defp failed_checks(checks) do
    Enum.reject(checks, & &1.within_tolerance)
  end

  defp persist_fact(exp, sim_result, validation, confidence, identity) do
    provenance = Map.get(sim_result, :provenance)
    trajectory = get_in(sim_result, [:result, :trajectory]) || []

    fact = %{
      subject: exp.hypothesis.subject,
      predicate: :validates,
      object: exp.hypothesis.object,
      confidence: confidence,
      mission_id: identity.mission_id,
      hypothesis_id: identity.hypothesis_id,
      experiment_id: identity.experiment_id,
      execution_id: identity.execution_id,
      hypothesis: Map.take(exp.hypothesis, [:subject, :object, :description]),
      params: get_in(sim_result, [:result, :params]),
      evidence: %{
        trajectory_points: length(trajectory),
        method: get_in(sim_result, [:result, :method]),
        verification_method: validation.verification_method,
        invariants: validation.invariants,
        checks_passed: Enum.count(validation.checks, & &1.within_tolerance),
        checks_total: length(validation.checks)
      },
      validation: %{
        valid: validation.valid,
        verification_method: validation.verification_method,
        invariants: validation.invariants
      },
      provenance: provenance,
      lineage: [
        identity.mission_id,
        identity.hypothesis_id,
        identity.experiment_id,
        identity.execution_id
      ],
      constitutional: %{
        research_only: true,
        deployment_authority: false
      },
      asserted_at: DateTime.utc_now()
    }

    case KnowledgeRepresentation.assert_fact(
           exp.hypothesis.subject,
           :validates,
           exp.hypothesis.object,
           confidence,
           fact
         ) do
      {:ok, persisted} -> {:integrated, persisted}
      {:error, reason} -> {:knowledge_update_failed, reason}
    end
  end

  defp record_rejection(exp, identity, counterexamples) do
    rejection = %{
      outcome: :hypothesis_rejected,
      mission_id: identity.mission_id,
      hypothesis_id: identity.hypothesis_id,
      experiment_id: identity.experiment_id,
      execution_id: identity.execution_id,
      subject: exp.hypothesis[:subject],
      object: exp.hypothesis[:object],
      counterexamples: counterexamples,
      recorded_at: DateTime.utc_now()
    }

    case knowledge_store() do
      nil ->
        :ok

      store ->
        artifact =
          Artifact.new(:experiment, rejection,
            lineage: identity |> Map.values(),
            confidence: 0.0
          )

        _ = KnowledgeStore.append(store, artifact)
        :ok
    end
  end

  defp candidate_experiments(_metrics, opts) do
    case Keyword.get(opts, :candidates) do
      list when is_list(list) and list != [] ->
        {:ok, list}

      _ ->
        pilot = Tiannara.Domains.Physics.pilot_experiment()

        {:ok,
         [
           %{
             domain_module: Tiannara.Domains.Physics,
             hypothesis: pilot.hypothesis,
             context: pilot.context,
             domain_weight: 1.2
           },
           %{
             domain_module: Tiannara.Domains.Chemistry,
             hypothesis: %{
               subject: :catalyst,
               object: :reaction_rate,
               molecular_graph: %{},
               predicted_distributions: [],
               current_beliefs: []
             },
             context: %{},
             domain_weight: 0.9
           }
         ]}
    end
  end

  defp collect_domain_metrics do
    records = CanonicalRegistry.all_records()

    metrics =
      records
      |> Enum.filter(fn r -> r.module != nil end)
      |> Enum.map(fn r -> r.module.metrics() end)

    {:ok, metrics}
  end

  defp knowledge_store do
    base = Application.get_env(:tiannara, :storage_base, "./data/storage")
    path = Path.join(base, "research_facts")

    case KnowledgeStore.open(path) do
      {:ok, store} -> store
      {:error, _reason} -> nil
    end
  end

  defp new_id(prefix) do
    "#{prefix}_#{System.system_time(:nanosecond)}_#{Base.encode16(:crypto.strong_rand_bytes(6), case: :lower)}"
  end
end
