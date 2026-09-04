defmodule Tiannara.Certification.MultiCertificate do
  @moduledoc """
  The multi-dimensional certificate (the R2.8-style certification). Lists every
  dimension with PASS / FAIL / NOT EVALUATED and an overall verdict.
  """
  @enforce_keys [:subsystem, :verdict, :dimensions]
  defstruct [:subsystem, :verdict, :dimensions, :issued_at, :reason]

  def certified?(%__MODULE__{verdict: :certified}), do: true
  def certified?(_), do: false

  def render(%__MODULE__{} = cert) do
    lines =
      Enum.map(cert.dimensions, fn d ->
        status =
          case d.status do
            :pass -> "PASS"
            :fail -> "FAIL"
            :unevaluated -> "NOT EVALUATED"
          end

        crit = if d.criticality == :critical, do: "[critical]", else: "[advisory]"

        "  " <>
          String.pad_trailing(to_string(d.id), 30) <> 
          String.pad_trailing(status, 15) <> crit
      end)

    verdict_str =
      case cert.verdict do
        :certified -> "CERTIFIED"
        {:not_certified, _} -> "NOT CERTIFIED"
      end

    """
    ════════════════════════════════════════════════════
      TIANNARA CERTIFICATION — #{String.upcase(to_string(cert.subsystem))}
    ════════════════════════════════════════════════════
    #{Enum.join(lines, "\n")}

    OVERALL VERDICT: #{verdict_str}
    Reason: #{inspect(cert.reason)}
    Issued: #{cert.issued_at}
    ════════════════════════════════════════════════════
    """
  end
end

defmodule Tiannara.Certification.Pipeline do
  @moduledoc """
  Composes every gate into a single multi-dimensional certificate. Each
  dimension is evaluated from a provided gate verdict; missing verdicts become
  `:unevaluated` and (if critical) block certification.

  Constitutional basis: Verification First ("No feature is complete until it is
  validated"), "Capability must never outpace verification", "Never optimize for
  appearing correct."
  """

  alias Tiannara.Certification.{Dimension, DimensionPolicy, MultiCertificate}

  @doc """
  `gate_results` maps dimension id -> gate verdict, where a verdict is one of:
    :gate_open | :pass | {:pass, evidence}
    {:gate_closed, reasons} | :fail | {:fail, reason}
    :unevaluated | :not_evaluated | nil (missing)
  """
  def evaluate(gate_results, opts \\ []) do
    subsystem = Keyword.get(opts, :subsystem, :tiannara)
    policy = Keyword.get(opts, :policy, DimensionPolicy.dimensions())

    dimensions =
      Map.keys(policy)
      |> Enum.map(fn id ->
        criticality = Map.fetch!(policy, id)
        {status, evidence, detail} = normalize(Map.get(gate_results, id))

        %Dimension{
          id: id,
          criticality: criticality,
          status: status,
          evidence: evidence,
          detail: detail
        }
      end)

    verdict = DimensionPolicy.overall_verdict(dimensions)


    %MultiCertificate{
      subsystem: subsystem,
      dimensions: dimensions,
      verdict: verdict,
      issued_at: DateTime.utc_now(),
      reason: reason(verdict)
    }
  end

  @doc "Build a gate_results map from a context of already-computed verdicts."
  def build_gate_results(context) do
    %{
      constitutional_invariants: Map.get(context, :invariant_verdict, :unevaluated),
      recovery: Map.get(context, :recovery_verdict, :unevaluated),
      evidence_integrity: Map.get(context, :evidence_integrity_verdict, :unevaluated),
      funnel_integrity: Map.get(context, :funnel_verdict, :unevaluated),
      adversarial_detection: Map.get(context, :adversarial_verdict, :unevaluated),
      authorization_integrity: Map.get(context, :authorization_verdict, :unevaluated),
      deterministic_replay: Map.get(context, :replay_verdict, :unevaluated)
    }
  end

  defp normalize(:gate_open), do: {:pass, nil, nil}
  defp normalize(:pass), do: {:pass, nil, nil}
  defp normalize({:pass, evidence}), do: {:pass, evidence, nil}
  defp normalize({:gate_closed, reasons}), do: {:fail, nil, reasons}
  defp normalize(:fail), do: {:fail, nil, nil}
  defp normalize({:fail, reason}), do: {:fail, nil, reason}
  defp normalize(:unevaluated), do: {:unevaluated, nil, nil}
  defp normalize(:not_evaluated), do: {:unevaluated, nil, nil}
  defp normalize(nil), do: {:unevaluated, nil, nil}
  defp normalize(other), do: {:unevaluated, nil, {:unrecognized, other}}

  defp reason(:certified), do: :all_critical_dimensions_pass
  defp reason({:not_certified, r}), do: r
end