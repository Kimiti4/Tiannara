defmodule Tiannara.Omega.Application do
  @moduledoc """
  The OTP application entry point for the Ω agency. Starts the supervised
  process tree.

  Constitutional basis: Fault tolerance, "Recover gracefully", "Preserve
  previous stable states."
  """
  use Application

  @impl true
  def start(_type, _args) do
    Tiannara.Omega.Supervisor.start_link([])
  end
end