defmodule Tiannara.Meta.IntegrationEvolutionPipelineTest do
  use ExUnit.Case

  alias Tiannara.Meta.Evolution.TensorEvolutionEngine

  test "full evolution pipeline executes" do
    law = %{
      id: "law_1",
      oir_ast: {:const, 42}
    }

    # TensorEvolutionEngine might already be started by the app supervisor
    case TensorEvolutionEngine.start_link([]) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    {mutated, fitness} =
      TensorEvolutionEngine.evolve(law)

    assert mutated != nil
    assert fitness != nil
  end
end
