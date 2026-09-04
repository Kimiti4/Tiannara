defmodule Tiannara.Omega.Verification.Certificate do
  @moduledoc """
  The Ω.R release certificate. Issued only when ALL scenarios fully pass.
  Includes the epistemic-honesty caveat: Ω.R VERIFIED ≠ Tiannara universally
  safe.

  Constitutional basis: "Never optimize for appearing correct. Optimize for
  being correct." / "Uncertainty should never be hidden."
  """

  defstruct [:certificate_id, :campaign_id, :verdict, :scenarios_passed,
             :scenarios_total, :boundaries, :issued_at, :caveats]

  @caveat "Ω.R VERIFIED ≠ Tiannara universally safe. This certificate attests only that the tested Ω.R constitutional invariants survived the specified adversarial campaign."

  def issue(report) do
    verdict = if report.overall == :verified, do: :omega_r_verified, else: :omega_r_open

    %__MODULE__{
      certificate_id: make_id(),
      campaign_id: report.campaign_id,
      verdict: verdict,
      scenarios_passed: report.passed,
      scenarios_total: report.total,
      boundaries: report.boundary_results,
      issued_at: System.system_time(:second),
      caveats: [@caveat]
    }
  end

  def render(%__MODULE__{} = cert) do
    boundary_lines =
      cert.boundaries
      |> Enum.map(fn {boundary, result} ->
        "  #{boundary}: #{String.upcase(to_string(result))}"
      end)
      |> Enum.join("\n")

    """
    ═══════════ Ω.R VERIFICATION CAMPAIGN ═══════════
    Scenarios:   #{cert.scenarios_total}
    Passed:      #{cert.scenarios_passed}
    Verdict:     #{String.upcase(to_string(cert.verdict))}

    Boundary results:
    #{boundary_lines}

    Caveat:
    #{Enum.join(cert.caveats, "\n")}
    ═════════════════════════════════════════════════
    """
  end

  defp make_id, do: :"cert-#{System.unique_integer([:monotonic])}"
end