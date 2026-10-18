defmodule Tiannara.ASC.ResearchPlanner do
  @moduledoc """
  Generates autonomous research roadmaps from civilizational goals.

  Fail-closed (production-readiness scan A7): no real goal-decomposition
  engine exists — the previous implementation returned the same four
  template programs with fabricated confidences (0.7/0.65/0.8/0.75) for
  any goal; the goal argument only reached string interpolation. Planning
  reports unavailability until a decomposition engine is implemented.
  """
  use GenServer

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{}, opts)

  def plan(pid, goal), do: GenServer.call(pid, {:plan, goal})

  @impl true
  def init(_), do: {:ok, %{plans: %{}}}

  @impl true
  def handle_call({:plan, _goal}, _from, state) do
    {:reply, {:error, :planner_unavailable}, state}
  end
end
