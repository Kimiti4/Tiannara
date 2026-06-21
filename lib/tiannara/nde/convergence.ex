defmodule Tiannara.NDE.Convergence do
  @moduledoc """
  Detects when the semantic ecosystem is converging into a monoculture.
  """
  @entropy_floor 0.45

  def evaluate(ecology) do
    entropy = Map.get(ecology, :semantic_entropy, 1.0)
    compression = Map.get(ecology, :compressed_density, 0.5)

    novelty_pressure = compression / max(entropy, 0.001)

    cond do
      entropy < @entropy_floor ->
        {:inject, novelty_pressure}

      true ->
        {:stable, novelty_pressure}
    end
  end
end
