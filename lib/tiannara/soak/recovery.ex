defmodule Tiannara.Soak.Recovery do
  @moduledoc """
  Soak resume semantics. Guarantees:

      A valid checkpoint survives abnormal termination and lets the SAME run
      resume without losing validated elapsed time or evidence. It must never
      silently reset to 0, and must never resume across run IDs.

  Decision table:
      latest valid checkpoint, same run_id  -> :resume
      latest valid checkpoint, other run_id -> :run_mismatch (do NOT resume)
      all checkpoints corrupt / none        -> :clean_start
  """

  alias Tiannara.Soak.Checkpoint

  def load(store, run_id) do
    case store.__struct__.latest_valid(store) do
      {:ok, %Checkpoint{soak_run_id: ^run_id} = cp} ->
        {:resume, cp}

      {:ok, %Checkpoint{} = cp} ->
        {:run_mismatch, cp}

      :none ->
        {:clean_start, initial_state(run_id)}
    end
  end

  defp initial_state(run_id) do
    %{
      soak_run_id: run_id,
      elapsed_seconds: 0,
      phase: :init,
      counters: %{},
      discovery_state: %{}
    }
  end
end
