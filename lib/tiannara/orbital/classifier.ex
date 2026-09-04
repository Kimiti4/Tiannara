defmodule Tiannara.Orbital.Classifier do
  @moduledoc """
  Classifies the civilizational orbit based on the Unified Reality Graph state.
  """
  
  def classify(world_state_snapshot) do
    cond do
      world_state_snapshot.collapse_probability > 0.8 -> :collapse
      world_state_snapshot.entropy > 0.9 -> :recovery
      world_state_snapshot.knowledge_capital > 100 -> :regenerative
      true -> :stable
    end
  end
end
