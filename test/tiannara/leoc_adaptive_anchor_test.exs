defmodule Tiannara.LEOC.AdaptiveAnchorTest do
  use ExUnit.Case, async: false

  test "commits an anchor when no baseline exists" do
    ensure_started(Tiannara.LEOC.AnchorRegistry)
    tensor = Nx.broadcast(1.0, {2, 2})
    assert {:new_anchor, hash} = Tiannara.LEOC.AdaptiveAnchor.evaluate("anchor-test", tensor)
    assert is_binary(hash)
  end

  test "detects drift and replaces the current anchor" do
    ensure_started(Tiannara.LEOC.AnchorRegistry)
    base = Nx.broadcast(0.0, {2, 2})
    changed = Nx.broadcast(1.0, {2, 2})
    assert {:ok, _} = Tiannara.LEOC.AnchorRegistry.put("anchor-drift", base)
    assert {:new_anchor, new_hash, drift} =
             Tiannara.LEOC.AdaptiveAnchor.evaluate("anchor-drift", changed, threshold: 0.5)
    assert drift == 1.0
    assert is_binary(new_hash)
  end

  defp ensure_started(module) do
    case GenServer.start_link(module, [], name: module) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end
  end
end
