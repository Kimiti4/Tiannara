defmodule Tiannara.Integration.ReportGenerator do
  @moduledoc """
  Generates final reports with RecoveryCertificate integration.
  """

  alias Tiannara.Soak.RecoveryCertificate
  alias Tiannara.Soak.TimeAccounting
  alias Tiannara.Integration.{Repro.Manifest, ViewModel, Console}

  def generate(paths, opts \\ []) do
    ctx = Tiannara.Integration.RunContext.load(paths)

    run_start = Keyword.fetch!(opts, :run_start)
    run_end = Keyword.fetch!(opts, :run_end)
    experiment_id = Keyword.get(opts, :experiment_id, paths.run_id)
    restarted? = Keyword.get(opts, :restarted?, false)

    time = TimeAccounting.compute(run_end, run_start, ctx.validated_seconds, restarted?: restarted?)

    cert = Keyword.get(opts, :recovery_certificate) || ctx.recovery_certificate

    manifest_base = Manifest.capture(experiment_id, Keyword.get(opts, :manifest_overrides, []))

    {recovery_verified, manifest} =
      case cert do
        %RecoveryCertificate{} = c ->
          {c.all_passed, Manifest.with_recovery_certificate(manifest_base, c, time)}

        _ ->
          {ctx.gate_verdict == :gate_open, Manifest.with_recovery(manifest_base, ctx.gate_verdict, time)}
      end

    manifest = Map.put(manifest, :results, ctx.results_summary)

    view_model =
      ViewModel.build(
        funnel: ctx.funnel,
        manifest: manifest,
        observatory: ctx.observatory,
        knowledge: ctx.knowledge
      )

    dashboard = Console.render(view_model)
    {grade, reasons} = grade(ctx, recovery_verified)

    %Tiannara.Integration.FinalReport{
      run_id: paths.run_id,
      experiment_id: experiment_id,
      grade: grade,
      grade_reasons: reasons,
      manifest: manifest,
      view_model: view_model,
      dashboard_text: dashboard,
      machine_summary: machine_summary(ctx, time, grade, recovery_verified, cert),
      checkpoint_integrity: ctx.checkpoint_integrity,
      availability: ctx.availability,
      recovery_certificate: cert,
      generated_at: DateTime.utc_now()
    }
  end

  # Recovery is now a first-class grading input: an unverified recovery caps the
  # grade regardless of how good the other signals look.
  defp grade(ctx, recovery_verified) do
    integrity_ok =
      case ctx.checkpoint_integrity do
        %{latest_valid?: true, corrupt: 0} -> true
        _ -> false
      end

    invariant_ok =
      case ctx.funnel do
        nil -> false
        events when is_list(events) -> length(events) > 0
        %{violations: violations} -> violations == []
      end

    constitutional_ok =
      case ctx.constitutional_invariants do
        nil -> false
        c -> c.all_passed
      end

    reasons =
      []
      |> then(fn r -> if recovery_verified, do: r, else: r ++ [:recovery_unverified] end)
      |> then(fn r -> if integrity_ok, do: r, else: r ++ [:checkpoint_integrity_failed] end)
      |> then(fn r -> if invariant_ok, do: r, else: r ++ [:funnel_invariant_violated_or_missing] end)
      |> then(fn r -> if constitutional_ok, do: r, else: r ++ [:constitutional_invariant_failed] end)

    grade =
      cond do
        not recovery_verified -> :recovery_unverified
        recovery_verified and integrity_ok and invariant_ok and constitutional_ok -> :verified_pending_reproduction
        true -> :provisional
      end

    {grade, reasons}
  end

  defp machine_summary(ctx, time, grade, recovery_verified, cert) do
    %{
      grade: grade,
      recovery_verified: recovery_verified,
      recovery_certificate:
        cert && %{passed: cert.passed_count, total: cert.total_count, verdict: cert.verdict},
      time: %{
        validated: time.validated_seconds,
        wall_clock: time.wall_clock_seconds,
        unvalidated: time.unvalidated_seconds,
        reconciled: TimeAccounting.reconciled?(time)
      },
      results: ctx.results_summary,
      availability: ctx.availability,
      gate_verdict: if(cert, do: cert.gate, else: ctx.gate_verdict)
    }
  end
end