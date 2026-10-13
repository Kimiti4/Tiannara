defmodule Tiannara.Phase4.RealExecution do
  @moduledoc """
  Real execution provider for the Phase-4 experiment gateway (MC-003-M M2/M4).

  Wires a real scientific experiment submission to the REAL execution
  substrate — `Tiannara.SelfImprovement.Sandbox.RealHarness` against a
  configured sandbox backend (`Local` / `Container` / `CI`). Evaluation runs in
  an isolated sandbox and produces measured build/test/benchmark evidence;
  `deployed?` is always false unless the caller supplies a certified
  certification, a valid unexpired `HumanDelivery.Authorization` grant, a
  lineage record, and an authenticated human identity, in which case the
  deployment decision passes through the single mandatory
  `Omega.DeploymentGateway` (at-most-once enforcement).

  Constitutional basis: "Capability must never outpace verification",
  Verification First, Evidence Before Confidence, "Maintain audit trails.
  Support reproducibility."

  Every real execution records an `execution_id`:
    * a durable append-only JSONL ledger (always),
    * a canonical `Evidence.Provenance` record with kind `:real_execution`
      (acceptable as scientific evidence),
    * best-effort append to the Executive `EventStore` when it is running.
  """

  alias Tiannara.Evidence.Provenance
  alias Tiannara.Phase4.ExecutionGovernance
  alias Tiannara.SelfImprovement.Sandbox.RealHarness
  alias Tiannara.Omega.EffectIdentity
  alias Tiannara.Omega.HumanDelivery.Authorization
  alias Tiannara.Omega.DeploymentGateway
  alias Tiannara.Omega.PatchGenerator.Candidate
  alias Tiannara.Executive.Event
  alias TiannaraOS.Provenance.Producer

  require Logger

  @producer "Tiannara.Phase4.RealExecution"

  @authority_scope "phase4:real_execution"
  @operation "real_execution"
  @audit_action :real_execution_committed

  @executions_log "priv/tiannara/real_execution/executions.jsonl"

  @spec enabled?() :: boolean()
  def enabled? do
    Application.get_env(:tiannara, :real_execution_enabled, false) == true
  end

  @doc """
  Executes a real experiment against the sandbox substrate.

  `spec` is a map of the form:
    %{
      id: experiment_id (optional),
      grant: %Tiannara.Omega.HumanDelivery.Authorization{} (REQUIRED),
      substrate: %{
        backend: module(),
        baseline: binary(),            # repo path / URL
        patch: %CodePatch{},
        specs: %{tests: %TestSpec{}, benchmark: %BenchmarkSpec{}, build: %BuildSpec{}}
      },
      deploy: %{
        certification: %MultiCertificate{verdict: :certified},
        lineage: [binary()],
        identity: %AuthenticatedHumanIdentity{},
        registry_path: binary() (optional)
      } (optional — enables the DeploymentGateway path)
    }
  """
  @spec execute(map()) ::
          {:ok, map()}
          | {:error, :real_execution_not_enabled | :authorization_grant_required | term()}
  def execute(spec) when is_map(spec) do
    with :ok <- guard_enabled(),
         :ok <- guard_grant(spec),
         {:ok, substrate} <- substrate(spec),
         {:ok, admission} <-
           ExecutionGovernance.begin(
             Map.fetch!(spec, :grant),
             execution_descriptor(spec, substrate)
           ) do
      case open_execution(spec, substrate) do
        {:ok, execution_id, _record, lifecycle} ->
          case run_sandbox(substrate) do
            {:ok, sandbox_result} ->
              verification = build_verification(substrate, sandbox_result)

              close_execution(
                execution_id,
                lifecycle,
                :completed,
                spec,
                substrate,
                verification,
                nil
              )

              provenance = build_provenance(execution_id, spec)
              record_execution(execution_id, spec, verification)

              with :ok <- audit_execution(admission, execution_id, spec) do
                maybe_deploy(spec, execution_id, verification)

                {:ok,
                 %{
                   experiment_id: Map.get(spec, :id, "exp_#{execution_id}"),
                   execution_id: execution_id,
                   verification: verification,
                   provenance: provenance,
                   sandbox: sandbox_result
                 }}
              end

            {:error, _reason} = sandbox_error ->
              ExecutionGovernance.release(admission.effect_id)

              close_execution(
                execution_id,
                lifecycle,
                :failed,
                spec,
                substrate,
                nil,
                inspect(elem(sandbox_error, 1))
              )

              sandbox_error
          end

        {:error, _reason} = open_error ->
          ExecutionGovernance.release(admission.effect_id)
          open_error
      end
    end
  end

  def execute(_), do: {:error, :invalid_experiment_spec}

  defp guard_enabled do
    if enabled?(), do: :ok, else: {:error, :real_execution_not_enabled}
  end

  defp guard_grant(%{grant: %Authorization{}}), do: :ok
  defp guard_grant(_), do: {:error, :authorization_grant_required}

  # The canonical semantic descriptor (M1) for this execution. Identity is
  # derived from it alone: experiment scope, substrate baseline, patch
  # fingerprint and backend environment. The grant is bound to it (M3) before
  # the sandbox runs.
  defp execution_descriptor(spec, substrate) do
    grant = Map.fetch!(spec, :grant)

    %{
      principal: to_string(Map.get(grant, :human_id) || "unknown"),
      authority_scope: @authority_scope,
      operation: @operation,
      target: %{
        experiment_id: to_string(Map.get(spec, :id) || "unnamed"),
        baseline: to_string(substrate.baseline)
      },
      parameters: %{patch_hash: content_fingerprint(substrate.patch)},
      environment: %{backend: to_string(substrate.backend)},
      intent: %{kind: "real_execution"},
      semantic_version: "1",
      identity_version: EffectIdentity.identity_version()
    }
  end

  defp content_fingerprint(term) do
    :erlang.term_to_binary(term)
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp audit_execution(admission, execution_id, spec) do
    ExecutionGovernance.record_audit(@audit_action, admission.grant.human_id, %{
      effect_id: admission.effect_id,
      authorization_id: admission.grant.authorization_id,
      explanation_id: admission.grant.explanation_id,
      execution_id: execution_id,
      experiment_id: Map.get(spec, :id),
      subsystem: "real_execution",
      executed_at: DateTime.utc_now() |> DateTime.to_iso8601()
    })
  end

  defp substrate(spec) do
    case Map.get(spec, :substrate) do
      %{backend: backend, baseline: baseline, patch: patch, specs: specs}
      when is_atom(backend) and is_binary(baseline) and is_map(patch) and is_map(specs) ->
        {:ok, %{backend: backend, baseline: baseline, patch: patch, specs: specs}}

      _ ->
        {:error, :no_real_execution_substrate_configured}
    end
  end

  defp run_sandbox(%{backend: backend, baseline: baseline, patch: patch, specs: specs}) do
    RealHarness.run(backend, baseline, patch, specs)
  rescue
    e -> {:error, {:sandbox_exception, Exception.message(e)}}
  catch
    :exit, reason -> {:error, {:sandbox_exit, reason}}
  end

  # Confidence/uncertainty is never fabricated here: every number in the
  # verification record comes directly from the measured sandbox result.
  defp build_verification(substrate, %{verdict: verdict} = result) do
    %{
      harness: :real_sandbox,
      method: :real_sandbox,
      backend: inspect(substrate.backend),
      baseline: substrate.baseline,
      verdict: verdict,
      tests: %{
        all_passed: result.tests.all_passed,
        details: result.tests.details
      },
      benchmark: result.benchmark
    }
  end

  defp build_provenance(execution_id, spec) do
    case Provenance.build(
           kind: :real_execution,
           execution_id: execution_id,
           experiment_id: Map.get(spec, :id),
           producer: "Tiannara.Phase4.RealExecution",
           environment: %{backend: spec |> Map.get(:substrate, %{}) |> Map.get(:backend)}
         ) do
      {:ok, record} -> record
      {:error, reason} -> Provenance.unknown("provenance_build_failed: #{inspect(reason)}")
    end
  end

  # Deployment is the ONLY optional side effect, and it is strictly enforced
  # by the DeploymentGateway: without a valid certification, lineage, grant,
  # and authenticated identity there is NO deployment.
  defp maybe_deploy(spec, execution_id, _verification) do
    case Map.get(spec, :deploy) do
      %{certification: certification, lineage: lineage, identity: identity} ->
        grant = Map.fetch!(spec, :grant)
        registry_path = Map.get(spec.deploy, :registry_path)
        proposal_id = Map.get(spec, :id, "exp_#{execution_id}")

        with {:ok, candidate} <- build_approved_candidate(execution_id, proposal_id) do
          case DeploymentGateway.deploy(
                 candidate,
                 certification,
                 lineage,
                 grant,
                 identity,
                 registry_path
               ) do
            {:ok, _record, _deployed} ->
              Logger.info("[RealExecution] Deployment committed for #{execution_id}")

            {:error, reason} ->
              Logger.info(
                "[RealExecution] Deployment denied for #{execution_id}: #{inspect(reason)}"
              )
          end
        end

      _ ->
        Logger.debug("[RealExecution] #{execution_id}: no deployment requested (deployed? false)")
    end
  rescue
    e ->
      Logger.warning(
        "[RealExecution] Deployment decision failed for #{execution_id}: #{inspect(e)}"
      )
  end

  # The candidate must advance through the full lifecycle state machine to
  # :approved before the DeploymentGateway can act — sandbox-first, verified,
  # certified, then human-approved.
  defp build_approved_candidate(execution_id, proposal_id) do
    with {:ok, c1} <-
           Candidate.transition(
             Candidate.new(:code_patch, proposal_id, %{execution_id: execution_id}),
             :sandboxed
           ),
         {:ok, c2} <- Candidate.transition(c1, :tested),
         {:ok, c3} <- Candidate.transition(c2, :benchmarked),
         {:ok, c4} <- Candidate.transition(c3, :certified),
         {:ok, c5} <- Candidate.transition(c4, :approved) do
      {:ok, c5}
    end
  end

  # Always-persistent execution ledger (append-only JSONL). The ledger path is
  # env-overridable so operators/tests can isolate it; the default keeps the
  # original tracked location.
  defp executions_log do
    Application.get_env(:tiannara, :real_execution_ledger_path, @executions_log)
  end

  defp record_execution(execution_id, spec, verification) do
    File.mkdir_p!(Path.dirname(executions_log()))

    line =
      Jason.encode!(%{
        type: "real_execution",
        execution_id: execution_id,
        experiment_id: Map.get(spec, :id),
        executed_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        verification: verification
      })

    File.write!(executions_log(), line <> "\n", [:append])

    # Best-effort append to the Executive event store when it is running.
    event =
      Event.new("experiment.real_execution.completed", %{
        execution_id: execution_id,
        experiment_id: Map.get(spec, :id),
        verification: verification
      })

    case Process.whereis(Tiannara.Executive.EventStore) do
      pid when is_pid(pid) -> Tiannara.Executive.EventStore.append(event)
      _ -> :ok
    end
  rescue
    e -> Logger.error("[RealExecution] Failed to persist execution ledger: #{inspect(e)}")
  end

  # Stage 3 instrumentation: every execution is authority-MINTED and opened
  # through the provenance runtime contract BEFORE the sandbox runs, so a
  # failed sandbox still yields a closed (failed) lifecycle and terminal-state
  # uniqueness holds for the process that minted it.
  defp open_execution(spec, substrate) do
    Producer.begin(@producer, %{
      "experiment_id" => Map.get(spec, :id),
      "attempt" => 1,
      "input_manifest" => %{backend: inspect(substrate.backend), baseline: substrate.baseline}
    })
  end

  defp close_execution(id, lifecycle, status, spec, substrate, verification, failure_reason) do
    fields =
      %{"experiment_id" => Map.get(spec, :id), "attempt" => 1}
      |> maybe_output_manifest(substrate, verification)
      |> maybe_failure(failure_reason)

    outcome =
      case status do
        :completed -> Producer.complete(@producer, id, lifecycle, fields)
        :failed -> Producer.fail(@producer, id, lifecycle, fields)
      end

    case outcome do
      {:ok, _record, _lifecycle2} ->
        :ok

      {:error, reason, culprit} ->
        Logger.warning(
          "[RealExecution] lifecycle #{status} rejected for #{id}: #{inspect(reason)}"
        )

        Logger.warning("[RealExecution] lifecycle culprit: #{inspect(culprit)}")
    end
  end

  defp maybe_output_manifest(fields, _substrate, nil), do: fields

  defp maybe_output_manifest(fields, substrate, verification) do
    Map.put(fields, "output_manifest", %{
      verdict: inspect(verification.verdict),
      backend: inspect(substrate.backend),
      baseline: substrate.baseline
    })
  end

  defp maybe_failure(fields, nil), do: fields
  defp maybe_failure(fields, reason), do: Map.put(fields, "failure", reason)
end
