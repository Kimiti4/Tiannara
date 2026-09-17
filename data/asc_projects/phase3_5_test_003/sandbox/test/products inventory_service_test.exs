defmodule Products inventoryServiceTest do
  use ExUnit.Case
  doctest Products inventoryService

  alias Products inventoryService

  describe "products inventoryService" do
      test "add_products inventory returns not_implemented" do
    # TODO: Replace with actual test based on TestContract
    assert {:error, :not_implemented} = Products inventoryService.add_products inventory(%{})
  end

  end
end
