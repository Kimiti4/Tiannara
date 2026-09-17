defmodule TiannaraRuntime.Cognitive.Runtime.ReplayCoordinator do
  def record(mission, subsystems) do
    mission_root = :crypto.hash(:sha256, inspect(mission)) |> Base.encode16(case: :lower)
    subsystem_hashes =
      subsystems
      |> Enum.map(fn {name, mod} -> {name, :crypto.hash(:sha256, inspect(mod)) |> Base.encode16(case: :lower)} end)
      |> Map.new()
    replay = %{
      mission_root: mission_root,
      subsystem_hashes: subsystem_hashes,
      recorded_at: :erlang.unique_integer([:positive])
    }
    {:ok, replay}
  end

  def verify(replay, mission, subsystems) do
    recomputed_root = :crypto.hash(:sha256, inspect(mission)) |> Base.encode16(case: :lower)
    if recomputed_root != Map.get(replay, :mission_root) do
      {:error, {:root, :mismatch}}
    else
      stored_hashes = Map.get(replay, :subsystem_hashes, %{})
      result =
        subsystems
        |> Enum.reduce_while(nil, fn {name, mod}, _acc ->
          computed = :crypto.hash(:sha256, inspect(mod)) |> Base.encode16(case: :lower)
          stored = Map.get(stored_hashes, name)
          if computed == stored do
            {:cont, nil}
          else
            {:halt, {:error, {name, :mismatch}}}
          end
        end)
      case result do
        nil -> {:ok, :verified}
        {:error, _} = err -> err
      end
    end
  end

  def reconstruct(replay) do
    {:ok, %{replay_data: replay, note: "Reconstruction requires subsystem replay modules"}}
  end
end
