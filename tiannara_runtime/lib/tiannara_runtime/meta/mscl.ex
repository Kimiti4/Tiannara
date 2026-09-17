defmodule Tiannara.Meta.MSCL do
  @moduledoc """
  Phase 5F.1 — Meta-Stability Constraint Layer (MSCL)

  Prevents observer-relative reality from degenerating into unbounded incoherent
  drift while preserving full ontological plurality.

  ## Core Principle: "Stability Without Consensus"

  Instead of: "Do all observers agree?"
  We ask:     "Do observers remain *locally self-consistent under interaction pressure*?"

  Shifts stability from:
    ❌ global agreement
    ✅ bounded structural persistence

  ## Meta-Stability Field (MSF)

  Each observer manifold emits a scalar field:

      MSF(x, t) = Coherence(x) × Resistance_to_External_Rewrite(x) × (1 - CTN_interference)

  | MSF Value   | State                                    |
  |-------------|------------------------------------------|
  | 0.0 – 0.3   | Liquid instability (collapsing ontology) |
  | 0.3 – 0.6   | Plastic deformation (adaptive blending)  |
  | 0.6 – 0.85  | Stable manifold (healthy divergence)     |
  | 0.85 – 1.0  | Rigid attractor (canonical reality lock) |

  ## Three Stability Operators (applied every evaluation tick)

  ### 1. Coherence Drift Filter
      C' = C × (1 - λ × I_interference)
      Prevents identity noise collapse under cross-observer field collision.

  ### 2. Ontological Elasticity Clamp
      ΔP ≤ ε × MSF
      Limits how far a reality can deform under foreign physics.
      Strong realities resist rewriting; weak ones adapt or dissolve.

  ### 3. Causal Resonance Dampener
      R(t+1) = R(t) × exp(-γ × loop_density)
      Prevents CTN paradox amplification unless structurally stable.

  ## What MSCL Achieves

  Without MSCL: observer realities diverge infinitely,
                CTNs become unstable recursive attractors,
                interference becomes non-computable chaos.

  With MSCL:    divergence is ALLOWED,
                but BOUNDED by structural persistence laws.
                Reality = "stable even when contradictory".

  ## Integration Points

  - MCK: MSF is computed after each compilation; stored per observer_id
  - OCG: MSF score is used as the :msf field in OSS computation
  - NATS: MSF updates broadcast to `tiannara.meta.mscl.field_update`
  - GPU: MSF uniform `u_msf` fed into meta_graph_engine.glsl for rendering
  """

  use GenServer
  require Logger

  alias Tiannara.NATS.MetaEvolutionStreamManager

  # ── Operator coefficients ─────────────────────────────────────────────────

  # λ — Coherence Drift Filter adaptability coefficient
  @lambda_drift      0.07

  # ε — Ontological Elasticity Clamp tolerance budget
  @epsilon_elasticity 1.0

  # γ — Causal Resonance Dampener coefficient
  @gamma_resonance   0.5

  # Evaluation interval (ms) — re-runs all manifold stability checks
  @eval_interval_ms  5_000

  # ── State ─────────────────────────────────────────────────────────────────

  defstruct [
    msf_field: %{},          # %{observer_id => msf_score}
    stability_budget: 1.0,
    lambda: @lambda_drift,
    gamma: @gamma_resonance
  ]

  # ── Public API ────────────────────────────────────────────────────────────

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Evaluate a single observer manifold through the MSCL operators.

  payload must contain:
    :observer_id   — string
    :coherence     — float 0.0–1.0
    :resistance    — float 0.0–1.0  (observer's resistance to external rewrite)
    :ctn_interference — float 0.0–1.0
    :physics_delta — float (magnitude of latest physics mutation)
    :loop_density  — float 0.0–1.0

  Returns {:ok, constrained_payload} with MSF applied.
  """
  def evaluate_manifold(observer_id, payload) do
    GenServer.call(__MODULE__, {:evaluate, observer_id, payload})
  end

  @doc "Return the current MSF score for an observer (nil if not tracked)."
  def get_msf(observer_id) do
    GenServer.call(__MODULE__, {:get_msf, observer_id})
  end

  @doc "Return the full MSF field snapshot."
  def get_field do
    GenServer.call(__MODULE__, :get_field)
  end

  @doc "Force remove an observer from the MSF field (on collapse)."
  def drop_observer(observer_id) do
    GenServer.cast(__MODULE__, {:drop, observer_id})
  end

  @doc "Classify an MSF score into a stability state."
  def classify(msf) when msf >= 0.85, do: :rigid_attractor
  def classify(msf) when msf >= 0.60, do: :stable_manifold
  def classify(msf) when msf >= 0.30, do: :plastic_deformation
  def classify(_msf),                 do: :liquid_instability

  # ── GenServer Callbacks ───────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    schedule_eval_sweep()
    Logger.info("🌊 [MSCL] Meta-Stability Constraint Layer initialized (Phase 5F.1)")
    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_call({:evaluate, observer_id, payload}, _from, state) do
    msf = compute_msf(payload)

    # Apply the three stability operators in sequence
    constrained =
      payload
      |> apply_coherence_drift_filter(msf, state.lambda)
      |> apply_elasticity_clamp(msf, state.stability_budget)
      |> apply_resonance_dampener(msf, state.gamma)
      |> Map.put(:msf, msf)
      |> Map.put(:msf_class, classify(msf))

    new_field = Map.put(state.msf_field, observer_id, msf)

    Logger.debug("[MSCL] #{observer_id}: MSF=#{Float.round(msf, 4)} (#{classify(msf)})")

    # Broadcast MSF update — GPU and OCG both subscribe
    publish_field_update(observer_id, msf, constrained)

    {:reply, {:ok, constrained}, %{state | msf_field: new_field}}
  end

  @impl true
  def handle_call({:get_msf, observer_id}, _from, state) do
    {:reply, Map.get(state.msf_field, observer_id), state}
  end

  @impl true
  def handle_call(:get_field, _from, state) do
    {:reply, {:ok, state.msf_field}, state}
  end

  @impl true
  def handle_cast({:drop, observer_id}, state) do
    {:noreply, %{state | msf_field: Map.delete(state.msf_field, observer_id)}}
  end

  # ── Periodic Sweep ────────────────────────────────────────────────────────

  @impl true
  def handle_info(:eval_sweep, state) do
    # Re-evaluate all tracked observers using their last known MSF
    # Detects drift decay over time without requiring an external trigger
    {updated_field, _} =
      Enum.reduce(state.msf_field, {%{}, 0}, fn {id, last_msf}, {acc, count} ->
        # Apply temporal decay: manifolds that are not updated lose stability slowly
        decayed_msf = last_msf * :math.exp(-@lambda_drift * 0.1)
        clamped = max(decayed_msf, 0.0)

        if abs(clamped - last_msf) > 0.001 do
          Logger.debug("[MSCL] Temporal decay on #{id}: #{Float.round(last_msf, 4)} → #{Float.round(clamped, 4)}")
          publish_field_update(id, clamped, %{msf: clamped, msf_class: classify(clamped)})
        end

        {Map.put(acc, id, clamped), count + 1}
      end)

    schedule_eval_sweep()
    {:noreply, %{state | msf_field: updated_field}}
  end

  # ── Core MSF Computation ──────────────────────────────────────────────────

  @doc """
  MSF(x, t) = Coherence(x) × Resistance(x) × (1 - CTN_interference)

  All fields default to 0.5 if absent.
  Output clamped to [0.0, 1.0].
  """
  def compute_msf(payload) do
    coherence     = clamp(Map.get(payload, :coherence, 0.5))
    resistance    = clamp(Map.get(payload, :resistance, 0.5))
    interference  = clamp(Map.get(payload, :ctn_interference, 0.5))

    raw = coherence * resistance * (1.0 - interference)
    Float.round(clamp(raw), 6)
  end

  # ── Stability Operators ───────────────────────────────────────────────────

  @doc """
  Operator 1 — Coherence Drift Filter

      C' = C × (1 - λ × I_interference)

  Stops identity noise collapse under cross-observer field collision.
  """
  def apply_coherence_drift_filter(payload, msf, lambda) do
    interference = Map.get(payload, :ctn_interference, 0.5)
    c = Map.get(payload, :coherence, 0.5)

    # MSF modulates how strongly interference erodes coherence:
    # high MSF (rigid) → interference has less effect
    effective_lambda = lambda * (1.0 - msf * 0.5)
    c_prime = c * (1.0 - effective_lambda * interference)

    Map.put(payload, :coherence, clamp(c_prime))
  end

  @doc """
  Operator 2 — Ontological Elasticity Clamp

      ΔP ≤ ε × MSF

  Limits how far a reality can deform under foreign physics injection.
  Strong realities (high MSF) resist rewriting; weak ones adapt or dissolve.
  """
  def apply_elasticity_clamp(payload, msf, epsilon) do
    delta = Map.get(payload, :physics_delta, 0.0)
    max_allowed = epsilon * msf

    clamped_delta = if is_number(delta) do
      min(abs(delta), max_allowed) * (if delta < 0, do: -1, else: 1)
    else
      0.0
    end

    Map.put(payload, :physics_delta, clamped_delta)
  end

  @doc """
  Operator 3 — Causal Resonance Dampener

      R(t+1) = R(t) × exp(-γ × loop_density)

  Prevents CTN paradox amplification unless the structure is stable.
  High MSF relaxes dampening — stable observers can sustain more resonance.
  """
  def apply_resonance_dampener(payload, msf, gamma) do
    loop_density = Map.get(payload, :loop_density, 0.0)
    r = Map.get(payload, :resonance, 1.0)

    # MSF-adjusted gamma: stable manifolds dampen less (allow structured resonance)
    adjusted_gamma = gamma * (1.0 - msf * 0.4)
    r_next = r * :math.exp(-adjusted_gamma * loop_density)

    Map.put(payload, :resonance, clamp(r_next))
  end

  # ── NATS Events ───────────────────────────────────────────────────────────

  defp publish_field_update(observer_id, msf, constrained) do
    payload = %{
      event_type: "mscl_field_update",
      observer_id: observer_id,
      msf: msf,
      msf_class: to_string(classify(msf)),
      coherence_after: Map.get(constrained, :coherence, nil),
      resonance_after: Map.get(constrained, :resonance, nil),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    try do
      MetaEvolutionStreamManager.publish("tiannara.meta.mscl.field_update", payload)
    rescue
      e -> Logger.warning("[MSCL] NATS publish failed: #{inspect(e)}")
    end
  end

  # ── Helpers ───────────────────────────────────────────────────────────────

  defp clamp(v) when is_number(v), do: max(0.0, min(1.0, v))
  defp clamp(_), do: 0.5

  defp schedule_eval_sweep do
    Process.send_after(self(), :eval_sweep, @eval_interval_ms)
  end
end
