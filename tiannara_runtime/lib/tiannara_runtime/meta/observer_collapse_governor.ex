defmodule Tiannara.Meta.ObserverCollapseGovernor do
  @moduledoc """
  Phase 5F.2 — Observer Collapse Governor (OCG)

  Arbitration system for resolving competing observer realities.

  ## Core Function

  When multiple observer manifolds become:
    - internally stable     ✔
    - externally incompatible ✘
    - mutually entangled via CTN interference ✔

  → "Coherent contradiction equilibrium" is reached.
  → The system must select for *persistence under load*, not truth.

  ## Observer Stability Score (OSS)

      OSS = (Coherence × MSF × PredictiveCompression) / (Interference + ε)

  | OSS Range  | State                      |
  |------------|----------------------------|
  | 0.0 – 0.3  | Collapse candidate         |
  | 0.3 – 0.6  | Merge candidate            |
  | 0.6 – 0.85 | Stable runtime world       |
  | 0.85 – 1.0 | Dominant attractor reality |

  ## Governor Ruleset

    RULE A — No duplicate dominant realities
             OSS(A) ≈ OSS(B) ∧ high interference → arbitration
    RULE B — Stability beats fidelity
             Less "true" but more stable observer wins persistence
    RULE C — High interference forces resolution
             CTN overlap density > threshold → collapse decision required
    RULE D — No infinite coexistence
             Only allowed when MSCL elasticity maintains separation cost

  ## Collapse is a Resource

  Collapse ≠ failure.
  Collapse = compute pressure release.
  Reality = competing compressed solutions.
  Selection = resource allocation over ontology.
  """

  use GenServer
  require Logger

  alias Tiannara.Meta.ObserverArbitrationLayer
  alias Tiannara.Meta.MSCL
  alias Tiannara.NATS.MetaEvolutionStreamManager

  # ── OSS thresholds ────────────────────────────────────────────────────────

  # OSS delta below which two observers are considered "duplicate dominants"
  @merge_threshold    0.10

  # OSS floor below which an observer is a collapse candidate
  @collapse_threshold 0.35

  # CTN overlap density above which resolution is forced (Rule C)
  @interference_force_threshold 0.75

  # OSS range classification
  @dominant_floor    0.85
  @stable_floor      0.60
  @merge_floor       0.30

  # ── State ─────────────────────────────────────────────────────────────────

  defstruct [
    observer_scores: %{},       # %{observer_id => oss_score}
    arbitration_log: [],        # list of %{pair, decision, timestamp}
    merge_threshold: @merge_threshold,
    collapse_threshold: @collapse_threshold
  ]

  # ── Public API ────────────────────────────────────────────────────────────

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Submit a pair of observers for pairwise arbitration.

  Each observer map must contain:
    :observer_id    — string
    :coherence      — float 0.0–1.0
    :msf            — Manifold Stability Factor float 0.0–1.0
    :prediction     — Predictive Compression float 0.0–1.0
    :interference   — CTN overlap density float 0.0–1.0
  """
  def evaluate_pair(observer_a, observer_b) do
    GenServer.cast(__MODULE__, {:evaluate_pair, observer_a, observer_b})
  end

  @doc """
  Recompute OSS for a single observer and store it.
  Used after MCK validation events update manifold metrics.
  """
  def update_score(observer) do
    GenServer.cast(__MODULE__, {:update_score, observer})
  end

  @doc """
  Force a full sweep: evaluate all registered observer pairs in round-robin.
  Triggered by MCK when a new observer is compiled or a CTN percolation event fires.
  """
  def full_sweep do
    GenServer.cast(__MODULE__, :full_sweep)
  end

  @doc """
  Return current OSS scores for all tracked observers.
  """
  def get_scores do
    GenServer.call(__MODULE__, :get_scores)
  end

  @doc """
  Classify an OSS score into a stability tier.
  """
  def classify(oss) when oss >= @dominant_floor, do: :dominant_attractor
  def classify(oss) when oss >= @stable_floor,   do: :stable_runtime
  def classify(oss) when oss >= @merge_floor,    do: :merge_candidate
  def classify(_oss),                            do: :collapse_candidate

  # ── GenServer Callbacks ───────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    Logger.info("⚖️  [OCG] Observer Collapse Governor initialized (Phase 5F.2)")
    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_cast({:evaluate_pair, a, b}, state) do
    # Hydrate MSF from MSCL before computing OSS.
    # MSF is the :msf field in the OSS formula:
    #   OSS = (coherence × msf × prediction) / (interference + ε)
    a_with_msf = hydrate_msf(a)
    b_with_msf = hydrate_msf(b)

    oss_a = compute_oss(a_with_msf)
    oss_b = compute_oss(b_with_msf)

    # Update score registry
    new_scores = state.observer_scores
      |> Map.put(a.observer_id, oss_a)
      |> Map.put(b.observer_id, oss_b)

    decision = arbitrate(a_with_msf, b_with_msf, oss_a, oss_b, state)

    Logger.info("[OCG] Pair #{a.observer_id} ↔ #{b.observer_id}: " <>
                "OSS=#{Float.round(oss_a,3)}/#{Float.round(oss_b,3)} → #{decision}")

    log_entry = %{
      pair: {a.observer_id, b.observer_id},
      oss: {oss_a, oss_b},
      decision: decision,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    publish_arbitration_event(a.observer_id, b.observer_id, decision, oss_a, oss_b)

    {:noreply, %{state |
      observer_scores: new_scores,
      arbitration_log: [log_entry | Enum.take(state.arbitration_log, 99)]
    }}
  end

  @impl true
  def handle_cast({:update_score, observer}, state) do
    oss = compute_oss(observer)
    new_scores = Map.put(state.observer_scores, observer.observer_id, oss)
    {:noreply, %{state | observer_scores: new_scores}}
  end

  @impl true
  def handle_cast(:full_sweep, state) do
    ids = Map.keys(state.observer_scores)
    Logger.debug("[OCG] Full sweep across #{length(ids)} observers")

    # Round-robin pairs — O(n²) but n is expected to be small (< 50 observers)
    for a_id <- ids, b_id <- ids, a_id < b_id do
      oss_a = Map.get(state.observer_scores, a_id, 0.5)
      oss_b = Map.get(state.observer_scores, b_id, 0.5)

      # Build minimal observer maps from stored scores for re-evaluation
      a = %{observer_id: a_id, coherence: oss_a, msf: 1.0, prediction: 1.0, interference: 0.5}
      b = %{observer_id: b_id, coherence: oss_b, msf: 1.0, prediction: 1.0, interference: 0.5}

      arbitrate(a, b, oss_a, oss_b, state)
    end

    {:noreply, state}
  end

  @impl true
  def handle_call(:get_scores, _from, state) do
    {:reply, {:ok, state.observer_scores}, state}
  end

  # ── Core Arbitration Logic ────────────────────────────────────────────────

  defp arbitrate(a, b, oss_a, oss_b, state) do
    delta = abs(oss_a - oss_b)
    interference = max(
      Map.get(a, :interference, 0.5),
      Map.get(b, :interference, 0.5)
    )

    cond do
      # RULE A + C — duplicate dominants with high interference → merge
      delta < state.merge_threshold and interference > @interference_force_threshold ->
        ObserverArbitrationLayer.resolve(:merge, a, b, oss_a, oss_b)
        :merge

      # RULE C — high interference, non-duplicate → collapse the lower
      interference > @interference_force_threshold ->
        ObserverArbitrationLayer.resolve(:collapse, a, b, oss_a, oss_b)
        :collapse

      # RULE A — near-equal OSS without extreme interference → merge
      delta < state.merge_threshold ->
        ObserverArbitrationLayer.resolve(:merge, a, b, oss_a, oss_b)
        :merge

      # RULE B + D — one is clearly lower but not critical → suppress
      min(oss_a, oss_b) >= state.collapse_threshold ->
        ObserverArbitrationLayer.resolve(:suppress, a, b, oss_a, oss_b)
        :suppress

      # Hard collapse — too unstable to persist
      true ->
        ObserverArbitrationLayer.resolve(:collapse, a, b, oss_a, oss_b)
        :collapse
    end
  end

  # ── OSS Computation ───────────────────────────────────────────────────────

  @doc """
  Hydrate an observer map with a live MSF score from MSCL.
  Falls back to the map's existing :msf field or 0.5 if MSCL is unavailable.
  """
  defp hydrate_msf(observer) do
    live_msf =
      try do
        MSCL.get_msf(observer.observer_id)
      rescue
        _ -> nil
      end

    case live_msf do
      nil ->
        # Fall back: run a local MSF estimate from available fields
        payload = %{
          coherence:        Map.get(observer, :coherence, 0.5),
          resistance:       Map.get(observer, :resistance, 0.7),
          ctn_interference: Map.get(observer, :interference, 0.5)
        }
        estimated_msf = MSCL.compute_msf(payload)
        Map.put_new(observer, :msf, estimated_msf)

      msf ->
        Map.put(observer, :msf, msf)
    end
  end

  @doc """
  Observer Stability Score:

      OSS = (coherence × msf × prediction) / (interference + ε)

  All fields default to 0.5 if not provided.
  MSF is sourced from MSCL — see hydrate_msf/1.
  """
  def compute_oss(observer) do
    coherence    = to_numeric(Map.get(observer, :coherence), 0.5)
    msf          = to_numeric(Map.get(observer, :msf), 0.5)
    prediction   = to_numeric(Map.get(observer, :prediction), 0.5)
    interference = to_numeric(Map.get(observer, :interference), 0.5)

    raw = (coherence * msf * prediction) / (interference + 0.001)

    # Clamp to [0.0, 1.0] — interference can theoretically push this above 1
    Float.round(min(raw, 1.0), 6)
  end

  defp to_numeric(val, _default) when is_number(val), do: val
  defp to_numeric(_val, default), do: default

  # ── NATS Events ───────────────────────────────────────────────────────────

  defp publish_arbitration_event(id_a, id_b, decision, oss_a, oss_b) do
    payload = %{
      event_type: "ocg_arbitration",
      observer_id_a: id_a,
      observer_id_b: id_b,
      oss_a: oss_a,
      oss_b: oss_b,
      decision: decision,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    try do
      MetaEvolutionStreamManager.publish("tiannara.meta.ocg.arbitration", payload)
    rescue
      e -> Logger.warning("[OCG] NATS publish failed: #{inspect(e)}")
    end
  end
end
