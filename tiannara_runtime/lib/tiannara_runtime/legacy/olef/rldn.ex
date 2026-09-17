defmodule Tiannara.Runtime.OLEF.RLDN do
  @moduledoc """
  Resource Load Diffusion Network (RLDN) - Diffuses load toward lower pressure targets.
  """

  def diffuse(%{source: _source, load: total_load}, targets) do
    # Filter out 0.0 or negative pressures to avoid division by zero
    valid_targets =
      targets
      |> Enum.filter(fn {_id, p} -> p > 0.0 end)

    inverse_weights =
      valid_targets
      |> Enum.map(fn {id, p} -> {id, 1.0 / p} end)

    total_inverse_weight =
      inverse_weights
      |> Enum.reduce(0.0, fn {_id, w}, acc -> acc + w end)

    routes =
      if total_inverse_weight > 0.0 do
        inverse_weights
        |> Enum.map(fn {id, w} ->
          share = w / total_inverse_weight
          %{target: id, load: total_load * share}
        end)
      else
        # Fallback: even distribution
        count = max(map_size(targets), 1)
        targets
        |> Enum.map(fn {id, _p} -> %{target: id, load: total_load / count} end)
      end

    {:ok, routes}
  end
end
