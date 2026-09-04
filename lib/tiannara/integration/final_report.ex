defmodule Tiannara.Integration.FinalReport do
  @moduledoc """
  The final report for soak runs, now capable of rendering RecoveryCertificate.
  """

  defstruct [
    :run_id,
    :experiment_id,
    :grade,
    :grade_reasons,
    :manifest,
    :view_model,
    :dashboard_text,
    :machine_summary,
    :checkpoint_integrity,
    :availability,
    :recovery_certificate,
    :generated_at
  ]

  def render(%__MODULE__{} = r) do
    recovery_block =
      case r.recovery_certificate do
        %Tiannara.Soak.RecoveryCertificate{} = cert ->
          """
          ── RECOVERY CERTIFICATE ─────────────────────────
          #{Tiannara.Soak.RecoveryCertificate.render(cert)}
          """

        _ ->
          """
          ── RECOVERY ATTESTATION ─────────────────────────
          #{Tiannara.Integration.Repro.Manifest.recovery_attestation(r.manifest)}
          """
      end

    constitutional_block =
      case Map.get(r.manifest, :constitutional_invariants) do
        %{all_passed: true} ->
          "Constitutional verification: PASS"

        %{all_passed: false, failing_scenarios: failing} ->
          "Constitutional verification: FAIL\nFailing scenarios: #{inspect(failing)}"

        _ ->
          "Constitutional verification: UNKNOWN"
      end

    """
    ════════════════════════════════════════════════════════
      TIANNARA 72-HOUR SOAK — FINAL REPORT
    ════════════════════════════════════════════════════════
    Run:            #{r.run_id}
    Experiment:     #{r.experiment_id}
    Generated:      #{r.generated_at}
    GRADE:          #{String.upcase(to_string(r.grade))}
    Grade reasons:  #{inspect(r.grade_reasons)}

    ── SOURCE AVAILABILITY ──────────────────────────────
    #{format_availability(r.availability)}

    #{r.dashboard_text}

    #{recovery_block}

    #{constitutional_block}

    ── CHECKPOINT INTEGRITY ─────────────────────────────
    #{format_integrity(r.checkpoint_integrity)}

    ── MACHINE SUMMARY ──────────────────────────────────
    #{inspect(r.machine_summary, pretty: true)}

    ── REPRODUCIBILITY NOTE ─────────────────────────────
    Single-run report. Production-grade status additionally requires an
    independent Run B compared via Repro.Verdict.compare/3.
    ════════════════════════════════════════════════════════
    """
  end

  # Helper function to format availability
  defp format_availability(availability) do
    "Availability: #{Float.round(availability * 100, 1)}%"
  end

  # Helper function to format integrity
  defp format_integrity(integrity) do
    case integrity do
      %{latest_valid?: true} -> "Integrity: OK"
      _ -> "Integrity: FAILED"
    end
  end
end