defmodule Tiannara.Evidence.Provenance do
  @moduledoc """
  Canonical provenance schema for all scientific artifacts.

  Every scientific artifact (experiment, observation, result, discovery,
  hypothesis, evidence) MUST carry a provenance record that identifies
  its origin. This is the foundation of evidence truth.

  Constitutional basis:
    - "Uncertainty should never be hidden."
    - "Every architectural decision should remain traceable."
    - "Maintain audit trails. Support reproducibility."
  """

  @type provenance_kind ::
          :real_execution
          | :simulation
          | :synthetic_fixture
          | :imported_evidence
          | :unknown

  @type provenance_record :: %{
          kind: provenance_kind(),
          source: binary() | nil,
          producer: binary() | nil,
          produced_at: DateTime.t() | nil,
          execution_id: binary() | nil,
          experiment_id: binary() | nil,
          environment: map() | nil,
          evidence_hash: binary() | nil,
          audit_trail: [binary()]
        }

  @valid_kinds [:real_execution, :simulation, :synthetic_fixture, :imported_evidence, :unknown]

  @doc """
  Build a provenance record.

  Returns {:ok, record} on valid input, {:error, reason} otherwise.
  NEVER fabricates a provenance record — if the origin is unknown,
  the kind MUST be :unknown, not a fabricated :real_execution.
  """
  @spec build(keyword()) :: {:ok, provenance_record()} | {:error, term()}
  def build(opts) do
    kind = Keyword.get(opts, :kind)

    with :ok <- validate_kind(kind),
         :ok <- validate_source(kind, Keyword.get(opts, :source)),
         :ok <- validate_execution_id(kind, Keyword.get(opts, :execution_id)) do
      {:ok,
       %{
         kind: kind,
         source: Keyword.get(opts, :source),
         producer: Keyword.get(opts, :producer),
         produced_at: Keyword.get(opts, :produced_at) || DateTime.utc_now(),
         execution_id: Keyword.get(opts, :execution_id),
         experiment_id: Keyword.get(opts, :experiment_id),
         environment: Keyword.get(opts, :environment),
         evidence_hash: Keyword.get(opts, :evidence_hash),
         audit_trail: Keyword.get(opts, :audit_trail, [])
       }}
    end
  end

  @doc """
  Build a provenance record for an UNKNOWN origin.

  Used when migrating historical records whose provenance cannot be
  established. This is the HONEST fallback — never fabricate a kind.
  """
  @spec unknown(binary()) :: provenance_record()
  def unknown(reason) when is_binary(reason) do
    %{
      kind: :unknown,
      source: nil,
      producer: nil,
      produced_at: nil,
      execution_id: nil,
      experiment_id: nil,
      environment: nil,
      evidence_hash: nil,
      audit_trail: ["unknown_provenance: #{reason}"]
    }
  end

  @doc """
  Classify whether a provenance record is acceptable as scientific evidence.

  Only :real_execution and :imported_evidence (with source attribution)
  are acceptable as scientific evidence. Simulations, fixtures, and
  unknowns are NOT.
  """
  @spec acceptable_as_evidence?(provenance_record()) :: boolean()
  def acceptable_as_evidence?(%{kind: :real_execution}), do: true
  def acceptable_as_evidence?(%{kind: :imported_evidence, source: s}) when is_binary(s) and s != "", do: true
  def acceptable_as_evidence?(_), do: false

  @doc """
  Compute a deterministic hash of a provenance record for audit purposes.
  """
  @spec hash(provenance_record()) :: binary()
  def hash(record) do
    canonical = :erlang.term_to_binary(record)
    :crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower)
  end

  # --- validation helpers ---

  defp validate_kind(kind) when kind in @valid_kinds, do: :ok
  defp validate_kind(kind), do: {:error, {:invalid_provenance_kind, kind}}

  defp validate_source(:imported_evidence, nil), do: {:error, :imported_evidence_requires_source}
  defp validate_source(:imported_evidence, ""), do: {:error, :imported_evidence_requires_source}
  defp validate_source(_, _), do: :ok

  defp validate_execution_id(:real_execution, nil), do: {:error, :real_execution_requires_execution_id}
  defp validate_execution_id(:real_execution, ""), do: {:error, :real_execution_requires_execution_id}
  defp validate_execution_id(_, _), do: :ok
end
