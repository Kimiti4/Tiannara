defmodule TiannaraRuntime.Civilization.Registry.GraphRegistryTest do
  use ExUnit.Case
  @moduletag :civilization
  @moduletag :registry
  @moduletag :graph

  alias TiannaraRuntime.Civilization.Registry.CivilizationGraphRegistry

  test "add_node creates node and lookup finds it" do
    {:ok, reg} = CivilizationGraphRegistry.initialize()
    {:ok, reg} = CivilizationGraphRegistry.add_node(reg, "civ_1", :civilization)
    {:ok, node} = CivilizationGraphRegistry.lookup(reg, "civ_1")
    assert node.id == "civ_1"
    assert node.type == :civilization
    assert CivilizationGraphRegistry.add_node(reg, "civ_1", :civilization) == {:error, {:duplicate_node, "civ_1"}}
  end

  test "add_edge connects nodes" do
    {:ok, reg} = CivilizationGraphRegistry.initialize()
    {:ok, reg} = CivilizationGraphRegistry.add_node(reg, "civ_a", :civilization)
    {:ok, reg} = CivilizationGraphRegistry.add_node(reg, "inst_b", :institution)
    {:ok, reg} = CivilizationGraphRegistry.add_edge(reg, "civ_a", "inst_b", :governs)
    {:ok, counts} = CivilizationGraphRegistry.count(reg)
    assert counts.nodes == 2
    assert counts.edges == 1
    {:ok, ordered} = CivilizationGraphRegistry.traverse(reg)
    assert length(ordered) == 2
  end

  test "traverse returns topological order for DAG" do
    {:ok, reg} = CivilizationGraphRegistry.initialize()
    {:ok, reg} = CivilizationGraphRegistry.add_node(reg, "root", :civilization)
    {:ok, reg} = CivilizationGraphRegistry.add_node(reg, "mid", :institution)
    {:ok, reg} = CivilizationGraphRegistry.add_node(reg, "leaf", :knowledge)
    {:ok, reg} = CivilizationGraphRegistry.add_edge(reg, "root", "mid", :governs)
    {:ok, reg} = CivilizationGraphRegistry.add_edge(reg, "mid", "leaf", :governs)
    {:ok, ordered} = CivilizationGraphRegistry.traverse(reg)
    assert length(ordered) == 3
    node_ids = Enum.map(ordered, fn %{node: n} -> n.id end)
    assert List.last(node_ids) == "root"
  end

  test "cycle detection returns error" do
    {:ok, reg} = CivilizationGraphRegistry.initialize()
    {:ok, reg} = CivilizationGraphRegistry.add_node(reg, "a", :civilization)
    {:ok, reg} = CivilizationGraphRegistry.add_node(reg, "b", :institution)
    {:ok, reg} = CivilizationGraphRegistry.add_edge(reg, "a", "b", :governs)
    {:ok, reg} = CivilizationGraphRegistry.add_edge(reg, "b", "a", :depends_on)
    result = CivilizationGraphRegistry.traverse(reg)
    assert match?({:error, {:cycle, _}}, result)
    validate_result = CivilizationGraphRegistry.validate(reg)
    assert match?({:error, _}, validate_result)
  end
end
