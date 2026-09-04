defmodule Tiannara.Evidence.CertificationGate do
  @moduledoc """
  Downstream certification gate for scientific artifacts.

  Rejects any artifact whose provenance is not acceptable as scientific
  evidence. This is the enforcement layer that prevents fabricated
  results from contaminating downstream discovery, research, and
  knowledge integration.

  Constitutional basis:
    - "Evidence Before Confidence"
    - "Capability must never outpace verification"
  """

  alias Tiannara.Evidence.Provenance

  @type verdict :: :accepted | :rejected | :quarantined

  @doc """
  Evaluate whether an artifact is acceptable as scientific evidence.

  Returns:
    {:accepted, artifact}         — provenance is real_execution or imported_evidence
    {:rejected, artifact, reason} — provenance is simulation/fixture/unknown
    {:quarantined, artifact, reason} — provenance missing or unverifiable
  """
  @spec evaluate(map()) :: {:accepted, map()} | {:rejected, map(), binary()} | {:quarantined, map(), binary()}
  def evaluate(artifact) do
    case Map.get(artifact, :provenance) do
      nil ->
        {:quarantined, artifact, "missing_provenance"}

      %{} = provenance ->
        cond do
          Provenance.acceptable_as_evidence?(provenance) ->
            {:accepted, artifact}

          provenance.kind == :unknown ->
            {:quarantined, artifact, "unknown_provenance"}

          provenance.kind in [:simulation, :synthetic_fixture] ->
            {:rejected, artifact, "fabricated_or_synthetic:#{provenance.kind}"}

          true ->
            {:rejected, artifact, "unacceptable_provenance:#{provenance.kind}"}
        end

      other ->
        {:quarantined, artifact, "malformed_provenance:#{inspect(other)}"}
    end
  end

  @doc """
  Strict evaluation: raises on rejection/quarantine.
  """
  @spec evaluate!(map()) :: map()
  def evaluate!(artifact) do
    case evaluate(artifact) do
      {:accepted, a} -> a
      {:rejected, _, reason} -> raise Tiannara.Evidence.RejectedError, reason: reason
      {:quarantined, _, reason} -> raise Tiannara.Evidence.QuarantinedError, reason: reason
    end
  end
end

defmodule Tiannara.Evidence.RejectedError do
  defexception [:reason]

  @impl true
  def message(%{reason: reason}), do: "Evidence rejected: #{reason}"
end

defmodule Tiannara.Evidence.QuarantinedError do
  defexception [:reason]

  @impl true
  def message(%{reason: reason}), do: "Evidence quarantined: #{reason}"
end
