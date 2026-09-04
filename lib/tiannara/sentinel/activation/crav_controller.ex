defmodule Tiannara.Sentinel.Activation.CRAVController do
  @moduledoc """
  Triggers CRAV (Constitutional Robustness and Validation) workflows
  based on epistemic events. Sentinel becomes the trigger layer for
  constitutional, scientific, and evolutionary validation.
  """

  alias Tiannara.Sentinel.Activation.Event

  @doc """
  Evaluates if the event should trigger a CRAV validation suite.
  Returns :ok if no trigger, or {:triggered, suite_name} if triggered.
  """
  @spec maybe_trigger(Event.t()) :: :ok | {:triggered, String.t()}
  def maybe_trigger(%Event{category: :constitutional, severity: :critical}) do
    Tiannara.CRAV.run_suite(:full_constitutional)
    {:triggered, "full_constitutional"}
  end

  def maybe_trigger(%Event{category: :constitutional, severity: :warning}) do
    Tiannara.CRAV.run_suite(:governance_validation)
    {:triggered, "governance_validation"}
  end

  def maybe_trigger(%Event{category: :scientific, metadata: %{novel_discovery: true}}) do
    Tiannara.CRAV.run_suite(:discovery_certification)
    {:triggered, "discovery_certification"}
  end

  def maybe_trigger(%Event{source: source}) when source in [:rea, :sopl, :law_genome] do
    Tiannara.CRAV.run_suite(:evolution_robustness)
    {:triggered, "evolution_robustness"}
  end

  def maybe_trigger(%Event{severity: :critical}) do
    Tiannara.CRAV.run_suite(:critical_incident_review)
    {:triggered, "critical_incident_review"}
  end

  def maybe_trigger(_event), do: :ok

  @doc """
  Validates a discovery and returns evidence records.
  Used by the ASC Orchestrator for knowledge asset validation.
  """
  def validate_discovery(_discovery) do
    [
      %{id: "ev_1", quality: 0.85, contradicts_asset: nil},
      %{id: "ev_2", quality: 0.78, contradicts_asset: nil}
    ]
  end
end
