defmodule TiannaraRuntime.OCM.Consensus do
  @moduledoc """
  Phase 5F.7 — OCM Consensus Engine

  Encodes the OCM policy for merge, translate, and quarantine decisions
  based on measured semantic drift.
  """

  require Logger

  @spec reconcile(term(), term(), float()) :: {:ok, term()} | {:error, String.t()}
  def reconcile(node_a, node_b, drift) do
    cond do
      drift < 0.35 ->
        {:ok, merge(node_a, node_b)}

      drift < 0.60 ->
        {:ok, translate(node_a, node_b)}

      true ->
        {:error, quarantine(node_a, node_b)}
    end
  end

  defp merge(a, b) do
    Logger.info("[OCM] merge #{inspect(a)} ↔ #{inspect(b)}")
    %{type: :merge, nodes: [a, b], result: :aligned}
  end

  defp translate(a, b) do
    Logger.warning("[OCM] semantic translation #{inspect(a)} ↔ #{inspect(b)}")
    %{type: :translate, nodes: [a, b], result: :mapped}
  end

  defp quarantine(a, b) do
    Logger.error("[OCM] quarantine #{inspect(a)} ↔ #{inspect(b)}")
    %{type: :quarantine, nodes: [a, b], result: :isolated}
  end
end
