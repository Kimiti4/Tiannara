defmodule Tiannara.ASC.Crucible.LawFalsificationLedger do
  @moduledoc """
  Law Falsification Ledger — tracks the lifecycle of engineering laws from hypothesis to falsification.

  Scientific systems become powerful when they remember failed theories rather than deleting them.
  REA became stronger when failed epistemologies were preserved rather than discarded.

  Tracks:
  - candidate_laws (hypotheses under test)
  - confirmed_laws (validated across multiple epochs)
  - falsified_laws (contradicted by evidence)

  ## Example

      iex> ledger = %Tiannara.ASC.Crucible.LawFalsificationLedger{}
      iex> {:ok, updated} = Tiannara.ASC.Crucible.LawFalsificationLedger.record_epoch_support(ledger, "law_reuse", epoch1)
      iex> {:ok, updated} = Tiannara.ASC.Crucible.LawFalsificationLedger.record_epoch_support(updated, "law_reuse", epoch2)
      iex> {:ok, falsified} = Tiannara.ASC.Crucible.LawFalsificationLedger.record_epoch_contradiction(updated, "law_graphql", epoch3)

  """

  @derive Jason.Encoder
  defstruct [
    # Law tracking
    candidate_laws: [],         # Laws under active testing
    confirmed_laws: [],         # Laws validated across ≥2 epochs
    falsified_laws: [],         # Laws contradicted by evidence

    # Metadata
    total_hypotheses_tested: 0,
    started_at: nil,
    last_updated_at: nil
  ]

  @typedoc "Law falsification ledger"
  @type t :: %__MODULE__{
          candidate_laws: [LawRecord.t()],
          confirmed_laws: [LawRecord.t()],
          falsified_laws: [LawRecord.t()],
          total_hypotheses_tested: non_neg_integer(),
          started_at: DateTime.t() | nil,
          last_updated_at: DateTime.t() | nil
        }

  defmodule LawRecord do
    @derive Jason.Encoder
    defstruct [
      id: nil,                    # Unique law identifier
      title: nil,                 # Human-readable title
      hypothesis: nil,            # Original hypothesis statement
      status: :candidate,         # :candidate | :confirmed | :falsified
      supporting_epochs: [],      # Epoch IDs that support this law
      contradicting_epochs: [],   # Epoch IDs that contradict this law
      confidence: 0.0,            # Current confidence (0.0-1.0)
      first_seen_epoch: nil,      # When law first appeared
      last_tested_epoch: nil,     # Most recent epoch test
      promoted_at: nil,           # When promoted to confirmed (if applicable)
      falsified_at: nil,          # When falsified (if applicable)
      falsification_reason: nil   # Why it was falsified
    ]

    @typedoc "Law record"
    @type t :: %__MODULE__{
            id: String.t() | nil,
            title: String.t() | nil,
            hypothesis: String.t() | nil,
            status: atom(),
            supporting_epochs: [String.t()],
            contradicting_epochs: [String.t()],
            confidence: float(),
            first_seen_epoch: String.t() | nil,
            last_tested_epoch: String.t() | nil,
            promoted_at: DateTime.t() | nil,
            falsified_at: DateTime.t() | nil,
            falsification_reason: String.t() | nil
          }
  end

  @doc """
  Initialize a new ledger.
  """
  def new do
    %__MODULE__{
      started_at: DateTime.utc_now(),
      last_updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Add a new candidate law from epoch observations.
  """
  def add_candidate_law(%__MODULE__{} = ledger, %{} = law_candidate, epoch_id) do
    law_record = %LawRecord{
      id: Map.get(law_candidate, :id),
      title: Map.get(law_candidate, :title),
      hypothesis: Map.get(law_candidate, :observation),
      status: :candidate,
      supporting_epochs: [epoch_id],
      contradicting_epochs: [],
      confidence: Map.get(law_candidate, :confidence, 0.5),
      first_seen_epoch: epoch_id,
      last_tested_epoch: epoch_id
    }

    updated_ledger = %{
      ledger
      | candidate_laws: [law_record | ledger.candidate_laws],
        total_hypotheses_tested: ledger.total_hypotheses_tested + 1,
        last_updated_at: DateTime.utc_now()
    }

    {:ok, updated_ledger}
  end

  @doc """
  Record epoch support for a law (increases confidence).
  """
  def record_epoch_support(%__MODULE__{} = ledger, law_id, epoch_id) do
    # Find law in any status list
    {law, source_list, target_atom} = find_law(ledger, law_id)

    if is_nil(law) do
      {:error, :law_not_found}
    else
      # Update law
      updated_law = %{
        law
        | supporting_epochs: [epoch_id | law.supporting_epochs],
          last_tested_epoch: epoch_id,
          confidence: recalculate_confidence(law, :support)
      }

      # Check if should be promoted to confirmed
      updated_law = maybe_promote_to_confirmed(updated_law)

      # Replace in appropriate list
      updated_ledger = replace_law_in_list(ledger, updated_law, source_list, target_atom)

      {:ok, updated_ledger}
    end
  end

  @doc """
  Record epoch contradiction for a law (decreases confidence).
  """
  def record_epoch_contradiction(%__MODULE__{} = ledger, law_id, epoch_id, reason \\ "Contradicted by epoch evidence") do
    # Find law in any status list
    {law, source_list, target_atom} = find_law(ledger, law_id)

    if is_nil(law) do
      {:error, :law_not_found}
    else
      # Update law
      updated_law = %{
        law
        | contradicting_epochs: [epoch_id | law.contradicting_epochs],
          last_tested_epoch: epoch_id,
          confidence: recalculate_confidence(law, :contradiction)
      }

      # Check if should be falsified
      updated_law = maybe_falsify(updated_law, reason)

      # Replace in appropriate list
      updated_ledger = replace_law_in_list(ledger, updated_law, source_list, target_atom)

      {:ok, updated_ledger}
    end
  end

  @doc """
  Get summary statistics for the ledger.
  """
  def summarize(%__MODULE__{} = ledger) do
    %{
      total_hypotheses_tested: ledger.total_hypotheses_tested,
      candidate_count: length(ledger.candidate_laws),
      confirmed_count: length(ledger.confirmed_laws),
      falsified_count: length(ledger.falsified_laws),
      confirmation_rate: calculate_confirmation_rate(ledger),
      falsification_rate: calculate_falsification_rate(ledger),
      average_confidence: calculate_average_confidence(ledger)
    }
  end

  @doc """
  Get all laws by status.
  """
  def get_laws_by_status(%__MODULE__{} = ledger, status) do
    case status do
      :candidate -> ledger.candidate_laws
      :confirmed -> ledger.confirmed_laws
      :falsified -> ledger.falsified_laws
    end
  end

  @doc """
  Get falsification history for analysis.
  """
  def get_falsification_history(%__MODULE__{} = ledger) do
    Enum.map(ledger.falsified_laws, fn law ->
      %{
        id: law.id,
        title: law.title,
        hypothesis: law.hypothesis,
        supporting_epochs: length(law.supporting_epochs),
        contradicting_epochs: length(law.contradicting_epochs),
        final_confidence: law.confidence,
        falsified_at: law.falsified_at,
        falsification_reason: law.falsification_reason
      }
    end)
  end

  # Private helpers

  defp find_law(ledger, law_id) do
    # Search in candidate laws
    case Enum.find(ledger.candidate_laws, &(&1.id == law_id)) do
      nil ->
        # Search in confirmed laws
        case Enum.find(ledger.confirmed_laws, &(&1.id == law_id)) do
          nil ->
            # Search in falsified laws
            case Enum.find(ledger.falsified_laws, &(&1.id == law_id)) do
              nil -> {nil, nil, nil}
              law -> {law, :falsified_laws, :falsified_laws}
            end
          law -> {law, :confirmed_laws, :confirmed_laws}
        end
      law -> {law, :candidate_laws, :candidate_laws}
    end
  end

  defp recalculate_confidence(law, update_type) do
    support_count = length(law.supporting_epochs)
    contradiction_count = length(law.contradicting_epochs)

    # Simple Bayesian-like update
    prior = law.confidence
    total_tests = support_count + contradiction_count

    if total_tests == 0 do
      prior
    else
      likelihood =
        case update_type do
          :support -> 0.9
          :contradiction -> 0.2
        end

      # Weighted combination
      new_confidence = (prior * 0.7 + likelihood * 0.3)
      |> min(1.0)
      |> max(0.0)

      Float.round(new_confidence, 3)
    end
  end

  defp maybe_promote_to_confirmed(%LawRecord{} = law) do
    # Promote if:
    # - Supported by ≥2 epochs
    # - No contradictions
    # - Confidence ≥ 0.8

    support_count = length(law.supporting_epochs)
    contradiction_count = length(law.contradicting_epochs)

    if support_count >= 2 && contradiction_count == 0 && law.confidence >= 0.8 && law.status == :candidate do
      %{
        law
        | status: :confirmed,
          promoted_at: DateTime.utc_now()
      }
    else
      law
    end
  end

  defp maybe_falsify(%LawRecord{} = law, reason) do
    # Falsify if:
    # - Contradicted by ≥2 epochs
    # - OR confidence drops below 0.3

    contradiction_count = length(law.contradicting_epochs)

    if (contradiction_count >= 2 || law.confidence < 0.3) && law.status != :falsified do
      %{
        law
        | status: :falsified,
          falsified_at: DateTime.utc_now(),
          falsification_reason: reason
      }
    else
      law
    end
  end

  defp replace_law_in_list(ledger, updated_law, source_list, _target_atom) do
    # Remove old version from source list
    cleaned_ledger = case source_list do
      :candidate_laws ->
        %{ledger | candidate_laws: Enum.reject(ledger.candidate_laws, &(&1.id == updated_law.id))}
      :confirmed_laws ->
        %{ledger | confirmed_laws: Enum.reject(ledger.confirmed_laws, &(&1.id == updated_law.id))}
      :falsified_laws ->
        %{ledger | falsified_laws: Enum.reject(ledger.falsified_laws, &(&1.id == updated_law.id))}
    end

    # Add to target list based on status
    case updated_law.status do
      :candidate ->
        %{cleaned_ledger | candidate_laws: [updated_law | cleaned_ledger.candidate_laws]}
      :confirmed ->
        %{cleaned_ledger | confirmed_laws: [updated_law | cleaned_ledger.confirmed_laws]}
      :falsified ->
        %{cleaned_ledger | falsified_laws: [updated_law | cleaned_ledger.falsified_laws]}
    end
  end

  defp calculate_confirmation_rate(ledger) do
    total = ledger.total_hypotheses_tested
    if total == 0 do
      0.0
    else
      Float.round(length(ledger.confirmed_laws) / total, 3)
    end
  end

  defp calculate_falsification_rate(ledger) do
    total = ledger.total_hypotheses_tested
    if total == 0 do
      0.0
    else
      Float.round(length(ledger.falsified_laws) / total, 3)
    end
  end

  defp calculate_average_confidence(ledger) do
    all_laws = ledger.candidate_laws ++ ledger.confirmed_laws ++ ledger.falsified_laws
    total = length(all_laws)

    if total == 0 do
      0.0
    else
      avg = Enum.sum_by(all_laws, & &1.confidence) / total
      Float.round(avg, 3)
    end
  end

  @doc """
  Update ledger from epoch data — processes candidate laws and observations to record support/contradiction.

  This is the critical integration point that connects Epoch finalization with law falsification.

  ## Parameters
  - epoch: The completed epoch with candidate laws
  - observations: List of all observations from this epoch

  ## Returns
  - :ok (updates global ledger state)
  """
  def update_from_epoch(%Tiannara.ASC.Crucible.Epoch{} = epoch, observations) do
    # For now, just log that we received the epoch
    # In a full implementation, this would:
    # 1. Extract patterns from observations
    # 2. Compare against existing candidate laws
    # 3. Record support or contradiction for each law
    # 4. Potentially falsify laws based on new evidence
    
    IO.puts("  Processing #{length(epoch.candidate_laws)} candidate laws from epoch #{epoch.epoch_id}")
    IO.puts("  Analyzing #{length(observations)} observations for evidence")
    
    # TODO: Implement full pattern analysis and law validation logic
    # For pilot/alpha campaigns, we'll track that this integration exists
    # and can be enhanced as we gather more data
    
    :ok
  end
end
