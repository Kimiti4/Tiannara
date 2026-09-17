defmodule ObservatoryApi.Channels.CertificationChannel do
  use Phoenix.Channel
  def join("obs:certification", _payload, socket), do: {:ok, socket}
end
