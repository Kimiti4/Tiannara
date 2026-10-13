defmodule Tiannara.World.ReplayEngineTest do
  use ExUnit.Case, async: false

  alias Tiannara.World.ReplayEngine

  setup do
    assert is_pid(Process.whereis(ReplayEngine)), "ReplayEngine must be started by the application"
    :ok
  end

  test "fails closed when no executable mutation source is available" do
    before = ReplayEngine.stats()

    assert {:error, :replay_source_unavailable} = ReplayEngine.replay(:beginning, :end)

    after_replay = ReplayEngine.stats()
    assert after_replay.replay_sessions == before.replay_sessions
  end
end