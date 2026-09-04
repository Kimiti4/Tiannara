defmodule Tiannara.Forecasting.Adapters.Evidence do
  @moduledoc """
  Adapter contract linking signals to the existing Scientific Discovery evidence
  system WITHOUT creating a parallel evidence ontology.

  Signals reference existing evidence by id. support/contradict relationships stay
  visible (Signal A supports H1, Signal B contradicts H1 — both remain).

  D1 defines the interface only; D2+ implement the concrete linkage.
  """

  @doc """
  Links a signal to an existing evidence entity by id.
  """
  @callback link_to_evidence(Signal.t(), evidence_id :: String.t(), kind :: :supports | :contradicts) ::
              {:ok, map()} | {:error, term()}

  @doc "Retrieves the evidence references for a signal."
  @callback evidence_for(Signal.t()) :: {:ok, [map()]} | {:error, term()}
end

defmodule Tiannara.Forecasting.Adapters.Research do
  @moduledoc """
  Adapter contract between EFDI signals and the Research Director.

  D1 exposes the information the Research Director needs (high information-gain
  signals, poorly observed regions, contradictory evidence, research gaps, high
  uncertainty, unresolved measurement questions). The eventual loop:

      Unknown → competing hypotheses → forecast uncertainty → info gain →
      experiment → evidence → updated forecast

  D1 defines the interface only; D2+ implement the Research Director integration.
  """

  @doc """
  Converts a high-value signal into a Research Director priority map
  compatible with `Tiannara.Research.ResearchDirector.ingest_priorities/1`.
  """
  @callback signal_to_priority(Signal.t()) :: {:ok, map()} | {:error, term()}

  @doc "Batch conversion of signals into priorities."
  @callback signals_to_priorities([Signal.t()]) :: {:ok, [map()]}

  @doc "Estimates the information gain of observing a region, for experiment selection."
  @callback information_gain_estimate(Signal.t(), [map()]) :: {:ok, float()} | {:error, :insufficient_data}

  @doc "Flags regions that are under-observed (research gaps)."
  @callback under_observed_regions([Signal.t()]) :: {:ok, [map()]}
end

defmodule Tiannara.Forecasting.Adapters.CIS do
  @moduledoc """
  Adapter contract between EFDI and the Cognitive Immune System.

  Constitutional boundary (per EFDI CIS integration):

      CIS telemetry → Signal → Forecast → collapse probability → CIS decision

  CIS retains constitutional authority over safety/stability regulation. EFDI
  provides epistemic prediction only — forecast confidence is NOT authorization.

  D1 defines the interface only; D2+ implement the integration. D1 does NOT
  replace the existing CIS collapse prediction.
  """

  @doc "Converts a signal into CIS-compatible telemetry."
  @callback signal_to_telemetry(Signal.t()) :: {:ok, map()} | {:error, term()}

  @doc "Converts a forecast distribution into a CIS-compatible collapse probability."
  @callback forecast_to_collapse_probability(map()) :: {:ok, float()} | {:error, term()}

  @doc "Converts a set of conflicting signals into a CIS pathogen event."
  @callback signal_conflict_to_pathogen([Signal.t()]) :: {:ok, map()} | {:error, term()}
end

defmodule Tiannara.Forecasting.Adapters.WorldModel do
  @moduledoc """
  Adapter contract between EFDI and the World Model / Unified Reality Graph.

  Future architecture (D2+):

      World State + Signals + Evidence → Forecast Distribution → Future States

  The Unified Reality Graph remains the canonical reality/world representation.
  EFDI does NOT fork a parallel world representation.

  D1 defines the interface only; no World Model modification is made in D1.
  """

  @doc "Registers a signal as a world-model observation/entity."
  @callback ingest_signal(Signal.t()) :: {:ok, term()} | {:error, term()}

  @doc "Retrieves the world-model context relevant to a signal's domain/regime."
  @callback context_for(Signal.t()) :: {:ok, map()} | {:error, term()}

  @doc "Checks whether a signal conflicts with existing world-model state."
  @callback conflicts_with_world?(Signal.t()) :: {:ok, boolean()} | {:error, term()}
end
