defmodule TiannaraRuntime.WorldModel.Counterfactual.CounterfactualEvidence do
  @moduledoc """
  Represents evidence collected during replay of a counterfactual branch, tracking parent links, intervention derivations, timeline integrity hashes, and replay attempts.
  """

  @id_prefix "ce_"

  @enforce_keys [:counterfactual_id]

  defstruct [
    :evidence_id,
    :counterfactual_id,
    :parent_evidence,
    :intervention_evidence,
    :timeline_hashes,
    :math_verification,
    :replay_attempts,
    :metadata
  ]

  @type t :: %__MODULE__{
          evidence_id: String.t() | nil,
          counterfactual_id: String.t(),
          parent_evidence: list(),
          intervention_evidence: list(),
          timeline_hashes: list(),
          math_verification: any(),
          replay_attempts: list(),
          metadata: map()
        }

  def new(opts) do
    struct = %__MODULE__{
      evidence_id: opts[:evidence_id],
      counterfactual_id: opts[:counterfactual_id],
      parent_evidence: opts[:parent_evidence] || [],
      intervention_evidence: opts[:intervention_evidence] || [],
      timeline_hashes: opts[:timeline_hashes] || [],
      math_verification: opts[:math_verification],
      replay_attempts: opts[:replay_attempts] || [],
      metadata: opts[:metadata] || %{}
    }

    case validate(struct) do
      :ok -> {:ok, ensure_id(struct)}
      {:error, _} = err -> err
    end
  end

  def validate(%__MODULE__{} = evidence) do
    errors = []

    errors =
      if is_nil(evidence.counterfactual_id) or evidence.counterfactual_id == "" do
        ["empty counterfactual_id" | errors]
      else
        errors
      end

    errors =
      if not is_list(evidence.parent_evidence) do
        ["parent_evidence not list" | errors]
      else
        errors
      end

    errors =
      if not is_list(evidence.intervention_evidence) do
        ["intervention_evidence not list" | errors]
      else
        errors
      end

    errors =
      if not is_list(evidence.timeline_hashes) do
        ["timeline_hashes not list" | errors]
      else
        errors
      end

    errors =
      if not is_list(evidence.replay_attempts) do
        ["replay_attempts not list" | errors]
      else
        errors
      end

    if errors == [], do: :ok, else: {:error, Enum.reverse(errors)}
  end

  def canonicalize(%__MODULE__{} = evidence) do
    evidence
    |> Map.from_struct()
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Map.new()
  end

  def compute_id(%__MODULE__{} = evidence) do
    hash = :crypto.hash(:sha256, evidence.counterfactual_id || "") |> Base.encode16(case: :lower)
    @id_prefix <> hash
  end

  defp ensure_id(%__MODULE__{evidence_id: nil} = evidence) do
    %{evidence | evidence_id: compute_id(evidence)}
  end

  defp ensure_id(%__MODULE__{} = evidence), do: evidence
end
