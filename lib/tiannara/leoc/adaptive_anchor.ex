defmodule Tiannara.LEOC.AdaptiveAnchor do
  @moduledoc """
  Drift-aware baseline anchor manager.

  Instead of assuming one immutable baseline for every epoch, this component
  measures normalized mean absolute drift and commits a new content-addressed
  anchor when the configured threshold is exceeded.
  """

  @default_threshold 0.15

  def evaluate(world_id, %Nx.Tensor{} = current_state, opts \\ []) do
    threshold = Keyword.get(opts, :threshold, @default_threshold)

    case Tiannara.LEOC.AnchorRegistry.current(world_id) do
      :error ->
        {:new_anchor, put_anchor(world_id, current_state)}

      {:ok, anchor} ->
        drift =
          current_state
          |> Nx.subtract(anchor.tensor)
          |> Nx.abs()
          |> Nx.mean()
          |> Nx.to_number()

        if drift > threshold do
          {:new_anchor, put_anchor(world_id, current_state), drift}
        else
          {:stable, anchor.hash, drift}
        end
    end
  end

  defp put_anchor(world_id, tensor) do
    {:ok, hash} = Tiannara.LEOC.AnchorRegistry.put(world_id, tensor)
    hash
  end
end
