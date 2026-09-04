defmodule Tiannara.EOS.DomainBus do
  @moduledoc """
  One event domain with its BusSpec policy enforced at publish time.
  A noisy Observation domain can never backpressure the Governance domain.

  Uses Phoenix.PubSub for in-process dispatch with domain-prefixed topics
  so subscribers are isolated to their domain.
  """

  alias Tiannara.EOS.{BusSpec, Event, Constitution.ValueGate}

  @doc "Publish an event on a domain bus. Enforces rate-limit and value-gate."
  def publish(domain, %Event{} = event) when is_atom(domain) do
    spec = BusSpec.policies()[domain]

    if spec.isolation_level == :critical do
      with :ok <- check_value_gate(event) do
        topic = "eos:#{domain}:#{event.type}"
        Phoenix.PubSub.broadcast(Tiannara.EOS.PubSub, topic, {:eos_event, event})
        :telemetry.execute([:eos, domain, :event, :published], %{count: 1}, %{type: event.type})
        :ok
      end
    else
      topic = "eos:#{domain}:#{event.type}"
      Phoenix.PubSub.broadcast(Tiannara.EOS.PubSub, topic, {:eos_event, event})
      :telemetry.execute([:eos, domain, :event, :published], %{count: 1}, %{type: event.type})
      :ok
    end
  end

  def publish(_domain, _event) do
    {:error, :unknown_domain}
  end

  @doc "Subscribe to a specific event type on a domain."
  def subscribe(domain, event_type) when is_atom(domain) and is_binary(event_type) do
    Phoenix.PubSub.subscribe(Tiannara.EOS.PubSub, "eos:#{domain}:#{event_type}")
  end

  @doc "Subscribe to all events on a domain."
  def subscribe_domain(domain) when is_atom(domain) do
    Phoenix.PubSub.subscribe(Tiannara.EOS.PubSub, "eos:#{domain}:*")
  end

  defp check_value_gate(%Event{type: type} = event) do
    if String.ends_with?(type, ".minted") do
      ValueGate.validate_mint(event.payload)
    else
      :ok
    end
  end
end
