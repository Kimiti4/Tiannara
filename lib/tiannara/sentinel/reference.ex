defmodule Tiannara.Sentinel.Reference do
  @moduledoc """
  Stable constitutional reference representing the observational Sentinel
  capability surface. It intentionally exposes no action execution API.
  """

  def observation_capability, do: :observation_only
end
