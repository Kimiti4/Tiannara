defmodule ObservationBus.CertificationHooks do
  @moduledoc """
  Automatic certification integration.

  Every event published through COB that matches certification criteria
  automatically gets:
    * Certificate generation
    * Constitution version binding
    * Hash chain anchoring
    * Timestamp authority binding
  """

  alias ObservationBus.Event

  @doc """
  Attaches certification metadata to an event if eligible.
  """
  @spec certify(Event.t()) :: Event.t()
  def certify(%Event{domain: "certification"} = event), do: ObservationBus.Security.certify(event)
  def certify(%Event{priority: prio} = event) when prio >= 80, do: ObservationBus.Security.certify(event)
  def certify(%Event{} = event), do: event

  @doc """
  Returns true if the event is certifiable.
  """
  @spec certifiable?(Event.t()) :: boolean()
  def certifiable?(%Event{domain: "certification"}), do: true
  def certifiable?(%Event{priority: prio}), do: prio >= 80
  def certifiable?(_), do: false
end
