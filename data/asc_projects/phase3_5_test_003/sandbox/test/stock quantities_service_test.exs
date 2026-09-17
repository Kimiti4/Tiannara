defmodule Stock quantitiesServiceTest do
  use ExUnit.Case
  doctest Stock quantitiesService

  alias Stock quantitiesService

  describe "stock quantitiesService" do
      test "update_stock quantities returns not_implemented" do
    # TODO: Replace with actual test based on TestContract
    assert {:error, :not_implemented} = Stock quantitiesService.update_stock quantities(%{})
  end

  end
end
