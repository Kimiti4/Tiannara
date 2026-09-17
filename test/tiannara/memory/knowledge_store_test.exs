defmodule Tiannara.Memory.KnowledgeStoreTest do
  use ExUnit.Case, async: true

  alias Tiannara.Memory.Artifact
  alias Tiannara.Memory.KnowledgeStore

  test "open creates an isolated directory" do
    dir = Path.join(System.tmp_dir!(), "tiannara_knowledge_test_#{System.unique_integer([:positive])}")
    {:ok, store} = KnowledgeStore.open(dir)
    assert File.exists?(dir)
    File.rmdir!(dir)
  end

  test "append and retrieve an artifact" do
    dir = Path.join(System.tmp_dir!(), "tiannara_knowledge_test_#{System.unique_integer([:positive])}")
    {:ok, store} = KnowledgeStore.open(dir)

    artifact = %Artifact{
      id: "test-1",
      rung: :principle,
      content: "hello",
      lineage: []
    }

    :ok = KnowledgeStore.append(store, artifact)
    all = KnowledgeStore.all(store)
    assert length(all) == 1
    assert hd(all).id == "test-1"
    File.rm_rf!(dir)
  end

  test "append_chain stores multiple artifacts" do
    dir = Path.join(System.tmp_dir!(), "tiannara_knowledge_test_#{System.unique_integer([:positive])}")
    {:ok, store} = KnowledgeStore.open(dir)

    chain = [
      %Artifact{id: "a", rung: :principle, content: "first", lineage: []},
      %Artifact{id: "b", rung: :observation, content: "second", lineage: ["a"]},
      %Artifact{id: "c", rung: :experiment, content: "third", lineage: ["a", "b"]}
    ]

    :ok = KnowledgeStore.append_chain(store, chain)
    all = KnowledgeStore.all(store)
    assert length(all) == 3
    File.rm_rf!(dir)
  end

  test "refuses production memory path" do
    assert {:error, :production_memory_forbidden} = KnowledgeStore.open("memory/production")
    assert {:error, :production_memory_forbidden} = KnowledgeStore.open("memory/production/sub")
  end
end
