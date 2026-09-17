defmodule Tiannara.Graph.ServerPersistentTest do
  use ExUnit.Case, async: false

  alias Tiannara.Graph.{Server, Persistent, InMemory, Audit}

  @moduletag :graph_server_persistent

  test "Graph.Server serializes concurrent writes safely" do
    {:ok, pid} = Server.start_link([])

    1..50
    |> Enum.map(fn i -> Task.async(fn -> Server.add_node(pid, :"n#{i}", %{i: i}) end) end)
    |> Enum.each(&Task.await/1)

    assert length(Server.node_ids(pid)) == 50
    GenServer.stop(pid)
  end

  test "Graph.Server preserves edge metadata + audit via snapshot" do
    {:ok, pid} = Server.start_link([])
    Server.add_node(pid, :a, %{})
    Server.add_node(pid, :b, %{})
    Server.add_edge(pid, :e1, :a, :b, :rel, %{w: 1})

    assert {:ok, %{metadata: %{w: 1}}} = Server.get_edge(pid, :e1)

    g = InMemory.from_snapshot(Server.snapshot(pid))
    refute Audit.has_cycle?(g)
    GenServer.stop(pid)
  end

  test "Graph.Persistent records mutations in an append-only event log" do
    {:ok, pid} = Persistent.start_link([])
    Persistent.add_node(pid, :a, %{v: 1})
    Persistent.add_node(pid, :b, %{v: 2})
    Persistent.add_edge(pid, :e1, :a, :b, :rel, %{w: 3})

    log = Persistent.event_log(pid)
    assert length(log) == 3
    assert {:add_node, :a, %{v: 1}} in log
    GenServer.stop(pid)
  end

  test "Graph.Persistent reconstructs by replaying its log" do
    {:ok, pid} = Persistent.start_link([])
    Persistent.add_node(pid, :a, %{v: 1})
    Persistent.add_edge(pid, :e1, :a, :a, :self, %{})

    :ok = Persistent.replay(pid)
    assert {:ok, %{v: 1}} = Persistent.get_node(pid, :a)
    assert {:ok, _} = Persistent.get_edge(pid, :e1)
    GenServer.stop(pid)
  end

  test "Graph.Persistent survives restart via a file-backed log" do
    path = Path.join(System.tmp_dir!(), "graph_#{System.unique_integer([:positive])}.etf")
    on_exit(fn -> File.rm(path) end)

    {:ok, pid} = Persistent.start_link(path: path)
    Persistent.add_node(pid, :a, %{v: 7})
    Persistent.add_edge(pid, :e1, :a, :a, :loop, %{ok: true})
    GenServer.stop(pid)

    {:ok, pid2} = Persistent.start_link(path: path)
    assert {:ok, %{v: 7}} = Persistent.get_node(pid2, :a)
    assert {:ok, %{metadata: %{ok: true}}} = Persistent.get_edge(pid2, :e1)
    GenServer.stop(pid2)
  end
end