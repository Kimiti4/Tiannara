defmodule Tiannara.Soak.RecoveryCertificate do
  @moduledoc """
  Persisted proof that a soak run recovered from a checkpoint. Records the
  outcome of the recovery matrix so a report can audit it later.

  The certificate is trusted as `verified` ONLY when the full recovery matrix
  passed (`all_passed == true`); it is never inferred from partial evidence.

  Constitutional basis: "Evidence Before Confidence" — trust requires evidence.
  """

  alias Tiannara.Soak.RecoveryGate

  @enforce_keys [:run_id, :gate, :verdict]
  defstruct [
    :run_id,
    :gate,
    :passed_count,
    :total_count,
    :all_passed,
    :verdict,
    :scenarios,
    recovered_at: nil
  ]

  @type t :: %__MODULE__{}

  @doc """
  Issue a certificate from recovery-matrix results.

  `results` is a list of `%{id: atom, passed: boolean, detail: String.t()}`.
  The certificate is `verified` ONLY when every check passed.
  """
  def issue(run_id, results) do
    passed = Enum.count(results, & &1.passed)
    total = length(results)
    all_passed = total > 0 and passed == total

    %__MODULE__{
      run_id: run_id,
      gate: RecoveryGate.verdict(Enum.map(results, fn r -> if r.passed, do: r.id end) |> Enum.reject(&is_nil/1)),
      passed_count: passed,
      total_count: total,
      all_passed: all_passed,
      verdict: if(all_passed, do: :verified, else: :unverified),
      scenarios: results,
      recovered_at: DateTime.utc_now()
    }
  end

  @doc "Persist the certificate as an artifact so a report can load it later."
  def save(%__MODULE__{} = cert, path) do
    File.mkdir_p!(Path.dirname(path))
    File.write(path, :erlang.term_to_binary(cert))
  end

  @doc "Load a persisted certificate."
  def load(path) do
    if File.exists?(path) do
      {:ok, path |> File.read!() |> :erlang.binary_to_term()}
    else
      {:error, :not_found}
    end
  end

  @doc "Render the certificate as a human-readable attestation block."
  def render(%__MODULE__{} = cert) do
    label = if cert.all_passed, do: "RECOVERY_VERIFIED", else: "RECOVERY_UNVERIFIED"

    failing =
      cert.scenarios
      |> Enum.reject(& &1.passed)
      |> Enum.map(& &1.id)

    friendly = if cert.all_passed, do: "RECOVERY VERIFIED", else: "RECOVERY UNVERIFIED"

    """
    [#{label}]
    [#{friendly}]
    Run:              #{cert.run_id}
    Gate:             #{inspect(cert.gate)}
    Recovery matrix:  #{cert.passed_count}/#{cert.total_count} scenarios passed
    Certificate:      #{String.upcase(to_string(cert.verdict))}
    Failing scenarios: #{inspect(failing)}
    """
  end
end