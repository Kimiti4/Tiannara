defmodule TiannaraOS.Governance.ConstitutionFailureTaxonomy do
  @moduledoc """
  ConstitutionFailureTaxonomy - Classify failures for analysis and prevention.

  Failure Categories:
  :structural, :replay, :migration, :governance, :safety, :evidence, :review, :deployment

  ## API

      @spec classify_failure(error :: term()) :: ConstitutionFailureRecord.t()
      @spec analyze_failure_patterns(category :: failure_category()) :: [pattern()]
      @spec suggest_prevention(failure_record :: t()) :: [String.t()]
  """

  defstruct [:failure_id, :proposal_id, :category, :severity, :description, :root_cause, :remediation, :timestamp, :resolved]

  @type t :: %__MODULE__{}
  @type failure_category :: :structural | :replay | :migration | :governance | :safety | :evidence | :review | :deployment

  @spec classify_failure(term()) :: t()
  def classify_failure(_error), do: %__MODULE__{}

  @spec analyze_failure_patterns(failure_category()) :: [map()]
  def analyze_failure_patterns(_category), do: []

  @spec suggest_prevention(t()) :: [String.t()]
  def suggest_prevention(_record), do: []
end
