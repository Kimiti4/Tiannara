defmodule Tiannara.Forecasting.Outcome do
  @moduledoc """
  D2 outcome linking: Forecast → ObservedOutcome, with hindsight isolation.

  An outcome links a forecast to reality. D2 does NOT decide whether an
  outcome is valid; it consumes the existing canonical event infrastructure.

  Rules:
    - forecast-time information and post-outcome information are kept separate.
    - An outcome recorded at/after `forecast.created_at` is linked only when it
      documents the forecast-time snapshot, never retroactively edited.
    - `hindsight_clean?/2` guards against revising the forecast after the fact.

  ## TCP-002.6: the observation contract

  The original struct carried five fields and nothing else. That was enough
  to *link* an outcome, but not enough to know *what* was observed, *when* it
  happened, *whether* the evidence supports it, or *which* registered forecast
  it belongs to. This struct now carries that information.

  ### Binding

  The authoritative values — the forecast digest, the outcome-definition
  digest and the horizon digest — are derived from the **registered** forecast
  by `Tiannara.Forecasting.Observation`, never supplied by the caller. The
  fields are present here so that the binding can be *checked*, not so that it
  can be *asserted*.

  ### Timestamp semantics

  These are not interchangeable and are never conflated:

  | Field         | Meaning                                            |
  |---------------|----------------------------------------------------|
  | `event_at`    | when the underlying event occurred                 |
  | `published_at`| when the source published the information          |
  | `acquired_at` | when Tiannara actually retrieved the evidence      |
  | `verified_at` | when the verifier completed its checks             |
  | `observed_at` | the legacy field; it is the event time when present |

  A missing source timestamp stays missing. It is never filled with the
  retrieval time.

  ### Legacy outcomes

  An outcome constructed before this contract has no digest, no evidence
  reference and no verification status. It remains readable, and it is
  classified `:unverified`. It is **not eligible for normal resolution**,
  because there is no evidence to verify. `eligible_for_resolution?/1` makes
  that explicit.
  """
  alias Tiannara.Forecasting.Contracts.Forecast

  @type verification_status ::
          :unverified
          | :verified
          | :verified_with_limited_source_assurance
          | :requires_review
          | :rejected
          | :unavailable

  @type outcome :: %{
          id: String.t(),
          forecast_id: String.t(),
          observed_outcome: term(),
          observed_at: DateTime.t() | nil,
          source: String.t(),
          # --- immutable forecast binding (TCP-002.6) ---
          forecast_digest: binary() | nil,
          outcome_definition_digest: binary() | nil,
          horizon_digest: binary() | nil,
          # --- observation identity ---
          observation_id: String.t() | nil,
          source_identity: String.t() | nil,
          source_type: String.t() | nil,
          source_record_id: String.t() | nil,
          # --- evidence ---
          evidence_ref: String.t() | nil,
          evidence_digest: binary() | nil,
          evidence_schema_version: String.t() | nil,
          # --- distinct timestamps ---
          event_at: DateTime.t() | nil,
          published_at: DateTime.t() | nil,
          acquired_at: DateTime.t() | nil,
          verified_at: DateTime.t() | nil,
          # --- verification ---
          verification_status: verification_status(),
          verification_policy_version: String.t() | nil,
          assurance: map() | nil
        }

  @spec new(forecast_id :: String.t(), observed_outcome :: term(), map() | Keyword.t()) ::
          outcome()
  def new(forecast_id, observed_outcome, attrs \\ []) when is_binary(forecast_id) do
    m = Map.new(attrs)

    outcome = %{
      id: Map.get(m, :id) || Tiannara.Executive.Types.new_id(),
      forecast_id: forecast_id,
      observed_outcome: observed_outcome,
      observed_at: Map.get(m, :observed_at),
      source: Map.get(m, :source, "event_store"),
      forecast_digest: Map.get(m, :forecast_digest),
      outcome_definition_digest: Map.get(m, :outcome_definition_digest),
      horizon_digest: Map.get(m, :horizon_digest),
      observation_id: Map.get(m, :observation_id),
      source_identity: Map.get(m, :source_identity),
      source_type: Map.get(m, :source_type),
      source_record_id: Map.get(m, :source_record_id),
      evidence_ref: Map.get(m, :evidence_ref),
      evidence_digest: Map.get(m, :evidence_digest),
      evidence_schema_version: Map.get(m, :evidence_schema_version),
      event_at: Map.get(m, :event_at),
      published_at: Map.get(m, :published_at),
      acquired_at: Map.get(m, :acquired_at),
      verified_at: Map.get(m, :verified_at),
      verification_status: Map.get(m, :verification_status, :unverified),
      verification_policy_version: Map.get(m, :verification_policy_version),
      assurance: Map.get(m, :assurance)
    }

    Tiannara.Forecasting.Lifecycle.record_outcome(outcome)

    outcome
  end

  @doc """
  True when the outcome observation time is at/after the forecast creation time
  (i.e., the outcome could not precede the forecast). This is the hindsight
  isolation pre-condition.
  """
  @spec hindsight_clean?(outcome(), Forecast.t()) :: boolean()
  def hindsight_clean?(_outcome, %Forecast{created_at: nil}), do: true

  def hindsight_clean?(%{observed_at: nil}, _forecast), do: true

  def hindsight_clean?(%{observed_at: at}, %Forecast{created_at: fc}) do
    DateTime.compare(at, fc) in [:gt, :eq]
  end

  @doc """
  Rejects outcomes whose observed_at precedes forecast creation (hindsight
  contamination). Returns `{:ok, outcome}` or `{:error, :hindsight_contamination}`.
  """
  @spec guard!(outcome(), Forecast.t()) :: {:ok, outcome()} | {:error, :hindsight_contamination}
  def guard!(outcome, %Forecast{} = forecast) do
    if hindsight_clean?(outcome, forecast) do
      {:ok, outcome}
    else
      {:error, :hindsight_contamination}
    end
  end

  @doc """
  The canonical digest of an observation's content.

  This binds everything that gives the observation its meaning: which
  forecast it belongs to, what was observed, when the event happened, when
  the source published it, when it was acquired, and which evidence it
  rests on. The verification state is deliberately excluded, because it is
  applied *to* the observation rather than being part of it.

  A verification record carries this digest. Without it, an observation could
  be verified and then have its observed value changed before resolution,
  and the resolution would score something the evidence never supported.
  """
  @spec content_digest(outcome()) :: binary()
  def content_digest(outcome) when is_map(outcome) do
    :crypto.hash(
      :sha256,
      :erlang.term_to_binary(
        {:tiannara_observation_v1, Map.get(outcome, :forecast_id),
         Map.get(outcome, :forecast_digest), Map.get(outcome, :outcome_definition_digest),
         Map.get(outcome, :horizon_digest), Map.get(outcome, :observation_id),
         Map.get(outcome, :observed_outcome), Map.get(outcome, :observed_at),
         Map.get(outcome, :event_at), Map.get(outcome, :published_at),
         Map.get(outcome, :acquired_at), Map.get(outcome, :evidence_ref),
         Map.get(outcome, :evidence_digest), Map.get(outcome, :source_identity)}
      )
    )
  end

  @doc """
  Whether this outcome carries the binding and the evidence reference.

  A legacy outcome — one with no forecast binding and no evidence reference —
  is not bound. It remains readable and auditable; it simply cannot be
  resolved.
  """
  @spec bound?(outcome()) :: boolean()
  def bound?(%{
        forecast_digest: digest,
        outcome_definition_digest: definition_digest,
        horizon_digest: horizon_digest,
        evidence_ref: ref,
        evidence_digest: evidence_digest
      })
      when is_binary(digest) and is_binary(definition_digest) and is_binary(horizon_digest) and
             is_binary(ref) and is_binary(evidence_digest) do
    true
  end

  def bound?(_outcome), do: false

  @doc """
  Whether this outcome carries the provenance required for normal resolution.

  This is `bound?/1` **and** a verification status the resolver accepts. A
  bound outcome that has not been verified is not eligible — it is waiting
  for the verifier, which is a different condition from being legacy.

  The status on its own is a *claim*. The resolver does not believe it: it
  checks it against a verification record the verifier produced.
  """
  @spec eligible_for_resolution?(outcome()) :: boolean()
  def eligible_for_resolution?(outcome) do
    bound?(outcome) and
      Map.get(outcome, :verification_status) in [
        :verified,
        :verified_with_limited_source_assurance
      ]
  end

  @doc """
  The classification of an outcome that has no provenance.

  It is `unverified`, not `unknown`: the system knows it cannot vouch for it.
  """
  @spec classification(outcome()) :: :bound_and_verified | :legacy_unverified | :unbound
  def classification(%{verification_status: :unverified, forecast_digest: nil}),
    do: :legacy_unverified

  def classification(%{verification_status: :unverified}), do: :unbound

  def classification(_outcome), do: :bound_and_verified
end
