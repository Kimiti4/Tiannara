defmodule TiannaraRuntime.Civilization.Registry.RegistryTest do
  use ExUnit.Case
  @moduletag :civilization
  @moduletag :registry

  alias TiannaraRuntime.Civilization.Registry.CivilizationRegistry
  alias TiannaraRuntime.Civilization.Registry.InstitutionRegistry
  alias TiannaraRuntime.Civilization.Registry.CivilizationGraphRegistry

  test "initialize returns empty registry" do
    {:ok, reg} = CivilizationRegistry.initialize()
    assert reg.items == %{}
    assert reg.ordered_ids == []
    assert is_integer(reg.created_at)

    {:ok, ireg} = InstitutionRegistry.initialize()
    assert ireg.items == %{}
    assert ireg.ordered_ids == []
    assert is_integer(ireg.created_at)
  end

  test "register adds item and lookup finds it" do
    {:ok, reg} = CivilizationRegistry.initialize()
    item = %{id: "civ_1", name: "Test Civilization"}
    {:ok, reg} = CivilizationRegistry.register(reg, item)
    {:ok, found} = CivilizationRegistry.lookup(reg, "civ_1")
    assert found == item
    {:ok, count} = CivilizationRegistry.count(reg)
    assert count == 1
  end

  test "lookup missing returns error" do
    {:ok, reg} = CivilizationRegistry.initialize()
    assert CivilizationRegistry.lookup(reg, "nonexistent") == {:error, :not_found}
  end

  test "remove deletes item" do
    {:ok, reg} = CivilizationRegistry.initialize()
    item = %{id: "civ_1", name: "Test"}
    {:ok, reg} = CivilizationRegistry.register(reg, item)
    {:ok, reg} = CivilizationRegistry.remove(reg, "civ_1")
    assert CivilizationRegistry.lookup(reg, "civ_1") == {:error, :not_found}
    {:ok, count} = CivilizationRegistry.count(reg)
    assert count == 0
    assert CivilizationRegistry.remove(reg, "civ_1") == {:error, :not_found}
  end

  test "CivilizationGraphRegistry initialize and register with validate" do
    {:ok, reg} = CivilizationGraphRegistry.initialize()
    assert reg.nodes == %{}
    assert reg.edges == %{}
    assert reg.adjacency == %{}
    assert is_integer(reg.created_at)

    item = %{id: "civ_1", type: :civilization}
    {:ok, reg} = CivilizationGraphRegistry.register(reg, item)
    {:ok, found} = CivilizationGraphRegistry.lookup(reg, "civ_1")
    assert found == item
    assert CivilizationGraphRegistry.validate(reg) == :ok
  end
end
