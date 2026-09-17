defmodule ObservatoryApiWeb.ObservatorySocket do
  use Phoenix.Socket

  channel "obs:runtime", ObservatoryApiWeb.ObservatoryChannel
  channel "obs:science", ObservatoryApiWeb.ObservatoryChannel
  channel "obs:engineering", ObservatoryApiWeb.ObservatoryChannel
  channel "obs:knowledge", ObservatoryApiWeb.ObservatoryChannel
  channel "obs:planet", ObservatoryApiWeb.ObservatoryChannel
  channel "obs:civilization", ObservatoryApiWeb.ObservatoryChannel
  channel "obs:evolution", ObservatoryApiWeb.ObservatoryChannel
  channel "obs:certification", ObservatoryApiWeb.ObservatoryChannel
  channel "obs:alerts", ObservatoryApiWeb.ObservatoryChannel
  channel "obs:replay", ObservatoryApiWeb.ObservatoryChannel
  channel "obs:mission", ObservatoryApiWeb.ObservatoryChannel
  channel "obs:experiments", ObservatoryApiWeb.ObservatoryChannel
  channel "obs:theories", ObservatoryApiWeb.ObservatoryChannel
  channel "obs:discovery", ObservatoryApiWeb.ObservatoryChannel

  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  def id(_socket), do: nil
end
