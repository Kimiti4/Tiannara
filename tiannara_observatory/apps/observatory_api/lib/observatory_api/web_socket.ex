defmodule ObservatoryApi.WebSocket do
  use Phoenix.Socket

  channel "obs:runtime", ObservatoryApi.Channels.RuntimeChannel
  channel "obs:metrics", ObservatoryApi.Channels.MetricsChannel
  channel "obs:science", ObservatoryApi.Channels.ScienceChannel
  channel "obs:engineering", ObservatoryApi.Channels.EngineeringChannel
  channel "obs:discovery", ObservatoryApi.Channels.DiscoveryChannel
  channel "obs:replay", ObservatoryApi.Channels.ReplayChannel
  channel "obs:alerts", ObservatoryApi.Channels.AlertsChannel
  channel "obs:certification", ObservatoryApi.Channels.CertificationChannel

  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  def id(_socket), do: nil
end
