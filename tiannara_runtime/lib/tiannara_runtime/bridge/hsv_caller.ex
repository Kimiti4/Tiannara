defmodule Tiannara.Bridge.HsvCaller do
  @moduledoc """
  Wrapper that invokes the SingularityVent (HSV) when the bridge detects overload.
  Used by `Tiannara.Bridge.evaluate_stability` to trigger a collapse if needed.
  """

  use GenServer
  require Logger

  # Start as a simple GenServer (no state needed)
  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def init(state), do: {:ok, state}

  @doc """
  Check the omega/phi boundary and invoke SingularityVent if needed.
  `omega` – ontology density, `phi` – load pressure, `coord` – spatial coordinate info.
  Returns `{:safe, omega, phi}` or the collapse map from `SingularityVent`.
  """
  def evaluate_boundary(omega, phi, coord) do
    Tiannara.Bridge.SingularityVent.evaluate_boundary(omega, phi, coord)
  end
end
