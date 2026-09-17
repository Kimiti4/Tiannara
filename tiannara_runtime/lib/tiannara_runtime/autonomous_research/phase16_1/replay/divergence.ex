defmodule TiannaraRuntime.AutonomousResearch.Phase16_1.Replay.Divergence do
  @moduledoc """
  Phase 16.1 Replay Divergence Infrastructure

  Generates structured divergence reports per RESEARCH_REPLAY_MODEL.md §7.

  On any determinism or evidence-mapping failure, the runtime must:
  - return explicit failure artifacts (not silent correction)
  - preserve divergence metadata for archaeology
  """

  @type t :: %__MODULE__{
          stage: String.t(),
          input_hash_set: [String.t()],
          output_hash_set: [String.t()],
          earliest_divergence: String.t(),
          message: String.t()
        }

  defstruct [:stage, :input_hash_set, :output_hash_set, :earliest_divergence, :message]

  @doc "Create a divergence report"
  @spec report(String.t(), [String.t()], [String.t()], String.t()) :: t()
  def report(stage, input_hashes, output_hashes, earliest) do
    %__MODULE__{
      stage: stage,
      input_hash_set: input_hashes,
      output_hash_set: output_hashes,
      earliest_divergence: earliest,
      message: "Replay divergence detected at stage #{stage}"
    }
  end

  @doc "Create divergence from fingerprint mismatch"
  @spec from_fingerprint_mismatch(String.t(), String.t()) :: t()
  def from_fingerprint_mismatch(original, replayed) do
    %__MODULE__{
      stage: "replay_engine",
      input_hash_set: [original],
      output_hash_set: [replayed],
      earliest_divergence: "replay_engine",
      message: "Fingerprint mismatch: #{original} != #{replayed}"
    }
  end

  @doc "Create divergence from missing evidence"
  @spec from_missing_evidence(String.t(), String.t()) :: t()
  def from_missing_evidence(artifact_id, missing_evidence_id) do
    %__MODULE__{
      stage: "evidence_closure",
      input_hash_set: [artifact_id],
      output_hash_set: [],
      earliest_divergence: missing_evidence_id,
      message: "Evidence closure failure: missing evidence #{missing_evidence_id}"
    }
  end

  @doc "Convert divergence report to immutable artifact map"
  @spec to_artifact(t()) :: map()
  def to_artifact(%__MODULE__{} = divergence) do
    %{
      "divergence_id" => divergence_id(divergence),
      "schema_version" => "16.1.0",
      "stage" => divergence.stage,
      "input_hash_set" => divergence.input_hash_set,
      "output_hash_set" => divergence.output_hash_set,
      "earliest_divergence" => divergence.earliest_divergence,
      "message" => divergence.message,
      "failure_class" => "REPLAY_DIVERGENCE"
    }
  end

  @doc "Check if a divergence report indicates fail-closed condition"
  @spec fail_closed?(t()) :: boolean()
  def fail_closed?(%__MODULE__{}) do
    true
  end

  # --- internal helpers ---

  defp divergence_id(divergence) do
    canonical = canonicalize_map(%{
      "stage" => divergence.stage,
      "earliest_divergence" => divergence.earliest_divergence
    })

    Jason.encode!(canonical)
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
    |> then(&("div_" <> &1))
  end

  defp canonicalize_map(term) when is_map(term) do
    term
    |> Enum.map(fn {k, v} -> {to_string(k), canonicalize_map(v)} end)
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.into(%{})
  end

  defp canonicalize_map(term) when is_list(term), do: Enum.map(term, &canonicalize_map/1)
  defp canonicalize_map(term), do: term
end
