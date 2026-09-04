defmodule Tiannara.ASC.Reality.PhysicalAdapter do
  @moduledoc """
  Contract for hardware adapters managed by `Tiannara.ASC.Reality.PhysicalDeploymentManager`.

  Any concrete hardware interface (simulated rig, bench hardware, drone fleet, ...)
  must implement these four capabilities. The deployment manager treats adapters
  as opaque: it asks for capabilities and status, forwards actions, and can
  always demand an emergency stop.
  """

  @callback capabilities() :: map()
  @callback status() :: map()
  @callback execute_action(action :: map()) :: {:ok, map()} | {:error, term()}
  @callback emergency_stop() :: :ok
end
