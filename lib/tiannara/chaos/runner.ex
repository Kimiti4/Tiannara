defmodule Tiannara.Chaos.Runner do
  @moduledoc """
  Execution contract for chaos scenarios -- HARD-GATED to isolated environments.

  ISOLATION CONTRACT (Track A / P0):
    The runner MUST refuse to execute against the live 72h soak or any
    production checkpoint path. It only operates on a dedicated isolated
    instance with its own data directory.
  """

  @callback inject(fault :: Tiannara.Chaos.Fault.t(), env :: keyword()) ::
              :ok | {:error, term()}

  @callback observe(scenario_id :: term(), env :: keyword()) :: map()

  @doc """
  Raises unless the environment is explicitly isolated. This is the guard
  that keeps the chaos campaign from ever touching the running soak.
  """
  def assert_isolated!(env) do
    unless Keyword.get(env, :isolated, false) do
      raise "ChaosRunner refused: env is not marked :isolated"
    end

    if Keyword.get(env, :targets_live_soak, false) do
      raise "ChaosRunner refused: cannot target the live soak"
    end

    :ok
  end
end

defmodule Tiannara.Chaos.Runner.Mock do
  @moduledoc """
  In-memory runner used to validate the blueprint itself. Never touches a
  live system. The real actuator is wired post-soak against an isolated node.
  """
  @behaviour Tiannara.Chaos.Runner

  @impl true
  def inject(%Tiannara.Chaos.Fault{} = _fault, env) do
    Tiannara.Chaos.Runner.assert_isolated!(env)
    # Real actuation happens here against the isolated instance.
    :ok
  end

  @impl true
  def observe(scenario_id, env) do
    Tiannara.Chaos.Runner.assert_isolated!(env)
    %{scenario_id: scenario_id, phases_seen: []}
  end
end
