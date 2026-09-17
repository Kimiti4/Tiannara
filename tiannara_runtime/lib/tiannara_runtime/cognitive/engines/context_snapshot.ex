defmodule TiannaraRuntime.Cognitive.Engines.ContextSnapshot do
  @moduledoc "Phase 18.3 — Context Snapshot"

  def capture(workspace, context_state, activation_graph) do
    snapshot = %{
      workspace: workspace,
      context_state: context_state,
      activation_graph: activation_graph,
      evidence_refs: workspace.evidence_refs,
      replay_refs: workspace.replay_refs,
      captured_at: :erlang.unique_integer([:positive]),
      fingerprint: nil
    }
    fingerprint = compute_fingerprint(snapshot)
    {:ok, %{snapshot | fingerprint: fingerprint}}
  end

  def restore(snapshot) do
    {:ok, snapshot}
  end

  def verify(snapshot) do
    expected = compute_fingerprint(%{snapshot | fingerprint: nil})
    if expected == snapshot.fingerprint do
      {:ok, :verified}
    else
      {:error, :hash_mismatch}
    end
  end

  def get_fingerprint(snapshot) do
    {:ok, snapshot.fingerprint}
  end

  defp compute_fingerprint(snapshot) do
    canonical =
      snapshot
      |> Map.drop([:captured_at, :fingerprint])
      |> Enum.sort_by(fn {k, _} -> k end)
      |> Enum.map(fn {k, v} -> "#{k}:#{inspect(v)}" end)
      |> Enum.join("|")
    :crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower)
  end
end
