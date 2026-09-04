defmodule Tiannara.Sentinel.Cognition.WorldModel do
  @moduledoc "Maintains the internal model of Tiannara's state and dependencies."
  use GenServer
  alias Tiannara.Sentinel.Cognition.WorldModelData

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{}, opts)
  def get_state(pid), do: GenServer.call(pid, :get_state)

  @impl true
  def init(_) do
    {:ok, %WorldModelData{
      subsystems: [:REA, :SOPL, :Memory, :RealityGraph],
      dependencies: %{REA: [:CausalGraph, :Memory], SOPL: [:REA]},
      agents: [],
      processes: [],
      failure_probabilities: %{REA: 0.12},
      bottlenecks: [:mutation_diversity],
      last_updated: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call(:get_state, _from, state), do: {:reply, state, state}
end
