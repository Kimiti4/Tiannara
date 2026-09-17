defmodule ObservationBus.CIL.Epistemic.TrustPropagator do
  @moduledoc """
  Propagates confidence through dependency graphs.

  When a knowledge object depends on weak evidence, its confidence
  is reduced accordingly. Trust flows through the evidence graph
  from foundational observations to high-level principles.
  """
  use GenServer

  defstruct [:total_propagations, :last_propagation]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %__MODULE__{total_propagations: 0, last_propagation: nil}}
  end

  @doc """
  Compute propagated confidence for an object given its dependency chain.
  Each level of indirection applies a decay factor.
  """
  @spec propagate(float(), non_neg_integer()) :: float()
  def propagate(base_confidence, depth) do
    decay = 0.85
    base_confidence * :math.pow(decay, depth)
  end

  @doc "Compute trust score for a chain of dependencies."
  @spec chain_trust([float()]) :: float()
  def chain_trust(confidences) do
    if length(confidences) == 0, do: 0.0
    Enum.reduce(confidences, 1.0, fn c, acc -> acc * c end)
  end

  @doc "Get propagation stats."
  @spec stats() :: map()
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{total_propagations: state.total_propagations, last_propagation: state.last_propagation}, state}
  end
end
