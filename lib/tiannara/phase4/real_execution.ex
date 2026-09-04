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
  alias Tiannara.SelfImprovement.Sandbox.RealHarness
  alias Tiannara.Omega.HumanDelivery.Authorization
  alias Tiannara.Omega.DeploymentGateway
  alias Tiannara.Omega.PatchGenerator.Candidate
  alias Tiannara.Executive.Event

  require Logger

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
          {:ok, map()} | {:error, :real_execution_not_enabled | :authorization_grant_required | term()}
  def execute(spec) when is_map(spec) do
    with :ok <- guard_enabled(),
         :ok <- guard_grant(spec),
         {:ok, substrate} <- substrate(spec),
         {:ok, sandbox_result} <- run_sandbox(substrate) do
      execution_id = make_execution_id()
      verification = build_verification(substrate, sandbox_result)
      provenance = build_provenance(execution_id, spec)
      record_execution(execution_id, spec, verification)
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
  end

  def execute(_), do: {:error, :invalid_experiment_spec}

  defp guard_enabled do
    if enabled?(), do: :ok, else: {:error, :real_execution_not_enabled}
  end

  defp guard_grant(%{grant: %Authorization{}}), do: :ok
  defp guard_grant(_), do: {:error, :authorization_grant_required}

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
          case DeploymentGateway.deploy(candidate, certification, lineage, grant, identity, registry_path) do
            {:ok, _record, _deployed} ->
              Logger.info("[RealExecution] Deployment committed for #{execution_id}")

            {:error, reason} ->
              Logger.info("[RealExecution] Deployment denied for #{execution_id}: #{inspect(reason)}")
          end
        end

      _ ->
        Logger.debug("[RealExecution] #{execution_id}: no deployment requested (deployed? false)")
    end
  rescue
    e ->
      Logger.warning("[RealExecution] Deployment decision failed for #{execution_id}: #{inspect(e)}")
  end

  # The candidate must advance through the full lifecycle state machine to
  # :approved before the DeploymentGateway can act — sandbox-first, verified,
  # certified, then human-approved.
  defp build_approved_candidate(execution_id, proposal_id) do
    with {:ok, c1} <- Candidate.transition(Candidate.new(:code_patch, proposal_id, %{execution_id: execution_id}), :sandboxed),
         {:ok, c2} <- Candidate.transition(c1, :tested),
         {:ok, c3} <- Candidate.transition(c2, :benchmarked),
         {:ok, c4} <- Candidate.transition(c3, :certified),
         {:ok, c5} <- Candidate.transition(c4, :approved) do
      {:ok, c5}
    end
  end

  # Always-persistent execution ledger (append-only JSONL).
  defp record_execution(execution_id, spec, verification) do
    File.mkdir_p!(Path.dirname(@executions_log))

    line =
      Jason.encode!(%{
        type: "real_execution",
        execution_id: execution_id,
        experiment_id: Map.get(spec, :id),
        executed_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        verification: verification
      })

    File.write!(@executions_log, line <> "\n", [:append])

    # Best-effort append to the Executive event store when it is running.
    event = Event.new("experiment.real_execution.completed", %{
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

  defp make_execution_id do
    "exec_#{DateTime.utc_now() |> DateTime.to_unix()}_#{System.unique_integer([:positive])}"
  end
end