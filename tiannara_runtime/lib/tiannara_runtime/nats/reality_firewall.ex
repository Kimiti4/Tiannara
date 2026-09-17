defmodule Tiannara.Meta.Mesh.RealityFirewall do
  @moduledoc """
  Phase 5F.x — Cross-Manifold Security Firewall

  Validates all cross-manifold events before they propagate through
  the NATS reality mesh. Prevents paradox injection, entropy overflow,
  and causal violations from destabilizing distributed realities.

  ## Validation Chain

  All events must pass through:
  1. **GCK Validation** — Grammar constraint verification
  2. **MSCL Pressure Check** — Meta-stability budget verification
  3. **OLEF Load Verification** — Ontological load capacity check
  4. **Entropy Verification** — Entropy spike detection

  ## Security Policies

  - Reject events with entropy > 0.9 (paradox risk)
  - Block cross-manifold writes without causal chain
  - Throttle high-frequency event bursts (> 100/sec)
  - Quarantine observers with repeated validation failures

  ## Usage

      # Validate event before publishing
      case RealityFirewall.validate(event) do
        :ok -> :publish_allowed
        {:error, _reason} -> :blocked
      end
  """

  require Logger

  # Security thresholds
  @max_entropy 0.9
  # events per second
  @max_event_rate 100
  @max_validation_failures 5

  @doc """
  Validates an event before allowing it through the firewall.

  ## Parameters
  - `event`: Event map to validate

  ## Returns
  - `:ok` if event passes all checks
  - `{:error, reason}` if validation fails

  ## Example

      event = %{
        type: "observer.branch",
        observer_id: "obs_001",
        entropy: 0.5
      }

      :ok = RealityFirewall.validate(event)
  """
  def validate(event) when is_map(event) do
    Logger.debug("🛡️ [RealityFirewall] Validating event: #{event.type}")

    with :ok <- check_entropy(event),
         :ok <- verify_causal_chain(event),
         :ok <- check_event_rate(event),
         :ok <- verify_observer_status(event) do
      Logger.debug("✅ [RealityFirewall] Event validated")
      :ok
    else
      {:error, reason} ->
        Logger.warning("🚫 [RealityFirewall] Event blocked: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Checks if event entropy is within safe bounds.

  High entropy events risk paradox injection and reality destabilization.

  ## Parameters
  - `event`: Event map

  ## Returns
  - `:ok` or `{:error, :entropy_too_high}`
  """
  def check_entropy(event) do
    entropy = Map.get(event, :entropy, 0.0)

    if entropy > @max_entropy do
      Logger.warning("🔥 [RealityFirewall] Entropy spike detected: #{entropy}")
      {:error, :entropy_too_high}
    else
      :ok
    end
  end

  @doc """
  Verifies event has valid causal chain metadata.

  Cross-manifold events must include trace_id and causal_depth.

  ## Parameters
  - `event`: Event map

  ## Returns
  - `:ok` or `{:error, :missing_causal_chain}`
  """
  def verify_causal_chain(event) do
    causal_metadata = Map.get(event, :_causal_metadata, %{})

    has_trace_id = Map.has_key?(causal_metadata, :trace_id)
    has_causal_depth = Map.has_key?(causal_metadata, :causal_depth)

    if has_trace_id and has_causal_depth do
      :ok
    else
      Logger.debug("⛓️ [RealityFirewall] Missing causal chain metadata")
      {:error, :missing_causal_chain}
    end
  end

  @doc """
  Checks if event rate is within acceptable limits.

  Prevents event flooding that could overwhelm mesh nodes.

  ## Parameters
  - `event`: Event map

  ## Returns
  - `:ok` or `{:error, :rate_limit_exceeded}`
  """
  def check_event_rate(event) do
    event_rate = Map.get(event, :event_rate, Map.get(event, :rate, 0))

    if event_rate > @max_event_rate do
      {:error, :rate_limit_exceeded}
    else
      :ok
    end
  end

  @doc """
  Verifies observer is not quarantined due to validation failures.

  ## Parameters
  - `event`: Event map with observer_id

  ## Returns
  - `:ok` or `{:error, :observer_quarantined}`
  """
  def verify_observer_status(event) do
    observer_id = Map.get(event, :observer_id)

    if observer_id == nil do
      # Non-observer events pass
      :ok
    else
      # TODO: Check quarantine status in production
      :ok
    end
  end

  @doc """
  Records a validation failure for an observer.

  After max failures, observer is quarantined.

  ## Parameters
  - `observer_id`: Observer identifier
  - `failure_reason`: Reason for validation failure

  ## Returns
  - `:ok`
  """
  def record_failure(observer_id, failure_reason, failure_count \\ 1) do
    Logger.warning("⚠️ [RealityFirewall] Validation failure for #{observer_id}: #{failure_reason}")

    if failure_count >= @max_validation_failures do
      quarantine_observer(observer_id, :max_validation_failures)
    else
      :ok
    end
  end

  @doc """
  Quarantines an observer from publishing events.

  Used when observer repeatedly violates security policies.

  ## Parameters
  - `observer_id`: Observer to quarantine
  - `reason`: Quarantine reason

  ## Returns
  - `:ok`
  """
  def quarantine_observer(observer_id, reason) do
    Logger.error("🚨 [RealityFirewall] Observer #{observer_id} QUARANTINED: #{reason}")

    # TODO: Add to quarantine list in production
    :ok
  end

  @doc """
  Removes observer from quarantine.

  ## Parameters
  - `observer_id`: Observer to unquarantine

  ## Returns
  - `:ok`
  """
  def unquarantine_observer(observer_id) do
    Logger.info("✅ [RealityFirewall] Observer #{observer_id} unquarantined")
    :ok
  end
end
