defmodule Tiannara.CEL.Kernel.RuntimeStates do
  @type state ::
          :booting
          | :initializing
          | :verifying
          | :learning
          | :operational
          | :adaptive
          | :recovery
          | :emergency
          | :maintenance
          | :shutdown

  @valid_transitions %{
    booting: [:initializing, :emergency, :shutdown],
    initializing: [:verifying, :recovery, :emergency, :shutdown],
    verifying: [:learning, :operational, :recovery, :emergency, :shutdown],
    learning: [:operational, :recovery, :emergency, :shutdown],
    operational: [:adaptive, :recovery, :maintenance, :emergency, :shutdown],
    adaptive: [:operational, :recovery, :maintenance, :emergency, :shutdown],
    recovery: [:verifying, :operational, :emergency, :shutdown],
    emergency: [:recovery, :shutdown],
    maintenance: [:verifying, :operational, :emergency, :shutdown],
    shutdown: []
  }

  @spec valid_transition?(state(), state()) :: boolean()
  def valid_transition?(from, to) do
    to in Map.get(@valid_transitions, from, [])
  end

  @spec next_states(state()) :: [state()]
  def next_states(state), do: Map.get(@valid_transitions, state, [])

  @spec operational?(state()) :: boolean()
  def operational?(s), do: s in [:operational, :adaptive]
end
