defmodule Tiannara.Integration.Repro.Manifest do
  @moduledoc """
  The reproducible manifest for soak runs, now certificate-aware.
  """

  alias Tiannara.Soak.RecoveryCertificate

  defstruct [
    :run_id,
    :experiment_id,
    :generated_at,
    :validated_seconds,
    :wall_clock_seconds,
    :unvalidated_seconds,
    :restarted?,
    :recovery_verified,
    :recovery_gate_missing,
    :recovery_certificate_summary
  ]

    @doc """
  Capture the base manifest for a run (before recovery/time data is attached).
  """
  def capture(experiment_id, _overrides \\ []) do
    %__MODULE__{
      run_id: experiment_id,
      experiment_id: experiment_id,
      generated_at: DateTime.utc_now()
    }
  end

  @doc """
  Attach a full Recovery Certificate. Recovery is `verified` ONLY when every
  matrix scenario passed (`cert.all_passed`) — never inferred, never partial.

  Constitutional basis: Evidence Before Confidence — trust requires evidence.
  """
  def with_recovery_certificate(manifest, %RecoveryCertificate{} = cert, %{} = t) do
    manifest
    |> with_recovery(cert.gate, t)
    |> Map.put(:recovery_certificate_summary, %{
      run_id: cert.run_id,
      passed: cert.passed_count,
      total: cert.total_count,
      all_passed: cert.all_passed,
      verdict: cert.verdict,
      failing_scenarios: Enum.reject(cert.scenarios, & &1.passed) |> Enum.map(& &1.id)
    })
  end

  @doc """
  Attach a bare gate verdict (no certificate available). Recovery is
  `verified` ONLY when the gate is fully open (`:gate_open`).

  Also copies the validated/wall-clock/unvalidated time accounting from the
  soak run so the manifest never claims continuous validation after restarts.
  """
  def with_recovery(manifest, gate_verdict, %{} = t) do
    missing =
      case gate_verdict do
        :gate_open -> []
        {:gate_closed, missing} -> missing
        _ -> []
      end

    %{
      manifest
      | recovery_verified: gate_verdict == :gate_open,
        recovery_gate_missing: missing,
        validated_seconds: Map.get(t, :validated_seconds, 0),
        wall_clock_seconds: Map.get(t, :wall_clock_seconds, 0),
        unvalidated_seconds: Map.get(t, :unvalidated_seconds, 0),
        restarted?: Map.get(t, :restarted?, false)
    }
  end

  @doc "Renderable recovery attestation block for soak reports."
  def recovery_attestation(m) do
    label =
      case Map.get(m, :recovery_verified) do
        true -> "RECOVERY VERIFIED"
        false -> "RECOVERY UNVERIFIED (gate closed)"
        _ -> "RECOVERY UNKNOWN"
      end

    base = """
    [#{label}]
    Validated soak time: #{hms(Map.get(m, :validated_seconds))}
    Wall-clock elapsed:  #{hms(Map.get(m, :wall_clock_seconds))}
    Unvalidated gap:     #{hms(Map.get(m, :unvalidated_seconds))}
    Restarted:           #{inspect(Map.get(m, :restarted?))}
    Gate missing:        #{inspect(Map.get(m, :recovery_gate_missing, []))}
    """

    case Map.get(m, :recovery_certificate_summary) do
      nil ->
        base

      cert ->
        base <> """
        Recovery matrix:   #{cert.passed}/#{cert.total} scenarios passed
        Certificate:       #{String.upcase(to_string(cert.verdict))}
        Failing scenarios: #{inspect(cert.failing_scenarios)}
        """
    end
  end

  # Helper function to format time in HH:MM:SS
  defp hms(seconds) do
    {h, rest} = div_rem(seconds, 3600)
    {m, s} = div_rem(rest, 60)
    :io_lib.format("~2.0B:~2.0B:~2.0B", [h, m, s]) |> :lists.flatten()
  end

  defp div_rem(a, b), do: {div(a, b), rem(a, b)}
end