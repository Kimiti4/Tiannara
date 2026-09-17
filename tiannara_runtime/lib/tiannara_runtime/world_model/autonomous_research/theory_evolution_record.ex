defmodule TiannaraRuntime.WorldModel.AutonomousResearch.TheoryEvolutionRecord do
  @moduledoc """
  Phase 17.8.6 — TheoryEvolutionRecord: the output artifact representing the
  outcome of a theory evolution cycle.

  Constitutional rules:
  - This struct is the single canonical representation of a theory update event.
  - No default values are hardcoded.
  - Every ID is content-addressed over its canonical fields.
  - The timestamp must be explicitly provided to guarantee deterministic replayability.
  """

  alias TiannaraRuntime.Shared.Canonical

  @id_prefix "terc"
  @id_field :record_id

  defstruct [
    :record_id,
    :config_id,
    :theory_id,
    :evidence_id,
    :pre_confidence,
    :post_confidence,
    :action,
    :rejection_reason,
    :evidence_support,
    :evidence_strength,
    :contradiction_detected,
    :timestamp
  ]

  @type t :: %__MODULE__{
          record_id: String.t() | nil,
          config_id: String.t() | nil,
          theory_id: String.t() | nil,
          evidence_id: String.t() | nil,
          pre_confidence: float() | nil,
          post_confidence: float() | nil,
          action: :strengthened | :weakened | :rejected | :unaffected | nil,
          rejection_reason: String.t() | nil,
          evidence_support: float() | nil,
          evidence_strength: float() | nil,
          contradiction_detected: boolean() | nil,
          timestamp: String.t() | nil
        }

  @doc """
  Constructs and validates a TheoryEvolutionRecord.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts) when is_list(opts) do
    record = %__MODULE__{
      config_id: Keyword.get(opts, :config_id),
      theory_id: Keyword.get(opts, :theory_id),
      evidence_id: Keyword.get(opts, :evidence_id),
      pre_confidence: Keyword.get(opts, :pre_confidence),
      post_confidence: Keyword.get(opts, :post_confidence),
      action: Keyword.get(opts, :action),
      rejection_reason: Keyword.get(opts, :rejection_reason),
      evidence_support: Keyword.get(opts, :evidence_support),
      evidence_strength: Keyword.get(opts, :evidence_strength),
      contradiction_detected: Keyword.get(opts, :contradiction_detected),
      timestamp: Keyword.get(opts, :timestamp)
    }

    with :ok <- validate(record) do
      id = Canonical.generate_id(record, @id_field, @id_prefix)
      {:ok, %{record | record_id: id}}
    end
  end

  @spec verify_id(t()) :: :ok | {:error, String.t()}
  def verify_id(%__MODULE__{} = record) do
    Canonical.verify_id(record, @id_field, @id_prefix)
  end

  @spec validate(t()) :: :ok | {:error, String.t()}
  defp validate(%__MODULE__{config_id: nil}),
    do: {:error, "TheoryEvolutionRecord: config_id is required"}

  defp validate(%__MODULE__{config_id: v}) when not is_binary(v) or v == "",
    do: {:error, "TheoryEvolutionRecord: config_id must be a non-empty string"}

  defp validate(%__MODULE__{theory_id: nil}),
    do: {:error, "TheoryEvolutionRecord: theory_id is required"}

  defp validate(%__MODULE__{theory_id: v}) when not is_binary(v) or v == "",
    do: {:error, "TheoryEvolutionRecord: theory_id must be a non-empty string"}

  defp validate(%__MODULE__{evidence_id: nil}),
    do: {:error, "TheoryEvolutionRecord: evidence_id is required"}

  defp validate(%__MODULE__{evidence_id: v}) when not is_binary(v) or v == "",
    do: {:error, "TheoryEvolutionRecord: evidence_id must be a non-empty string"}

  defp validate(%__MODULE__{pre_confidence: nil}),
    do: {:error, "TheoryEvolutionRecord: pre_confidence is required"}

  defp validate(%__MODULE__{pre_confidence: v}) when not is_float(v) or v < 0.0 or v > 1.0,
    do: {:error, "TheoryEvolutionRecord: pre_confidence must be a float between 0.0 and 1.0"}

  defp validate(%__MODULE__{post_confidence: nil}),
    do: {:error, "TheoryEvolutionRecord: post_confidence is required"}

  defp validate(%__MODULE__{post_confidence: v}) when not is_float(v) or v < 0.0 or v > 1.0,
    do: {:error, "TheoryEvolutionRecord: post_confidence must be a float between 0.0 and 1.0"}

  defp validate(%__MODULE__{action: nil}),
    do: {:error, "TheoryEvolutionRecord: action is required"}

  defp validate(%__MODULE__{action: v}) when v not in [:strengthened, :weakened, :rejected, :unaffected],
    do: {:error, "TheoryEvolutionRecord: action must be one of :strengthened, :weakened, :rejected, :unaffected"}

  defp validate(%__MODULE__{evidence_support: nil}),
    do: {:error, "TheoryEvolutionRecord: evidence_support is required"}

  defp validate(%__MODULE__{evidence_support: v}) when not is_float(v) or v < 0.0 or v > 1.0,
    do: {:error, "TheoryEvolutionRecord: evidence_support must be a float between 0.0 and 1.0"}

  defp validate(%__MODULE__{evidence_strength: nil}),
    do: {:error, "TheoryEvolutionRecord: evidence_strength is required"}

  defp validate(%__MODULE__{evidence_strength: v}) when not is_float(v) or v < 0.0 or v > 1.0,
    do: {:error, "TheoryEvolutionRecord: evidence_strength must be a float between 0.0 and 1.0"}

  defp validate(%__MODULE__{contradiction_detected: nil}),
    do: {:error, "TheoryEvolutionRecord: contradiction_detected is required"}

  defp validate(%__MODULE__{contradiction_detected: v}) when not is_boolean(v),
    do: {:error, "TheoryEvolutionRecord: contradiction_detected must be a boolean"}

  defp validate(%__MODULE__{timestamp: nil}),
    do: {:error, "TheoryEvolutionRecord: timestamp is required for determinism"}

  defp validate(%__MODULE__{timestamp: v}) when not is_binary(v) or v == "",
    do: {:error, "TheoryEvolutionRecord: timestamp must be a non-empty ISO8601 string"}

  defp validate(%__MODULE__{}), do: :ok
end
