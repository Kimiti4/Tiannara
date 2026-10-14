defmodule Tiannara.Phase4.PhysicsPilotExecution do
  @moduledoc """
  MC-004-P: Real execution provider for the domain-physics pilot experiment.

  Runs the authorized damped-harmonic-oscillator pilot through the real RK4
  integrator and records the execution as a genuine, human-authorized experiment
  with `:real_execution` provenance — distinct from the earlier `:simulation`
  provenance used during the MC-004-M mutation gate.

  Evidence written on every successful execution:
    * a durable append-only JSONL ledger (path configurable via
      `:real_execution_ledger_path`; default
      `priv/tiannara/real_execution/executions.jsonl`),
    * a `Evidence.Provenance` record with `kind: :real_execution`,
    * best-effort append to the Executive EventStore (when running).

  This module parallels `Tiannara.Phase4.RealExecution` but is purpose-built for
  domain-simulation pilots: no code-patch sandbox, no `RealHarness`, no
  deployment gateway. The simulation *is* the experiment.

  Constitutional basis: "Capability must never outpace verification",
  "Evidence Before Confidence", "Maintain audit trails".
  """

  alias Tiannara.Evidence.Provenance
  alias Tiannara.Phase4.ExecutionGovernance
  alias Tiannara.Omega.EffectIdentity
  alias Tiannara.Omega.HumanDelivery.Authorization
  alias Tiannara.Executive.Event

  require Logger

  @authority_scope "phase4:physics_pilot"
  @operation "physics_pilot_execution"
  @audit_action :physics_pilot_executed

  @executions_log "priv/tiannara/real_execution/executions.jsonl"

  # The ledger path is env-overridable so operators/tests can isolate it; the
  # default keeps the original tracked location.
  defp executions_log do
    Application.get_env(:tiannara, :real_execution_ledger_path, @executions_log)
  end

  @doc """
  Executes the physics pilot as a real, authorized experiment.

  `spec` is a map of the form:
    %{
      grant: %Authorization{status: :granted},     # REQUIRED
      pilot: %{hypothesis: map, context: map}       # optional — defaults to pilot_experiment()
    }

  Returns `{:ok, %{execution_id, verification, provenance, simulation}}` on success.
  """
  @spec execute(map()) :: {:ok, map()} | {:error, term()}
  def execute(spec) when is_map(spec) do
    with :ok <- guard_enabled(),
         :ok <- guard_grant(Map.get(spec, :grant)),
         pilot = Map.get(spec, :pilot, pilot_default()),
         {:ok, admission} <-
           ExecutionGovernance.begin(spec.grant, execution_descriptor(spec.grant, pilot)) do
      case run_and_record(pilot) do
        {:ok, result} ->
          audit_execution(admission, result)

        {:error, {:post_effect_failure, reason}} ->
          # The simulation (the effect) already ran. Provenance/ledger
          # persistence failed: fail closed — keep the claim consumed
          # (M6/M8 semantics) and report the evidence failure.
          {:error, reason}

        {:error, _reason} = execution_error ->
          ExecutionGovernance.release(admission.effect_id)
          execution_error
      end
    end
  end

  def execute(_), do: {:error, :invalid_experiment_spec}

  # The canonical semantic descriptor (M1) for this pilot run: fixed experiment
  # scope, RK4 environment, and the hypothesis/context fingerprints that make
  # two runs distinct effects (D165 §6: distinct input = distinct identity).
  defp execution_descriptor(grant, pilot) do
    %{
      principal: to_string(Map.get(grant, :human_id) || "unknown"),
      authority_scope: @authority_scope,
      operation: @operation,
      target: %{experiment_id: "mc004-p-pilot"},
      parameters: %{
        hypothesis_hash: content_fingerprint(pilot.hypothesis),
        context_hash: content_fingerprint(pilot.context)
      },
      environment: %{method: "rk4"},
      intent: %{kind: "physics_pilot_execution"},
      semantic_version: "1",
      identity_version: EffectIdentity.identity_version()
    }
  end

  defp content_fingerprint(term) do
    :erlang.term_to_binary(term)
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp run_and_record(pilot) do
    with {:ok, simulation} <- run_simulation(pilot),
         {:ok, validation} <- run_validation(simulation) do
      execution_id = make_execution_id()
      verification = build_verification(execution_id, simulation, validation)

      # Post-effect boundary: the simulation has run. Failures from here on
      # are tagged :post_effect_failure so the caller does not release the
      # grant claim — the effect happened even though evidence may not persist.
      with {:ok, provenance} <- build_provenance(execution_id),
           :ok <- record_execution(execution_id, verification, provenance) do
        {:ok,
         %{
           execution_id: execution_id,
           verification: verification,
           provenance: provenance,
           simulation: simulation
         }}
      else
        {:error, reason} -> {:error, {:post_effect_failure, reason}}
      end
    end
  end

  # Audit edge (M8): fail-closed — an execution whose audit cannot be appended
  # is reported as an error with execution_recorded: true (effect happened).
  defp audit_execution(admission, result) do
    case ExecutionGovernance.record_audit(@audit_action, admission.grant.human_id, %{
           effect_id: admission.effect_id,
           authorization_id: admission.grant.authorization_id,
           explanation_id: admission.grant.explanation_id,
           execution_id: result.execution_id,
           subsystem: "physics_pilot",
           executed_at: DateTime.utc_now() |> DateTime.to_iso8601()
         }) do
      :ok -> {:ok, Map.put(result, :effect_id, admission.effect_id)}
      {:error, _reason} = audit_error -> audit_error
    end
  end

  # --- guards ---

  defp guard_enabled do
    if Tiannara.Phase4.RealExecution.enabled?(),
      do: :ok,
      else: {:error, :real_execution_not_enabled}
  end

  defp guard_grant(%Authorization{status: :granted} = grant) do
    if Authorization.expired?(grant) do
      {:error, :grant_expired}
    else
      :ok
    end
  end

  defp guard_grant(%Authorization{}), do: {:error, :authorization_grant_denied}
  defp guard_grant(_), do: {:error, :authorization_grant_required}

  # --- simulation ---

  defp run_simulation(pilot) do
    Tiannara.Domains.Physics.simulate(pilot.hypothesis, pilot.context)
  end

  defp run_validation(simulation) do
    Tiannara.Domains.Physics.validate(%{model: simulation})
  end

  # --- evidence ---

  defp build_verification(execution_id, simulation, validation) do
    result = simulation.result

    %{
      harness: :real_simulation,
      method: :rk4,
      order: result.order,
      steps: result.steps,
      dt: result.dt,
      trajectory_length: length(result.trajectory),
      initial_state: result.initial_state,
      final_state: result.final_state,
      validation: validation,
      execution_id: execution_id
    }
  end

  defp build_provenance(execution_id) do
    case Provenance.build(
           kind: :real_execution,
           execution_id: execution_id,
           producer: "Tiannara.Phase4.PhysicsPilotExecution",
           environment: %{method: :rk4, model: :damped_harmonic_oscillator}
         ) do
      {:ok, record} ->
        {:ok, record}

      {:error, reason} ->
        {:error, {:provenance_build_failed, reason}}
    end
  end

  # --- persistence ---

  defp record_execution(execution_id, verification, provenance) do
    with :ok <- persist_ledger_line(execution_id, verification, provenance) do
      append_event(execution_id, verification, provenance)
      :ok
    end
  end

  # Fail-closed: a ledger write failure aborts the execution report. The
  # computation happened (post-effect), so the caller must not release the
  # grant claim, but a success must never be reported without durable evidence.
  defp persist_ledger_line(execution_id, verification, provenance) do
    path = executions_log()
    File.mkdir_p!(Path.dirname(path))

    line =
      Jason.encode!(%{
        type: "real_execution",
        subsystem: "physics_pilot",
        execution_id: execution_id,
        executed_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        verification: Map.drop(verification, [:validation]),
        provenance: provenance
      })

    File.write!(path, line <> "\n", [:append])
    :ok
  rescue
    e ->
      Logger.error("[PhysicsPilotExecution] Execution ledger write failed: #{Exception.message(e)}")
      {:error, {:execution_ledger_write_failed, Exception.message(e)}}
  end

  # Best-effort secondary sink (per moduledoc): the JSONL ledger is canonical.
  defp append_event(execution_id, verification, provenance) do
    event =
      Event.new("experiment.real_execution.completed", %{
        execution_id: execution_id,
        subsystem: "physics_pilot",
        verification: verification,
        provenance: provenance
      })

    case Process.whereis(Tiannara.Executive.EventStore) do
      pid when is_pid(pid) ->
        Tiannara.Executive.EventStore.append(event)

      _ ->
        Logger.warning(
          "[PhysicsPilotExecution] Executive EventStore not running; event not appended (JSONL ledger is canonical evidence)"
        )
    end

    :ok
  rescue
    e ->
      Logger.error(
        "[PhysicsPilotExecution] EventStore append failed (ledger already durable): #{Exception.message(e)}"
      )

      :ok
  end

  # --- helpers ---

  defp make_execution_id do
    "pilot_#{DateTime.utc_now() |> DateTime.to_unix()}_#{System.unique_integer([:positive])}"
  end

  defp pilot_default, do: Tiannara.Domains.Physics.pilot_experiment()
end
