defmodule Tiannara.EPC.StateTensor do
  @moduledoc """
  Evolution Pressure Control: State Tensor.
  Normalized [0, 1] state representation aligned with MSCL.
  """

  def snapshot do
    mscl = query_mscl()
    grcc = query_grcc()
    olef = query_olef()

    %{
      h: grcc.entropy,
      d: grcc.dominance,
      c: grcc.coherence,
      n: grcc.novelty,
      o: olef.pressure,
      l: mscl.load,
      phi: mscl.divergence
    }
    |> normalize()
  end

  defp query_mscl do
    case try_get_state(Tiannara.MSCL.Supervisor) do
      %{global_pressure: gp, max_global_pressure: mgp, collapse_risk: cr} ->
        %{load: min(1.0, gp / max(mgp, 1.0)), divergence: cr}
      _ ->
        %{load: 0.2, divergence: 0.1}
    end
  end

  defp query_grcc do
    entropy = case try_get_state(Tiannara.GRCC.EntropyController) do
      %{entropy: e} -> min(1.0, abs(e))
      _ -> 0.5
    end
    identities = case try_get_state(Tiannara.GRCC.IdentityField) do
      %{identities: ids} -> ids
      _ -> %{}
    end
    lineage_map = case try_get_state(Tiannara.GRCC.LineageManager) do
      %{lineages: ls} -> ls
      _ -> %{}
    end

    identity_count = max(1, map_size(identities))
    dominance = abs(length(Map.values(lineage_map)) - length(Map.keys(lineage_map))) / max(length(Map.keys(lineage_map)), 1)
    coherence_sum = identities |> Map.values() |> Enum.reduce(0.0, fn v, acc -> acc + Map.get(v, :coherence, 0.5) end)
    coherence = coherence_sum / identity_count
    novelty = max(0.0, min(1.0, entropy * (1.0 - dominance)))

    %{entropy: entropy, dominance: min(1.0, dominance), coherence: coherence, novelty: novelty}
  end

  defp query_olef do
    case try_get_state(Tiannara.OLEF.NodeRegistry) do
      %{nodes: nodes} when map_size(nodes) > 0 ->
        active = Enum.count(nodes, fn {_, info} -> info.status == :active end)
        %{pressure: min(1.0, active / max(map_size(nodes), 1))}
      _ ->
        %{pressure: 0.5}
    end
  end

  defp try_get_state(module) do
    :sys.get_state(module)
  rescue
    _ -> nil
  end

  defp normalize(s) do
    Map.new(s, fn {k, v} ->
      {k, clamp01(v)}
    end)
  end

  defp clamp01(x), do: max(0.0, min(1.0, x))
end
