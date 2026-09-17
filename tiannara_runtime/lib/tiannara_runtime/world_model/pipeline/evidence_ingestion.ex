defmodule TiannaraRuntime.WorldModel.Pipeline.EvidenceIngestion do
  @moduledoc """
  Phase 17.2 — Evidence Ingestion (Pipeline Stage 1).

  Connects to the Phase 16.1 ObservationRegistry to fetch, classify,
  fingerprint, and package observations into an evidence set for
  downstream world model construction.

  ## Pipeline stages (from Phase 17 MODEL_PIPELINE.md):
    Stage 1 — Evidence Ingestion:
      1a. Fetch observations by domain + time window
      1b. Fingerprint each observation (SHA-256 of canonical JSON)
      1c. Compute evidence root (Merkle root of all fingerprints)
      1d. Classify observations by type
      1e. Assemble and return the EvidenceSet

  ## Classification
    - :controlled_experiment  — has experiment_id, controlled variables
    - :natural_observation    — passive observation, no intervention
    - :simulation_output      — originated from simulation
    - :mixed                  — multiple types present
  """

  @behaviour TiannaraRuntime.WorldModel.Behaviours.Pipeline

  alias TiannaraRuntime.AutonomousResearch.Phase16_1.ObservationRegistry
  alias TiannaraRuntime.WorldModel.Ontology.Evidence

  @doc """
  Ingest evidence from the ObservationRegistry.

  Options:
    - `:domain`      — atom, research domain to filter by (e.g. :physics)
    - `:time_window` — %{start: iso_string, end: iso_string} or nil
    - `:observation_ids` — explicit list of observation IDs to fetch (bypasses domain/time filter)
    - `:metadata`    — extra metadata to attach to the evidence set

  Returns `{:ok, evidence_map}` where evidence_map contains:
    - evidence_id, domain, classification, observations,
      observation_count, evidence_root, time_window, metadata, created_at
  """
  @impl true
  @spec ingest_evidence(keyword()) :: {:ok, map()} | {:error, String.t()}
  def ingest_evidence(opts \\ []) do
    domain = Keyword.get(opts, :domain, :all)
    time_window = Keyword.get(opts, :time_window)
    observation_ids = Keyword.get(opts, :observation_ids)
    metadata = Keyword.get(opts, :metadata, %{})

    with {:ok, observations} <- fetch_observations(domain, time_window, observation_ids),
         classified = classify_observations(observations),
         evidence_root <- compute_evidence_root(observations),
         {:ok, evidence} <- build_evidence_set(observations, domain, classified, evidence_root, time_window, metadata) do
      {:ok, evidence_to_map(evidence)}
    end
  end

  @doc """
  Fetch observations from the Phase 16.1 ObservationRegistry.

  Filters by domain (via origin metadata) and optional time window
  (via captured_at field). If observation_ids are given, fetches
  those directly and ignores domain/time filters.
  """
  @spec fetch_observations(atom() | nil, map() | nil, [String.t()] | nil) ::
          {:ok, [map()]} | {:error, String.t()}
  def fetch_observations(domain, time_window \\ nil, observation_ids \\ nil)

  def fetch_observations(_domain, _time_window, observation_ids) when is_list(observation_ids) and observation_ids != [] do
    results =
      observation_ids
      |> Enum.map(fn id -> ObservationRegistry.lookup_observation(id) end)
      |> Enum.filter(fn r -> r != :error end)
      |> Enum.map(fn {:ok, obs} -> obs end)

    {:ok, results}
  end

  def fetch_observations(domain, time_window, _observation_ids) do
    all = ObservationRegistry.list_observations()

    filtered =
      all
      |> Enum.filter(fn obs -> matches_domain?(obs, domain) end)
      |> Enum.filter(fn obs -> matches_time_window?(obs, time_window) end)

    {:ok, filtered}
  end

  @doc """
  Classify a list of observations by type.

  Each observation is classified as :controlled_experiment,
  :natural_observation, or :simulation_output based on its
  origin and payload metadata fields.

  Returns `%{classification: atom(), counts: map(), details: [map()]}`.
  """
  @spec classify_observations([map()]) :: map()
  def classify_observations(observations) do
    classified = Enum.map(observations, fn obs ->
      %{observation: obs, type: classify_single(obs)}
    end)

    counts =
      classified
      |> Enum.group_by(fn %{type: t} -> t end)
      |> Map.new(fn {type, list} -> {type, length(list)} end)

    overall =
      case map_size(counts) do
        0 -> :unknown
        1 -> counts |> Map.keys() |> hd()
        _ -> :mixed
      end

    %{
      classification: overall,
      counts: counts,
      details: classified
    }
  end

  @doc """
  Compute a Merkle-style evidence root from observation fingerprints.

  The root is SHA-256 over the sorted, concatenated fingerprints
  of all observations. This provides a deterministic, replayable
  identifier for the full evidence set.
  """
  @spec compute_evidence_root([map()]) :: String.t()
  def compute_evidence_root(observations) do
    fingerprints =
      observations
      |> Enum.map(&compute_observation_fingerprint/1)
      |> Enum.sort()

    combined = Enum.join(fingerprints)

    :crypto.hash(:sha256, combined)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Compute a deterministic fingerprint for a single observation.
  Uses SHA-256 over canonical JSON of the observation.
  """
  @spec compute_observation_fingerprint(map()) :: String.t()
  def compute_observation_fingerprint(observation) do
    canonical = canonicalize_map(observation)
    json = Jason.encode!(canonical)
    :crypto.hash(:sha256, json) |> Base.encode16(case: :lower)
  end

  @doc false
  def build_evidence_set(observations, domain, classified, evidence_root, time_window, metadata) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()

    Evidence.new(
      domain: domain,
      source: :observation_registry,
      classification: classified.classification,
      observations: observations,
      observation_count: length(observations),
      evidence_root: evidence_root,
      time_window: time_window,
      metadata: Map.merge(metadata, %{
        classification_counts: classified.counts,
        classification_details: classified.details
      }),
      created_at: now
    )
  end

  # -- classification logic --

  defp classify_single(obs) do
    origin = Map.get(obs, "origin", %{})
    payload = Map.get(obs, "payload", %{})
    meta = Map.get(obs, "metadata", %{})

    cond do
      has_experiment_id?(origin, payload, meta) -> :controlled_experiment
      has_simulation_id?(origin, payload, meta) -> :simulation_output
      true -> :natural_observation
    end
  end

  defp has_experiment_id?(origin, _payload, meta) do
    Map.has_key?(origin, "experiment_id") or Map.has_key?(meta, "experiment_id")
  end

  defp has_simulation_id?(origin, _payload, meta) do
    Map.has_key?(origin, "simulation_id") or Map.has_key?(meta, "simulation_id")
  end

  # -- filtering --

  defp matches_domain?(_obs, nil), do: true
  defp matches_domain?(_obs, :all), do: true

  defp matches_domain?(obs, domain) do
    origin = Map.get(obs, "origin", %{})
    Map.get(origin, "domain", Map.get(origin, :domain)) == to_string(domain)
  end

  defp matches_time_window?(_obs, nil), do: true

  defp matches_time_window?(obs, %{start: s, end: e}) do
    captured = Map.get(obs, "captured_at")
    is_binary(captured) and captured >= s and captured <= e
  end

  defp matches_time_window?(_obs, _), do: true

  # -- canonicalization (reused from Phase 16.1 pattern) --

  defp canonicalize_map(term) when is_map(term) do
    term
    |> Enum.map(fn {k, v} -> {to_string(k), canonicalize_map(v)} end)
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.into(%{})
  end

  defp canonicalize_map(term) when is_list(term), do: Enum.map(term, &canonicalize_map/1)
  defp canonicalize_map(term), do: term

  # -- serialization --

  defp evidence_to_map(%Evidence{} = e) do
    %{
      evidence_id: e.evidence_id,
      domain: e.domain,
      source: e.source,
      classification: e.classification,
      observations: e.observations,
      observation_count: e.observation_count,
      evidence_root: e.evidence_root,
      time_window: e.time_window,
      metadata: e.metadata,
      created_at: e.created_at
    }
  end
end
