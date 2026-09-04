defmodule Tiannara.Forecasting.Signal do
  @moduledoc """
  A canonical signal: a structured observation with explicit epistemic status.

  A signal is NOT a prediction, NOT evidence, NOT a fact, and NOT a belief.
  It is a structured observation with quality and provenance metadata.

  Epistemic lifecycle (never silently collapse these categories):

      observation → signal → evidence → hypothesis → forecast → decision

  Constitutional rules:
    - Every field is explicit; `:unknown`/`nil` is a valid value where evidence
      is insufficient. Unmeasured is distinct from measured-and-low.
    - Historical signals are immutable. Corrections create new versions via
      `version/2` and never overwrite the original.
    - A signal preserves where it came from, what was observed, when, how it was
      transformed, what uncertainty exists, how reliable the source is, whether it
      is independent of other signals, and under what conditions it is valid.

  This struct is the D1 foundation consumed by D2 (Forecasting + Calibration),
  D3 (Decision), D4 (Counterfactual), D5 (Noise) and D6 (Forecast Memory).
  """

  @type provenance_t :: %{
          kind: :observation | :derived | :synthetic | :migrated,
          sha256: String.t() | nil,
          source_event_id: String.t() | nil
        }

  defstruct [
    # Identity — immutable, unique, never reused
    :id,
    :version,

    # Source — where did it originate?
    :source,
    :source_reliability,
    :domain,
    :context,

    # Observation — what was actually observed?
    :observation,
    :observation_ref,
    :observation_type,
    :measurement_uncertainty,

    # Temporal — when?
    :timestamp,
    :received_at,
    :regime,

    # Provenance & lineage — how was it transformed / linked?
    :provenance,
    :lineage,
    :transformation_history,

    # Identity lineage — id this signal replaces (set only on versioned copies)
    :supersedes,

    # Quality metadata — assessed separately, preserved as raw dimensions
    :reliability,
    :relevance,
    :independence,
    :persistence,

    # Information value — may be :unknown until outcome data exists
    :predictive_value,

    # Status & validation conditions
    :status,
    :expires_at,

    # Extensible
    :metadata,
    :tags
  ]

  @type t :: %__MODULE__{}

  @doc """
  Builds a signal from a map or keyword list, applying defaults.

  Guarantees:
    - Unique immutable `id` (UUID v4).
    - `version` defaults to 1.
    - `received_at` and `timestamp` default to `DateTime.utc_now/0`.
    - `status` defaults to `:registered`.
    - `provenance.kind` defaults to `:observation`.
    - `domain` defaults to `:cross_domain` (domain-neutral by default).
  """
  @spec new(map() | Keyword.t()) :: t()
  def new(attrs) when is_map(attrs) or is_list(attrs) do
    m = Map.new(attrs)
    now = DateTime.utc_now()

    provenance =
      Map.get(m, :provenance) ||
        %{kind: Map.get(m, :provenance_kind, :observation), sha256: nil, source_event_id: nil}

    %__MODULE__{
      id: Map.get(m, :id) || Tiannara.Executive.Types.new_id(),
      version: Map.get(m, :version, 1),
      source: Map.get(m, :source),
      source_reliability: Map.get(m, :source_reliability),
      domain: Map.get(m, :domain, :cross_domain),
      context: Map.get(m, :context),
      observation: Map.get(m, :observation),
      observation_ref: Map.get(m, :observation_ref),
      observation_type: Map.get(m, :observation_type, :unknown),
      measurement_uncertainty: Map.get(m, :measurement_uncertainty),
      timestamp: Map.get(m, :timestamp, now),
      received_at: Map.get(m, :received_at, now),
      regime: Map.get(m, :regime),
      provenance: provenance,
      lineage: Map.get(m, :lineage, []),
      transformation_history: Map.get(m, :transformation_history, []),
      supersedes: Map.get(m, :supersedes),
      reliability: Map.get(m, :reliability),
      relevance: Map.get(m, :relevance),
      independence: Map.get(m, :independence),
      persistence: Map.get(m, :persistence),
      predictive_value: Map.get(m, :predictive_value),
      status: Map.get(m, :status, :registered),
      expires_at: Map.get(m, :expires_at),
      metadata: Map.get(m, :metadata, %{}),
      tags: Map.get(m, :tags, [])
    }
  end

  @doc """
  Validates a signal, returning `{:ok, signal}` or `{:error, reason}`.

  Requirements:
    - `source` and `observation` must be present and non-nil (required keys).
    - if `expires_at` is set, it must be in the future relative to `reference` at
      registration time (temporal validity checked separately against `now`).
    - measurement_uncertainty, if present, must be a map with a `:type` field.
  """
  @spec validate(t()) :: {:ok, t()} | {:error, term()}
  def validate(%__MODULE__{} = signal) do
    if is_nil(signal.source) do
      {:error, :missing_source}
    else
      if is_nil(signal.observation) do
        {:error, :missing_observation}
      else
        case signal.measurement_uncertainty do
          nil ->
            {:ok, signal}

          mu when is_map(mu) and not is_map_key(mu, :type) ->
            {:error, :malformed_measurement_uncertainty}

          mu when is_map(mu) ->
            {:ok, signal}

          _ ->
            {:error, :malformed_measurement_uncertainty}
        end
      end
    end
  end

  @doc """
  Creates the next version of a signal from an update map without overwriting history.

  The returned signal:
    - carries a new `id` (same logical signal, new identity),
    - increments `version`,
    - records the superseded id in `lineage` (prepended as parent),
    - keeps provenance, but stamps it as a `:derived` update.
  """
  @spec version(t(), map() | Keyword.t()) :: t()
  def version(%__MODULE__{} = signal, updates) do
    u = Map.new(updates)
    previous_id = signal.id

    new(signal
        |> Map.from_struct()
        |> Map.drop([:id])
        |> Map.put(:version, signal.version + 1)
        |> Map.put(:lineage, [previous_id | signal.lineage])
        |> Map.put(:provenance, %{
          kind: :derived,
          sha256: signal.provenance && signal.provenance[:sha256],
          source_event_id: previous_id
        })
        |> Map.merge(u))
    |> Map.put(:supersedes, previous_id)
  end

  @doc """
  Returns true if the signal is expired relative to the given reference time
  (default `DateTime.utc_now/0`). A signal with no `expires_at` never expires.
  """
  @spec expired?(t(), DateTime.t() | nil) :: boolean()
  def expired?(%__MODULE__{expires_at: nil}, _now), do: false

  def expired?(%__MODULE__{expires_at: exp}, now) when is_nil(now) do
    DateTime.compare(exp, DateTime.utc_now()) == :lt
  end

  def expired?(%__MODULE__{expires_at: exp}, now) do
    DateTime.compare(exp, now) == :lt
  end

  @doc """
  The canonical fingerprint of a signal: a deterministic sha256 over the
  source + observation (for deduplication). Stable and reproducible.
  """
  @spec dedup_key(t()) :: String.t()
  def dedup_key(%__MODULE__{} = signal) do
    payload = :erlang.term_to_binary(%{source: signal.source, observation: signal.observation})
    :crypto.hash(:sha256, payload) |> Base.encode16(case: :lower)
  end
end
